module flag_reg (
    input  wire       i_clk,        // システムクロック
    input  wire       i_rst_n,      // 非同期リセット（負論理）
    input  wire       i_flag_wen,   // フラグ更新有効信号（Control Unitより）
    input  wire [2:0] i_alu_flags,  // ALUからの最新フラグ [2:Z, 1:N, 0:V]
    output wire       o_flag_z,     // 保存されているゼロフラグ
    output wire       o_flag_n,     // 保存されているネガティブフラグ
    output wire       o_flag_v      // 保存されているオーバーフローフラグ
);

    // 内部接続用ワイヤ
    wire [2:0] w_stored_flags;

    // -------------------------------------------------------------------------
    // 1. Flag Register Bank (Level 1)
    // Z, N, Vの3ビット分を保持するレジスタ群をインスタンス化
    // -------------------------------------------------------------------------
    flag_reg_bank u_flag_bank (
        .i_clk          (i_clk),
        .i_rst_n        (i_rst_n),
        .i_wen          (i_flag_wen),
        .i_alu_flags    (i_alu_flags),
        .o_stored_flags (w_stored_flags)
    );

    // 各フラグを個別に出力へ配線
    assign o_flag_z = w_stored_flags[2];
    assign o_flag_n = w_stored_flags[1];
    assign o_flag_v = w_stored_flags[0];

endmodule