module register_file_write_decoder (
    input  wire [3:0]  i_rd_addr,
    input  wire        i_wen,
    output wire [15:0] o_wen_bus
);

    // 4ビットのレジスタアドレスを16ビットのワンホット（One-hot）信号に変換する。
    // i_wenが0の場合は全てのビットを0（書き込み禁止）とする。
    // 論理合成ツールにおいて、アドレスデコード用の組み合わせ回路として視覚化される。
    assign o_wen_bus = (i_wen) ? (16'h0001 << i_rd_addr) : 16'h0000;

endmodule