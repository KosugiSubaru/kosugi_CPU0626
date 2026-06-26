module program_counter_mux_3to1_nbit (
    input  wire [1:0]  i_sel,
    input  wire [15:0] i_data0,
    input  wire [15:0] i_data1,
    input  wire [15:0] i_data2,
    output wire [15:0] o_data
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_mux
            program_counter_mux_3to1_1bit u_mux_1bit (
                .i_sel   (i_sel),
                .i_data0 (i_data0[i]),
                .i_data1 (i_data1[i]),
                .i_data2 (i_data2[i]),
                .o_data  (o_data[i])
            );
        end
    endgenerate

endmodule