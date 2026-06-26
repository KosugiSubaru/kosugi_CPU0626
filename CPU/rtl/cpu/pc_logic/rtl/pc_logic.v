module pc_logic (
    input  wire [15:0] i_pc_current,    // 現在のPC値
    input  wire [15:0] i_imm,           // 符号拡張済み即値
    input  wire [15:0] i_rs1_data,      // jalr用ベースレジスタ値
    input  wire        i_flag_z,        // ゼロフラグ
    input  wire        i_flag_n,        // ネガティブフラグ
    input  wire        i_flag_v,        // オーバーフローフラグ
    input  wire        i_is_blt,        // 命令判定：blt
    input  wire        i_is_ble,        // 命令判定：ble
    input  wire        i_is_bz,         // 命令判定：bz
    input  wire        i_is_jal,        // 命令判定：jal
    input  wire        i_is_jalr,       // 命令判定：jalr
    output wire [15:0] o_pc_next,       // 次サイクルでPCにセットする値
    output wire [15:0] o_pc_plus_1      // jal/jalrでのrd書き込み用 (PC+1)
);

    // 内部接続用ワイヤ
    wire [15:0] w_pc_plus_1;
    wire [15:0] w_pc_plus_imm;
    wire [15:0] w_rs1_plus_imm;
    wire        w_branch_taken;
    wire [1:0]  w_pc_sel;

    // -------------------------------------------------------------------------
    // 1. Target Address Calculators (Level 1)
    // 次のPC候補となる3つのアドレスを計算する。各加算器が回路図上のブロックとなる。
    // -------------------------------------------------------------------------

    // PC + 1: 通常実行およびリンク用
    pc_logic_adder_nbit u_adder_inc (
        .i_a    (i_pc_current),
        .i_b    (16'd1),
        .i_cin  (1'b0),
        .o_sum  (w_pc_plus_1),
        .o_cout ()
    );

    // PC + imm: 分岐または相対ジャンプ用
    pc_logic_adder_nbit u_adder_imm (
        .i_a    (i_pc_current),
        .i_b    (i_imm),
        .i_cin  (1'b0),
        .o_sum  (w_pc_plus_imm),
        .o_cout ()
    );

    // rs1 + imm: 絶対ジャンプ用
    pc_logic_adder_nbit u_adder_jalr (
        .i_a    (i_rs1_data),
        .i_b    (i_imm),
        .i_cin  (1'b0),
        .o_sum  (w_rs1_plus_imm),
        .o_cout ()
    );

    // -------------------------------------------------------------------------
    // 2. Branch Condition Evaluator (Level 1)
    // フラグと命令から、分岐条件が成立しているか判定する
    // -------------------------------------------------------------------------
    pc_logic_branch_eval u_branch_eval (
        .i_flag_z       (i_flag_z),
        .i_flag_n       (i_flag_n),
        .i_flag_v       (i_flag_v),
        .i_is_blt       (i_is_blt),
        .i_is_ble       (i_is_ble),
        .i_is_bz        (i_is_bz),
        .o_branch_taken (w_branch_taken)
    );

    // -------------------------------------------------------------------------
    // 3. Selection Logic & Next PC Multiplexer (Level 1)
    // 命令と判定結果に基づき、最終的な次PC値を選択する
    // -------------------------------------------------------------------------

    // 選択信号生成: 00:PC+1, 01:Target(PC+imm), 10:Target(rs1+imm)
    assign w_pc_sel = (i_is_jalr)                 ? 2'b10 :
                      (i_is_jal | w_branch_taken) ? 2'b01 : 2'b00;

    pc_logic_mux_3to1_nbit u_pc_mux (
        .i_sel   (w_pc_sel),
        .i_data0 (w_pc_plus_1),
        .i_data1 (w_pc_plus_imm),
        .i_data2 (w_rs1_plus_imm),
        .o_data  (o_pc_next)
    );

    // jal/jalr 用の戻りアドレス出力
    assign o_pc_plus_1 = w_pc_plus_1;

endmodule