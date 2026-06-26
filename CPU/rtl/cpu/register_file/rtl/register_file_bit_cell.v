module register_file_bit_cell (
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_wen,
    input  wire i_d,
    output reg  o_q
);

    // 書き込み有効信号(i_wen)付きの1ビットD-フリップフロップ。
    // クロック立ち上がり時にi_wenが有効であれば、入力を内部状態に反映する。
    // 論理合成後、レジスタファイルを構成する最小の記憶素子として視覚化される。
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_q <= 1'b0;
        end else if (i_wen) begin
            o_q <= i_d;
        end
    end

endmodule