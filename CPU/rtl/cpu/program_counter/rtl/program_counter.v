module program_counter (
    input  wire        i_clk,           // システムクロック
    input  wire        i_rst_n,         // 非同期リセット（負論理）
    input  wire [1:0]  i_pc_sel,        // 次のPC選択 (0:PC+1, 1:PC+imm, 2:rs1+imm)
    input  wire [15:0] i_imm,           // 分岐・ジャンプ用即値
    input  wire [15:0] i_rs1_data,      // jalr用ベースアドレス
    output wire [15:0] o_pc_current,    // 現在のPC（命令メモリへ）
    output wire [15:0] o_pc_plus_1      // PC+1（jal/jalrのリンクレジスタ書き込み用）
);

    // 内部接続用ワイヤ
    wire [15:0] w_pc_next;
    wire [15:0] w_pc_plus_imm;
    wire [15:0] w_rs1_plus_imm;

    // -------------------------------------------------------------------------
    // 1. Current PC Register (Level 1 Module)
    // 現在のプログラムカウンタ値を保持する16ビットレジスタ
    // -------------------------------------------------------------------------
    program_counter_reg_nbit u_pc_reg (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_data  (w_pc_next),
        .o_data  (o_pc_current)
    );

    // -------------------------------------------------------------------------
    // 2. Address Adders (Level 1 Modules)
    // 次のアドレス候補を計算する加算器群
    // -------------------------------------------------------------------------

    // PC + 1: 通常の命令実行（インクリメント）
    program_counter_adder_nbit u_adder_inc (
        .i_a     (o_pc_current),
        .i_b     (16'd1),
        .i_cin   (1'b0),
        .o_sum   (o_pc_plus_1),
        .o_cout  ()
    );

    // PC + imm: 相対分岐・ジャンプ (Branch / JAL)
    program_counter_adder_nbit u_adder_branch (
        .i_a     (o_pc_current),
        .i_b     (i_imm),
        .i_cin   (1'b0),
        .o_sum   (w_pc_plus_imm),
        .o_cout  ()
    );

    // rs1 + imm: 絶対ジャンプ (JALR)
    program_counter_adder_nbit u_adder_jalr (
        .i_a     (i_rs1_data),
        .i_b     (i_imm),
        .i_cin   (1'b0),
        .o_sum   (w_rs1_plus_imm),
        .o_cout  ()
    );

    // -------------------------------------------------------------------------
    // 3. Next PC Selector (Level 1 Module)
    // 制御信号に基づき、次のクロックでPCにセットする値を選択する
    // -------------------------------------------------------------------------
    program_counter_mux_3to1_nbit u_pc_mux_next (
        .i_sel   (i_pc_sel),
        .i_data0 (o_pc_plus_1),     // 通常進行
        .i_data1 (w_pc_plus_imm),   // 分岐・JAL
        .i_data2 (w_rs1_plus_imm),  // JALR
        .o_data  (w_pc_next)
    );

endmodule