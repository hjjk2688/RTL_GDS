// UART 외부 수신 모듈
`define default_netname none

module UART_RX(
    input wire clock,
    input wire reset,
    input wire rx, // 직렬 데이터 입력

    output reg [7:0] data_out, // 수신된 8비트 데이터
    output reg data_ready      // 데이터 수신 완료 신호
);

    // CLOCK_DIV = Fclk / Baurate
    // 12,000,000 / 9600
    parameter CLOCK_DIV = 1250; // 시스템 클럭 9600bps 지정

    reg [15:0] clock_count;
    reg [3:0] bit_idx;
    reg [2:0] state;
    reg [7:0] data_reg;

    localparam IDLE = 3'd0;
    localparam START = 3'd1;
    localparam DATA = 3'd2;
    localparam STOP = 3'd3;
    localparam CLEANUP = 3'd4;

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            clock_count <= 0;
            bit_idx <= 0;
            data_ready <= 1'b0;
            data_out <= 8'h00;
        end else begin
            // data_ready 신호는 한 클럭 동안만 유지
            if (data_ready) begin
                data_ready <= 1'b0;
            end

            case (state)
                // IDLE: Start Bit (High -> Low)를 기다림
                IDLE: begin
                    if (!rx) begin
                        state <= START;
                        clock_count <= 0;
                    end
                end

                // START: Start Bit의 중간 지점까지 대기
                START: begin
                    if (clock_count == (CLOCK_DIV / 2)) begin
                        // Start Bit가 여전히 Low인지 다시 확인 (노이즈 필터링)
                        if (!rx) begin
                            state <= DATA;
                            clock_count <= 0;
                            bit_idx <= 0;
                        end else begin
                            state <= IDLE; // 노이즈였으면 IDLE로 복귀
                        end
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                // DATA: 8개의 데이터 비트를 순서대로 샘플링
                DATA: begin
                    if (clock_count == CLOCK_DIV - 1) begin
                        clock_count <= 0;
                        data_reg[bit_idx] <= rx;
                        if (bit_idx == 7) begin
                            state <= STOP;
                        end else begin
                            bit_idx <= bit_idx + 1;
                        end
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                // STOP: Stop Bit를 기다림
                STOP: begin
                    if (clock_count == CLOCK_DIV - 1) begin
                        state <= CLEANUP;
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                // CLEANUP: 수신된 데이터를 출력하고 data_ready 신호 발생
                CLEANUP: begin
                    data_out <= data_reg;
                    data_ready <= 1'b1;
                    state <= IDLE;
                end

                default:
                    state <= IDLE;
            endcase
        end
    end

endmodule
