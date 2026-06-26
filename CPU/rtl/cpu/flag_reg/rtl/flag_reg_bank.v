module flag_reg_bank (
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_wen,
    input  wire [2:0] i_alu_flags,
    output wire [2:0] o_stored_flags
);

    // -------------------------------------------------------------------------
    // 3つのフラグビット (Z, N, V) を並列にインスタンス化
    // generate文を使用することで、回路図上で整列されたレジスタ群として視覚化される
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 3; i = i + 1) begin : gen_flag_bits
            flag_reg_bit u_flag_bit (
                .i_clk   (i_clk),
                .i_rst_n (i_rst_n),
                .i_wen   (i_wen),
                .i_d     (i_alu_flags[i]),
                .o_q     (o_stored_flags[i])
            );
        end
    endgenerate

endmodule