module flag_reg_bit (
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_wen,
    input  wire i_d,
    output reg  o_q
);

    // 書き込み許可信号(i_wen)付きの1ビットD-フリップフロップ。
    // クロック同期でフラグの状態を保持し、条件分岐命令が「1クロック前の結果」を参照できるようにする。
    // 論理合成後、個別のフラグビットを記憶する最小単位のブロックとして視覚化される。
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_q <= 1'b0;
        end else if (i_wen) begin
            o_q <= i_d;
        end
    end

endmodule