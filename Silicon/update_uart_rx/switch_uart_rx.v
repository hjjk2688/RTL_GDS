// CPU 모드 제어 모듈
// mode: 00(Manual), 01(CPU), 10(UART_RX)

`define default_netname none

module SWITCH_uart_rx (
    // [수정] 모드 입력을 2비트로 확장
    input wire [1:0] mode,

    // Manual 모드 입력
    input wire [7:0] manual_a, manual_b,
    input wire [2:0] manual_opcode,

    // CPU 모드 입력
    input wire [7:0] cpu_a, cpu_b,
    input wire [2:0] cpu_opcode,

    // [추가] UART RX 모드 입력
    input wire [7:0] uart_a, uart_b,
    input wire [2:0] uart_opcode,

    output reg [7:0] select_a, select_b,
    output reg [2:0] select_opcode
    );

    // 'mode' 신호에 따라 ALU로 전달될 입력을 선택
    always @(*) begin
        case (mode)
            // Manual 모드
            2'b00: begin
                select_a = manual_a;
                select_b = manual_b;
                select_opcode = manual_opcode;
            end
            // CPU 모드
            2'b01: begin
                select_a = cpu_a;
                select_b = cpu_b;
                select_opcode = cpu_opcode;
            end
            // UART RX 모드
            2'b10: begin
                select_a = uart_a;
                select_b = uart_b;
                select_opcode = uart_opcode;
            end
            // 기본값 (CPU 모드)
            default: begin
                select_a = cpu_a;
                select_b = cpu_b;
                select_opcode = cpu_opcode;
            end
        endcase
    end
    
endmodule
