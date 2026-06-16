`timescale 1ns / 1ps

module debounce #(
    parameter DEBOUNCE_CNT = 1000000
)(
    input  clk,
    input  rstn,
    input  btn_in,
    output btn_out
);

    reg [$clog2(DEBOUNCE_CNT)-1:0] cnt;
    reg btn_sync0, btn_sync1;
    reg btn_stable;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            btn_sync0 <= 1'b0;
            btn_sync1 <= 1'b0;
            cnt       <= 0;
            btn_stable <= 1'b0;
        end else begin
            btn_sync0 <= btn_in;
            btn_sync1 <= btn_sync0;

            if (btn_sync1 != btn_stable) begin
                cnt <= cnt + 1'b1;
                if (cnt == DEBOUNCE_CNT - 1) begin
                    btn_stable <= btn_sync1;
                    cnt <= 0;
                end
            end else begin
                cnt <= 0;
            end
        end
    end

    assign btn_out = btn_stable;

endmodule
