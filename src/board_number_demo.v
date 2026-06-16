`timescale 1ns / 1ps

module board_number_demo #(
    parameter SCAN_DIV_BITS = 15,
    parameter STUDENT_ID    = 32'h02181024,
    parameter DEBOUNCE_BITS = 20
)(
    input  clk,
    input  rstn,
    input  [15:0] sw_i,
    input  btn_sort_raw,
    output [15:0] led_o,
    output [7:0]  disp_seg_o,
    output [7:0]  disp_an_o
);

wire [31:0] cpu_dmem_out;
wire [31:0] display_data;
wire        btn_sort;

localparam DEBOUNCE_CNT = 1 << DEBOUNCE_BITS;

debounce #(
    .DEBOUNCE_CNT(DEBOUNCE_CNT)
) U_DEBOUNCE (
    .clk(clk),
    .rstn(rstn),
    .btn_in(btn_sort_raw),
    .btn_out(btn_sort)
);

sccomp U_SCCOMP (
    .clk(clk),
    .rstn(rstn),
    .reg_sel(5'd0),
    .reg_data(),
    .dmem_out(cpu_dmem_out)
);

assign led_o = sw_i;
assign display_data = btn_sort ? cpu_dmem_out : STUDENT_ID;

scan_7seg #(
    .SCAN_DIV_BITS(SCAN_DIV_BITS)
) U_SCAN_7SEG (
    .clk(clk),
    .rstn(rstn),
    .data(display_data),
    .disp_seg_o(disp_seg_o),
    .disp_an_o(disp_an_o)
);

endmodule
