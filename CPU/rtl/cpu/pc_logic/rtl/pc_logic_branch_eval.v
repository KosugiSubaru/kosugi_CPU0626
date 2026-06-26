module pc_logic_branch_eval (
    input  wire i_flag_z,        // ゼロフラグ (保存値)
    input  wire i_flag_n,        // ネガティブフラグ (保存値)
    input  wire i_flag_v,        // オーバーフローフラグ (保存値)
    input  wire i_is_blt,        // 命令判定：blt
    input  wire i_is_ble,        // 命令判定：ble
    input  wire i_is_bz,         // 命令判定：bz
    output wire o_branch_taken   // 分岐成立信号
);

    // 符号付き比較ロジック：Less Than (N ^ V)
    wire w_condition_lt;
    assign w_condition_lt = i_flag_n ^ i_flag_v;

    // 符号付き比較ロジック：Less Than or Equal ((N ^ V) | Z)
    wire w_condition_le;
    assign w_condition_le = w_condition_lt | i_flag_z;

    // 各命令に応じた条件成立判定
    wire w_blt_taken;
    wire w_ble_taken;
    wire w_bz_taken;

    assign w_blt_taken = i_is_blt & w_condition_lt;
    assign w_ble_taken = i_is_ble & w_condition_le;
    assign w_bz_taken  = i_is_bz  & i_flag_z;

    // いずれかの分岐条件が成立した場合に信号を出力
    assign o_branch_taken = w_blt_taken | w_ble_taken | w_bz_taken;

endmodule