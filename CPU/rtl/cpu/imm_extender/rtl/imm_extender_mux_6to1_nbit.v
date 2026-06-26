module imm_extender_mux_6to1_nbit (
    input  wire [2:0]  i_sel,
    input  wire [15:0] i_data0,
    input  wire [15:0] i_data1,
    input  wire [15:0] i_data2,
    input  wire [15:0] i_data3,
    input  wire [15:0] i_data4,
    input  wire [15:0] i_data5,
    output wire [15:0] o_data
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_mux6
            imm_extender_mux_6to1_1bit u_mux_bit (
                .i_sel   (i_sel),
                .i_data0 (i_data0[i]),
                .i_data1 (i_data1[i]),
                .i_data2 (i_data2[i]),
                .i_data3 (i_data3[i]),
                .i_data4 (i_data4[i]),
                .i_data5 (i_data5[i]),
                .o_data  (o_data[i])
            );
        end
    endgenerate

endmodule