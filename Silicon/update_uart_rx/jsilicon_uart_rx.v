// UART RX 기능이 추가된 top 모듈
`define default_netname none

// [수정] 모듈 이름 변경
module tt_um_Jsilicon_uart_rx(
    input wire clk_in1,
    input wire rst_n,

    // [추가] UART 수신을 위한 핀
    input wire uart_rx_pin,

    input wire [7:0] ui_in,
    input wire [7:0] uio_in,
    input wire ena,
    
    output wire [7:0] uo_out,
    output wire [7:0] uio_out
    );

    // --- 클럭 및 리셋 ---
    wire clk_out1;
    wire locked;
    wire async_reset = rst_n;
    wire sync_reset;

    clk_wiz_0 clock_wizard_inst (
        .clk_out1(clk_out1),
        .reset(async_reset),
        .locked(locked),
        .clk_in1(clk_in1)
    );

    reg rst_sync1, rst_sync2;
    always @(posedge clk_out1) begin
        rst_sync1 <= async_reset;
        rst_sync2 <= rst_sync1;
    end
    assign sync_reset = rst_sync2;

    // --- 모드 선택 로직 수정 ---
    // [수정] mode를 2비트로 확장: 00(Manual), 01(CPU), 10(UART)
    wire [1:0] mode = uio_in[4:3]; 

    // --- UART RX 및 명령어 파서 ---
    wire [7:0] uart_rx_data;
    wire uart_rx_data_ready;
    UART_RX uart_rx_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .rx(uart_rx_pin),
        .data_out(uart_rx_data),
        .data_ready(uart_rx_data_ready)
    );

    wire [7:0] uart_a, uart_b;
    wire [2:0] uart_opcode;
    wire uart_cmd_ready;
    CMD_PARSER cmd_parser_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .uart_data_in(uart_rx_data),
        .uart_data_ready(uart_rx_data_ready),
        .uart_a(uart_a),
        .uart_b(uart_b),
        .uart_opcode(uart_opcode),
        .cmd_ready(uart_cmd_ready)
    );

    // --- CPU 코어 (PC, DECODER, REG) ---
    wire [7:0] instr;
    wire instruction_finished;

    PC pc_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(instruction_finished),
        .instr_out(instr)
    );

    wire [2:0] decoder_alu_opcode;
    wire [3:0] decoder_operand;
    wire decoder_reg_sel;
    wire decoder_alu_enable;
    wire decoder_write_enable;

    DECODER dec_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(ena),
        .instr_in(instr),
        .alu_opcode(decoder_alu_opcode),
        .operand(decoder_operand),
        .reg_sel(decoder_reg_sel),
        .alu_enable(decoder_alu_enable),
        .write_enable(decoder_write_enable)
    );

    wire [7:0] wb_data = decoder_alu_enable ? alu_result[7:0] : {4'b0000, decoder_operand};
    wire [2:0] regfile_opcode = decoder_write_enable ? (decoder_reg_sel ? 3'b001 : 3'b000) : 3'b111;
    wire [7:0] R0, R1;

    REG reg_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(instruction_finished),
        .opcode(regfile_opcode),
        .data_in(wb_data),
        .R0_out(R0),
        .R1_out(R1)
    );

    // --- 입력 소스 선택 (SWITCH) ---
    wire [7:0] cpu_a = R0;
    wire [7:0] cpu_b = {4'b0000, decoder_operand};
    wire [2:0] cpu_opcode = decoder_alu_opcode;

    wire [3:0] manual_a = ui_in[7:4];
    wire [3:0] manual_b = ui_in[3:0];
    wire [2:0] manual_opcode = uio_in[7:5];

    wire [7:0] select_a, select_b;
    wire [2:0] select_opcode;
    // [수정] 확장된 SWITCH_uart_rx 모듈 인스턴스화
    SWITCH_uart_rx switch_inst (
        .mode(mode),
        .manual_a({4'b0000, manual_a}),
        .manual_b({4'b0000, manual_b}),
        .manual_opcode(manual_opcode),
        .cpu_a(cpu_a),
        .cpu_b(cpu_b),
        .cpu_opcode(cpu_opcode),
        .uart_a(uart_a),
        .uart_b(uart_b),
        .uart_opcode(uart_opcode),
        .select_a(select_a),
        .select_b(select_b),
        .select_opcode(select_opcode)
    );

    // --- ALU 및 FSM 실행 로직 ---
    wire [15:0] alu_result;
    wire fsm_trigger;
    wire alu_ena;

    // [수정] FSM과 ALU를 활성화시키는 로직
    // CPU 모드일 때는 기존 ena 신호를, UART 모드일 때는 cmd_ready 신호를 사용
    assign fsm_trigger = (mode == 2'b01) ? ena : uart_cmd_ready;
    assign alu_ena = (mode == 2'b00) ? ena : 
                     (mode == 2'b01) ? (ena & decoder_alu_enable) :
                     (mode == 2'b10) ? uart_cmd_ready : 1'b0;

    ALU alu_inst (
        .a(select_a),
        .b(select_b),
        .opcode(select_opcode),
        .ena(alu_ena),
        .result(alu_result)
    );

    wire uart_tx;
    wire uart_busy;
    // [수정] FSM의 ena 입력을 fsm_trigger로 연결
    // [수정] FSM으로 보낼 데이터를 모드에 따라 선택하는 로직 추가
    wire [7:0] data_for_fsm;
    assign data_for_fsm = (mode == 2'b01) ? wb_data : alu_result[7:0];

    // [수정] FSM의 ena 입력을 fsm_trigger로, 데이터 입력을 data_for_fsm으로 연결
    FSM core_init (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(fsm_trigger),
        .wb_data_in(data_for_fsm),
        .uart_tx(uart_tx),
        .uart_busy(uart_busy),
        .instruction_finished(instruction_finished)
    );

    // --- 최종 출력 ---
    assign uo_out = {uart_busy, alu_result[6:0]};
    assign uio_out = {alu_result[15:9], uart_tx};
    
endmodule
