// top 모듈
// FSM 커버
// 동작 구조 - Manual : USER INPUT > Jsilicon.v > FSM.v (Internal ALU, UART)
// 동작 구조 - CPU(AUTO)
// Foward : PC > DECODER > REG > SWITCH > FSM (Internal ALU, UART)
// Write-Back : ALU Result (FSM output) > REG

`define default_netname none

module tt_um_Jsilicon(
    // Tinytapeout 요구 변수명으로 수정 
    input wire clk_in1, // 포트 이름 변경 (XDC 파일 기준)
    input wire rst_n,

    // 사용자 입력 기능 추가
    input wire [7:0] ui_in,
    input wire [7:0] uio_in,

    // Enable Input 추가
    input wire ena,
    
    // 출력핀 재지정
    //output wire [7:0] uio_oe,
    
    // 사용자 출력 추가
    output wire [7:0] uo_out,
    output wire [7:0] uio_out
    
     //output reg [7:0] uo_out,
     //output reg [7:0] uio_out
    
    );

    // 클럭 위자드 및 리셋 신호
    wire clk_out1;
    wire locked;
    wire async_reset = rst_n; // 클럭 위자드용 비동기 리셋
    wire sync_reset;          // 시스템용 동기 리셋

    // 클럭 위자드 인스턴스
    clk_wiz_0 clock_wizard_inst (
        .clk_out1(clk_out1),
        .reset(async_reset), // 클럭 위자드는 비동기 리셋 사용
        .locked(locked),
        .clk_in1(clk_in1)
    );

    // 리셋 버튼 바운스 방지를 위한 2-FF 동기화
    reg rst_sync1, rst_sync2;
    always @(posedge clk_out1) begin
        rst_sync1 <= async_reset;
        rst_sync2 <= rst_sync1;
    end
    assign sync_reset = rst_sync2;

    // Manual 제어 할당
    // 내부 wire 지정
    wire [3:0] manual_a = ui_in[7:4];
    wire [3:0] manual_b = ui_in[3:0];
    // Opcode 지정
    // 연결 추가 - Opcode 
    wire [2:0] manual_opcode = uio_in[7:5];
    // Mode 핀 추가
    // 0 : Manual, 1 = CPU 
    wire mode = uio_in[4]; 
    
    
    
    // =================================================================================
    // [수정 사항 4] CPU 동기화 로직
    // ---------------------------------------------------------------------------------
    // CPU의 각 파트(PC, REG, FSM)가 서로를 기다리지 않고 폭주하는 현상을 막기 위해
    // FSM이 생성하는 'instruction_finished' 신호를 이용해 PC와 REG의 동작을 제어.
    // 이제 PC와 REG는 FSM이 "하나의 명령어 사이클이 끝났다"고 알려줄 때만 동작함.
    // =================================================================================
    wire [7:0] instr;
    wire instruction_finished; // FSM의 '명령어 처리 완료' 신호를 받을 와이어

    PC pc_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(instruction_finished), // FSM이 허락할 때만 PC가 다음 명령어로 이동하도록 변경
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
        .ena(ena), // 디코더는 항상 현재 명령어를 해독해야 하므로 최상위 ena 유지
        .instr_in(instr),
        .alu_opcode(decoder_alu_opcode),
        .operand(decoder_operand),
        .reg_sel(decoder_reg_sel),
        .alu_enable(decoder_alu_enable),
        .write_enable(decoder_write_enable)
    );

    wire [15:0] alu_result;
    // [수정 사항 5] 명령어 종류에 따른 Write-Back 데이터 선택 로직
    // LDI 같은 명령어(alu_enable=0)는 연산 결과가 아닌 명령어의 상수(operand)를 레지스터에 써야 함.
    // 일반 연산(alu_enable=1)은 ALU의 연산 결과를 레지스터에 씀.
    wire [7:0] wb_data = decoder_alu_enable ? alu_result[7:0] : {4'b0000, decoder_operand};
    wire [2:0] regfile_opcode = decoder_write_enable ? (decoder_reg_sel ? 3'b001 : 3'b000) : 3'b111;
    wire [7:0] R0, R1;

    REG reg_inst (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(instruction_finished), // FSM이 허락할 때만 레지스터에 값이 쓰여지도록 변경
        .opcode(regfile_opcode),
        .data_in(wb_data),
        .R0_out(R0),
        .R1_out(R1)
    );

    // [수정 사항 6] ALU 입력 소스 정의
    // cpu_a는 R0 레지스터 값을, cpu_b는 명령어에 포함된 상수(operand) 값을 사용.
    // 이를 통해 "레지스터-상수" 연산 구조를 명확히 함.
    wire [7:0] cpu_a = R0;
    wire [7:0] cpu_b = {4'b0000, decoder_operand};
    wire [2:0] cpu_opcode = decoder_alu_opcode;

    // SWITCH 제어
    wire [7:0] select_a;
    wire [7:0] select_b;
    wire [2:0] select_opcode;
    SWITCH switch_inst (
        .mode(mode),
        .manual_a({4'b0000, manual_a}),
        .manual_b({4'b0000, manual_b}),
        .manual_opcode(manual_opcode),
        .cpu_a(cpu_a),
        .cpu_b(cpu_b),
        .cpu_opcode(cpu_opcode),
        .select_a(select_a),
        .select_b(select_b),
        .select_opcode(select_opcode)
    );

    wire uart_tx;
    wire uart_busy;
    wire alu_ena = mode ? (ena & decoder_alu_enable) : ena;

    // =================================================================================
    // [수정 사항 7] ALU 모듈을 FSM 외부로 분리
    // "Multiple Driver" 에러를 해결하고, 제어 유닛(FSM)과 연산 유닛(ALU)의 역할을
    // 명확히 분리하기 위해 ALU를 최상위 모듈에 직접 인스턴스화.
    // =================================================================================
    ALU alu_inst (
        .a(select_a),
        .b(select_b),
        .opcode(select_opcode),
        .ena(alu_ena),
        .result(alu_result)
    );

    // [수정 사항 8] FSM 포트 연결 수정
    // FSM 내부에서 ALU와 관련된 로직이 모두 제거되었으므로, 불필요한 포트 연결을 삭제.
    // 이제 FSM은 ALU의 결과값만 입력받아 UART로 보내주는 역할만 함.
    FSM core_init (
        .clock(clk_out1),
        .reset(sync_reset),
        .ena(ena),
		//.wb_data_in(wb_data), // [수정] FSM으로 실제 Write-Back될 데이터를 전달
        .wb_data_in(wb_data), // [수정] FSM으로 실제 Write-Back될 데이터를 전달
        .uart_tx(uart_tx),
        .uart_busy(uart_busy),
        .instruction_finished(instruction_finished)
    );

    // 출력 핀 설정
    //assign uio_oe = 8'b00000001;

    // 출력 지정
//    assign uo_out = mode ? 8'b11111111 : { uart_busy, alu_result[6:0] };
//    assign uio_out = mode ? 8'b11111111: { alu_result[15:9], uart_tx };
    assign uo_out =  { uart_busy, alu_result[6:0] };
    assign uio_out = { alu_result[15:9], uart_tx };
   
//    always @(*) begin
//    // mode가 0일 때 (Manual 모드)
//        if (mode == 1'b0) begin
//            uo_out = { uart_busy, alu_result[6:0] };
//            uio_out = { alu_result[15:9], uart_tx };
    
//        end
//    // mode가 1일 때 (CPU 모드)
//        else begin
//            uo_out = 1; // 예: CPU 모드에서는 R0 값을 출력
//            //uio_out = 0; // 예: CPU 모드에서는 R1 값을 출력
//            //uio_out = 1;
//        end
//    end
endmodule

