// 내부 레지스터 파일
// 구조 :2 PC + ROM > Decoder > REG > ALU > FSM + UART

`define default_netname none

(* keep_hierarchy *)
module REG (
    input wire clock,
    input wire reset,
    input wire ena,

    // 데이터 입출력
    input wire [2:0] opcode,
    // 명령어 저장
    input wire [7:0] data_in, 
    // FSM, ALU 데이터 저장
    // output reg [7:0] data_out,

    // 디버그 포트
    output wire [7:0] R0_out,
    output wire [7:0] R1_out
    );

    // =================================================================================
    // [수정 사항] REG (Register File) 모듈
    //
    // 기능: 8비트 범용 레지스터 R0, R1을 포함하며, 명령어에 따라 데이터를 저장하거나
    //       레지스터 간의 데이터 이동을 처리합니다.
    //
    // 변경 사항:
    // - 기능적인 변경은 없으며, 코드 가독성을 높이기 위한 주석이 추가되었습니다.
    // - 'ena' 신호는 FSM의 'instruction_finished' 신호에 연결되어,
    //   FSM의 허락 하에만 레지스터 쓰기가 이루어지도록 동기화됩니다.
    // =================================================================================


    reg [7:0] R0, R1;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            // 기본값 초기화
            R0 <= 0; R1 <= 0;
            // data_out <= 8'b0;
        end else if (ena) begin
            case (opcode)
                // opcode 별 분리
                // LOAD R0, R1 (데이터 저장)
                3'b000: R0 <= data_in;
                3'b001: R1 <= data_in;

                // MOV (덮어쓰기)
                3'b010: R1 <= R0;
                3'b011: R0 <= R1;

                // OUT (출력) <- assign으로 직접 가져다 씀
                // 3'b100: data_out <= R0;
                // 3'b101: data_out <= R1;

                // NOP (기본값)
                default: begin
                    // 다른 opcode 에서는 명령 실행 안함
                end
            endcase
        end
    end

    assign R0_out = R0;
    assign R1_out = R1;
    
endmodule
