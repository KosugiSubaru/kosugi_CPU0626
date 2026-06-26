module register_file_word_cell (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire        i_wen,
    input  wire [15:0] i_data,
    output wire [15:0] o_data
);

    // -------------------------------------------------------------------------
    // 1ビットの記憶セル(register_file_bit_cell)を16個並列に配置し、
    // 1ワード（16ビット）のレジスタを構成する。
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_bit_cells
            register_file_bit_cell u_bit_cell (
                .i_clk   (i_clk),
                .i_rst_n (i_rst_n),
                .i_wen   (i_wen),
                .i_d     (i_data[i]),
                .o_q     (o_data[i])
            );
        end
    endgenerate

endmodule