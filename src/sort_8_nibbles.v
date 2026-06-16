`timescale 1ns / 1ps

module sort_8_nibbles (
    input  [31:0] data_in,
    output [31:0] data_out
);

    wire [3:0] in [0:7];
    wire [3:0] s1 [0:7];
    wire [3:0] s2 [0:7];
    wire [3:0] s3 [0:7];
    wire [3:0] s4 [0:7];
    wire [3:0] s5 [0:7];
    wire [3:0] s6 [0:7];
    wire [3:0] s7 [0:7];
    wire [3:0] s8 [0:7];

    assign in[0] = data_in[ 3: 0];
    assign in[1] = data_in[ 7: 4];
    assign in[2] = data_in[11: 8];
    assign in[3] = data_in[15:12];
    assign in[4] = data_in[19:16];
    assign in[5] = data_in[23:20];
    assign in[6] = data_in[27:24];
    assign in[7] = data_in[31:28];

    assign {s1[1], s1[0]} = (in[0] > in[1]) ? {in[0], in[1]} : {in[1], in[0]};
    assign {s1[3], s1[2]} = (in[2] > in[3]) ? {in[2], in[3]} : {in[3], in[2]};
    assign {s1[5], s1[4]} = (in[4] > in[5]) ? {in[4], in[5]} : {in[5], in[4]};
    assign {s1[7], s1[6]} = (in[6] > in[7]) ? {in[6], in[7]} : {in[7], in[6]};

    assign s2[0] = s1[0];
    assign {s2[2], s2[1]} = (s1[1] > s1[2]) ? {s1[1], s1[2]} : {s1[2], s1[1]};
    assign {s2[4], s2[3]} = (s1[3] > s1[4]) ? {s1[3], s1[4]} : {s1[4], s1[3]};
    assign {s2[6], s2[5]} = (s1[5] > s1[6]) ? {s1[5], s1[6]} : {s1[6], s1[5]};
    assign s2[7] = s1[7];

    assign {s3[1], s3[0]} = (s2[0] > s2[1]) ? {s2[0], s2[1]} : {s2[1], s2[0]};
    assign {s3[3], s3[2]} = (s2[2] > s2[3]) ? {s2[2], s2[3]} : {s2[3], s2[2]};
    assign {s3[5], s3[4]} = (s2[4] > s2[5]) ? {s2[4], s2[5]} : {s2[5], s2[4]};
    assign {s3[7], s3[6]} = (s2[6] > s2[7]) ? {s2[6], s2[7]} : {s2[7], s2[6]};

    assign s4[0] = s3[0];
    assign {s4[2], s4[1]} = (s3[1] > s3[2]) ? {s3[1], s3[2]} : {s3[2], s3[1]};
    assign {s4[4], s4[3]} = (s3[3] > s3[4]) ? {s3[3], s3[4]} : {s3[4], s3[3]};
    assign {s4[6], s4[5]} = (s3[5] > s3[6]) ? {s3[5], s3[6]} : {s3[6], s3[5]};
    assign s4[7] = s3[7];

    assign {s5[1], s5[0]} = (s4[0] > s4[1]) ? {s4[0], s4[1]} : {s4[1], s4[0]};
    assign {s5[3], s5[2]} = (s4[2] > s4[3]) ? {s4[2], s4[3]} : {s4[3], s4[2]};
    assign {s5[5], s5[4]} = (s4[4] > s4[5]) ? {s4[4], s4[5]} : {s4[5], s4[4]};
    assign {s5[7], s5[6]} = (s4[6] > s4[7]) ? {s4[6], s4[7]} : {s4[7], s4[6]};

    assign s6[0] = s5[0];
    assign {s6[2], s6[1]} = (s5[1] > s5[2]) ? {s5[1], s5[2]} : {s5[2], s5[1]};
    assign {s6[4], s6[3]} = (s5[3] > s5[4]) ? {s5[3], s5[4]} : {s5[4], s5[3]};
    assign {s6[6], s6[5]} = (s5[5] > s5[6]) ? {s5[5], s5[6]} : {s5[6], s5[5]};
    assign s6[7] = s5[7];

    assign {s7[1], s7[0]} = (s6[0] > s6[1]) ? {s6[0], s6[1]} : {s6[1], s6[0]};
    assign {s7[3], s7[2]} = (s6[2] > s6[3]) ? {s6[2], s6[3]} : {s6[3], s6[2]};
    assign {s7[5], s7[4]} = (s6[4] > s6[5]) ? {s6[4], s6[5]} : {s6[5], s6[4]};
    assign {s7[7], s7[6]} = (s6[6] > s6[7]) ? {s6[6], s6[7]} : {s6[7], s6[6]};

    assign s8[0] = s7[0];
    assign {s8[2], s8[1]} = (s7[1] > s7[2]) ? {s7[1], s7[2]} : {s7[2], s7[1]};
    assign {s8[4], s8[3]} = (s7[3] > s7[4]) ? {s7[3], s7[4]} : {s7[4], s7[3]};
    assign {s8[6], s8[5]} = (s7[5] > s7[6]) ? {s7[5], s7[6]} : {s7[6], s7[5]};
    assign s8[7] = s7[7];

    assign data_out = {s8[0], s8[1], s8[2], s8[3], s8[4], s8[5], s8[6], s8[7]};

endmodule
