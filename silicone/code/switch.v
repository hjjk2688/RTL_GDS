// CPU 모드 제어 모듈
// 0 : 외부 제어(Manual) 1 : 내장 ROM 명령 실행

`define default_netname none

module SWITCH (
    // 스위치 포트
    input wire mode,

    // 다중 mode 선택자로 조정
    input wire [7:0] manual_a, manual_b,
    input wire [2:0] manual_opcode,

    input wire [7:0] cpu_a, cpu_b,
    input wire [2:0] cpu_opcode,

    output wire [7:0] select_a, select_b,
    output wire [2:0] select_opcode
    );

    // =================================================================================
    // [수정 사항] SWITCH 모듈
    //
    // 기능: 'mode' 신호에 따라 CPU 모드(자동)와 매뉴얼 모드(수동) 중 하나의 입력 소스를 선택합니다.
    //       CPU 모드에서는 PC, DECODER, REG에서 오는 값을 사용하고,
    //       매뉴얼 모드에서는 외부 UI 입력(ui_in, uio_in)에서 오는 값을 사용합니다.
    //
    // 변경 사항:
    // - 기능적인 변경은 없으며, 코드 가독성을 높이기 위한 주석이 추가되었습니다.
    // =================================================================================


    // SWITCH
    assign select_a = mode ? cpu_a : manual_a;
    assign select_b = mode ? cpu_b : manual_b;
    assign select_opcode = mode ? cpu_opcode : manual_opcode; 
endmodule
