// UART Command Parser (with Start Byte)
`define default_netname none

module CMD_PARSER (
    input wire clock,
    input wire reset,

    input wire [7:0] uart_data_in,
    input wire uart_data_ready,

    output reg [7:0] uart_a,
    output reg [7:0] uart_b,
    output reg [2:0] uart_opcode,
    output reg cmd_ready
);

    // [추가] 명령어 시작을 알리는 특별한 바이트
    localparam START_BYTE = 8'hFE;

    reg [2:0] state; // [수정] 상태 개수가 늘어나 3비트로 확장
    
    // [수정] IDLE: 시작 바이트 대기, WAIT_A: a값 대기
    localparam IDLE = 3'd0;
    localparam WAIT_A = 3'd1;
    localparam WAIT_B = 3'd2;
    localparam WAIT_OPCODE = 3'd3;
    localparam EXECUTE = 3'd4;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cmd_ready <= 1'b0;
            uart_a <= 0;
            uart_b <= 0;
            uart_opcode <= 0;
        end else begin
            cmd_ready <= 1'b0;

            case (state)
                // IDLE: START_BYTE(0xFE)를 기다림. 다른 모든 바이트는 무시.
                IDLE: begin
                    if (uart_data_ready && uart_data_in == START_BYTE) begin
                        state <= WAIT_A;
                    end
                end
                // WAIT_A: a 값을 기다림
                WAIT_A: begin
                    if (uart_data_ready) begin
                        uart_a <= uart_data_in;
                        state <= WAIT_B;
                    end
                end
                // WAIT_B: b 값을 기다림
                WAIT_B: begin
                    if (uart_data_ready) begin
                        uart_b <= uart_data_in;
                        state <= WAIT_OPCODE;
                    end
                end
                // WAIT_OPCODE: opcode 값을 기다림
                WAIT_OPCODE: begin
                    if (uart_data_ready) begin
                        uart_opcode <= uart_data_in[2:0];
                        state <= EXECUTE;
                    end
                end
                // EXECUTE: 명령어 실행 신호를 보내고 다시 IDLE로 복귀
                EXECUTE: begin
                    cmd_ready <= 1'b1;
                    state <= IDLE;
                end
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
