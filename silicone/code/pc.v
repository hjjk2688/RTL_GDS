// mode=1, program counter + rom
// 프로그램 카운터 + 롬 ( CPU 모드 1 인 경우 )

`define default_netname none

(* keep_hierarchy *)
module PC (
    input wire clock,
    input wire reset,
    input wire ena,

    // 디버그 포트 - JSilicon.v (TOP)에서 사용하지 않도록 설정하여 제거
    // output wire [3:0] pc_out,
    output wire [7:0] instr_out

    );

    reg [7:0] instr_out_reg;
    reg [3:0] pc;
    // 내장 롬 명령어 지시 (프로그램)
    // 명령구조 : [7:5] = opcode, [4:0]=operand
    // ex, ADD 3  = [000](opcode) + [00011](operand)
    // todo - FSM 명령어 추가하기 (25.10.06)

    always @(*) begin
        case (pc)
            //4'd0: instr_out_reg = 8'b00000011; // ADD 3
            //4'd1: instr_out_reg = 8'b00100010; // SUB 2
            //4'd2: instr_out_reg = 8'b01000101; // MUL 5
            //4'd3: instr_out_reg = 8'b00000000; // NOP
            
            // =================================================================================
            // [수정 사항 1] CPU가 처음 시작할 때 R0, R1이 모두 0이라 연산이 불가능한 문제를 해결하기 위해,
            // 프로그램의 첫 명령어를 "R0 레지스터에 상수 5를 로드하라"는 LDI 명령어로 변경.
            // 이 명령어를 통해 R0가 초기값을 갖게 되어, 이후의 연산들이 정상적으로 수행될 수 있음.
            // =================================================================================
            // Opcode: 110 (LDI), RegSel: 0 (R0), Operand: 0101 (5)
//            4'd0: instr_out_reg = 8'b11000101; // "LDI R0, 5"
//            4'd1: instr_out_reg = 8'b00100010; //  - 2
//            4'd2: instr_out_reg = 8'b00100100; //  - 4
//            4'd3: instr_out_reg = 8'b00101000; //  - 8
//            default: instr_out_reg = 8'b00000000; // Default to NOP
            
            4'd0: instr_out_reg = 8'b11000101; // "LDI R0, 5"
            4'd1: instr_out_reg = 8'b00000001; //  +1 110
            4'd2: instr_out_reg = 8'b00000001; //  +1  111
            4'd3: instr_out_reg = 8'b00000001; //  +1 1000
            default: instr_out_reg = 8'b00000000; // Default to NOP
        endcase
    end
 
    always @(posedge clock or posedge reset) begin
        // 명시적 비트폭(합성 경고 해결)로 지정
        if (reset) pc <= 4'd0;
        else if (ena) begin
            // 롬 명령어 끝까지 도달하면 0으로 로드
            if (pc == 4'd3)
                pc <= 4'd0;
            else
                pc <= pc + 1;
        end
    end

    // 포트명 오류 수정
    assign instr_out = instr_out_reg;

    // 디버그 포트 - 합성 과정에서 pc_out 포트 제거로 인한 제거
    // assign pc_out = pc;

endmodule
