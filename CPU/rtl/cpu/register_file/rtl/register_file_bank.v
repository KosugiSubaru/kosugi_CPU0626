module register_file_bank (
    input  wire         i_clk,
    input  wire         i_rst_n,
    input  wire [15:0]  i_wen_bus,
    input  wire [15:0]  i_rd_data,
    output wire [255:0] o_all_data
);

    // ISA規定：R0（インデックス0）は常に0を返す
    assign o_all_data[15:0] = 16'h0000;

    // -------------------------------------------------------------------------
    // R1からR15までの15個のレジスタを生成 (Pattern Structuring)
    // 各ワードセル（register_file_word_cell）は16ビット幅のレジスタを構成する
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : gen_reg_bank
            register_file_word_cell u_word_cell (
                .i_clk   (i_clk),
                .i_rst_n (i_rst_n),
                .i_wen   (i_wen_bus[i]),
                .i_data  (i_rd_data),
                .o_data  (o_all_data[i*16 +: 16])
            );
        end
    endgenerate

endmodule