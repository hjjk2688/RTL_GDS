// =================================================================================
// [수정 사항 3] FSM (Finite State Machine) - CPU의 모든 동작을 지휘하는 지휘자
//
// 1. 역할 변경: 단순 UART 전송 제어 -> CPU 전체 동작 동기화
//    - ALU를 FSM 외부로 분리하여, FSM은 순수 '제어 유닛'의 역할만 수행합니다.
//    - PC, 레지스터 쓰기, UART 전송 시작 시점을 모두 관장합니다.
//
// 2. 'instruction_finished' 신호 추가:
//    - 한 명령어의 실행~결과 전송까지의 과정이 끝났음을 알리는 핵심 제어 신호입니다.
//    - 이 신호가 1이 될 때만 PC가 다음 명령어로 넘어가고, 레지스터에 새로운 값이 쓰여집니다.
//    - 이를 통해 CPU의 무한 폭주(UART 데이터 드롭 현상)를 막고, 명령어 단위로 순차적인 실행을 보장합니다.
//
// 3. 상태(State) 재구성:
//    - EXECUTE 상태를 추가하여 '명령어 실행 및 완료 신호 생성' 역할을 명확히 분리했습니다.
// =================================================================================

`define default_netname none

(* keep_hierarchy *)
module FSM (
    input wire clock,
    input wire reset,
    input wire ena,                  // 최상위 모듈에서 들어오는 실행 신호
	//input wire [15:0] alu_result	// 원래 이렇게 받음
    input wire [7:0] wb_data_in,      // [수정] 레지스터에 실제 쓰여질 값을 입력으로 받음
    output wire uart_tx,
    output wire uart_busy,
    output reg instruction_finished // PC와 레지스터에게 "동작하라"고 알려주는 제어 신호
    );

    // FSM 상태 재정의: IDLE(대기), EXECUTE(실행), SEND(전송), WAIT(전송대기)
    localparam IDLE   = 2'd0;
    localparam EXECUTE = 2'd1;
    localparam SEND   = 2'd2;
    localparam WAIT   = 2'd3;

    reg [1:0] state;
    reg start_uart;
	//reg [15:0] result_reg; // UART로 보낼 ALU 결과값을 안전하게 저장할 레지스터
    reg [7:0] result_reg; // [수정] UART로 보낼 데이터는 이제 8비트이므로 레지스터 크기 변경

    // UART 모듈 연결.
    UART_TX uart_connect(
        .clock(clock),
        .reset(reset),
        .start(start_uart),
		//.data_in(result_reg), // [수정] 8비트 레지스터를 직접 연결
        .data_in(result_reg), // [수정] 8비트 레지스터를 직접 연결
        .tx(uart_tx),
        .busy(uart_busy)
    );

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            start_uart <= 1'b0;
            instruction_finished <= 1'b0;
            //result_reg <= 16'b0; 
			result_reg <= 8'b0; // [수정] 8비트로 리셋
			
        end else begin
            // 기본적으로 모든 제어 신호는 매 클럭 시작 시 비활성화
            start_uart <= 1'b0;
            instruction_finished <= 1'b0;

            case (state)
                IDLE: begin
                    // 최상위 ena 신호가 들어오면 EXECUTE 상태로 진입
                    if (ena) begin
                        state <= EXECUTE;
                    end
                end

                EXECUTE: begin
                    // "명령어 실행 및 완료" 상태 (단 한 클럭만 유지됨)
                    //result_reg <= alu_result;       // 1. ALU 결과값을 안전하게 복사(UART 전송용)
					result_reg <= wb_data_in;       // 1. [수정] ALU 결과 대신 실제 Write-Back될 데이터를 복사
                    start_uart <= 1'b1;             // 2. UART 전송 시작 신호 생성
                    instruction_finished <= 1'b1;   // 3. PC와 레지스터에게 "다음!" 신호 전송
                    state <= SEND;                  // 4. 다음 상태(UART 전송 시작 대기)로 전환
                end

                SEND: begin
                    // UART가 데이터를 보내기 시작해서 busy 신호가 켜지면 WAIT 상태로 진입하여 대기
                    if (uart_busy) begin
                        state <= WAIT;
                    end
                end

                WAIT: begin
                    // UART 전송이 모두 끝나 busy 신호가 꺼지면 다시 IDLE 상태로 복귀
                    if (!uart_busy) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
