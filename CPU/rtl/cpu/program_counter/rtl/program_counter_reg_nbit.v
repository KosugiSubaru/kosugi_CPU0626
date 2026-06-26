module program_counter_reg_nbit (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire [15:0] i_data,
    output wire [15:0] o_data
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_reg_1bit
            program_counter_reg_1bit u_reg_1bit (
                .i_clk   (i_clk),
                .i_rst_n (i_rst_n),
                .i_d     (i_data[i]),
                .o_q     (o_data[i])
            );
        end
    endgenerate

endmodule