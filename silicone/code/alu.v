// 계산기

`define default_netname none

(* keep_hierarchy *)
module ALU(
    // 입력 정의(ALU)
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [2:0] opcode,
    input wire ena,

    output reg [15:0] result
    );

    // =================================================================================
    // [수정 사항] ALU (Arithmetic Logic Unit) 모듈
    //
    // 기능: 8비트 두 입력(a, b)에 대해 다양한 산술 및 논리 연산을 수행합니다.
    //       opcode에 따라 덧셈, 뺄셈, 곱셈, 나눗셈, 나머지, 비교 연산 등을 지원합니다.
    //
    // 변경 사항:
    // - 기능적인 변경은 없으며, 코드 가독성을 높이기 위한 주석이 추가되었습니다.
    // =================================================================================


    // opcode
    // 000 - (+)
    // 001 - (-)
    // 010 - (*)
    // 011 - (/)
    // 100 - (%)
    // 101 - IF(==)
    // 110 - (>)
    // 111 - (<)

    // 곱셈과 0 나눔 벡터
    wire [15:0] multiply_temp = a * b;
    wire div_by_zero = (b == 8'h00);

    always @(*) begin
        // 기본값 세팅
        result = 16'b0000;
        if (ena) begin
            case (opcode)
                // 데이터 업데이트 // 8진수 > 16 진수 변경
                3'b000: result = {{8{1'b0}}, a + b};
                3'b001: result = {{8{1'b0}}, a - b};
                3'b010: result = multiply_temp; 
                3'b011: result = div_by_zero ? 16'b0000 : {{8{1'b0}}, a / b};
                3'b100: result = div_by_zero ? 16'b0000 : {{8{1'b0}}, a % b}; 
                3'b101: result = (a == b) ? 16'h0001 : 16'h0000;
                3'b110: result = (a > b) ? 16'h0001 : 16'h0000;
                3'b111: result = (a < b) ? 16'h0001 : 16'h0000;
                // 비정의 코드 반환
                default: result = 16'h0000;
            endcase
        end
    end
endmodule
