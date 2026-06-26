module control_unit (
    input  wire [15:0] i_instr,             // 16ビット命令
    input  wire        i_flag_z,            // ゼロフラグ
    input  wire        i_flag_n,            // ネガティブフラグ
    input  wire        i_flag_v,            // オーバーフローフラグ
    output wire        o_reg_write_en,      // レジスタ書き込み許可
    output wire [3:0]  o_alu_op,            // ALU演算選択
    output wire        o_alu_src_sel,       // ALU入力B選択 (0:rs2, 1:imm)
    output wire        o_mem_write_en,      // メモリ書き込み許可
    output wire [2:0]  o_wb_src_sel,        // レジスタ書き込みデータ選択
    output wire [1:0]  o_pc_sel,            // 次のPC選択
    output wire [2:0]  o_imm_type           // 即値拡張形式
);

    // デコーダから出力される命令ごとのワンホット有効信号を接続するワイヤ
    wire [15:0] w_inst_onehot;

    // -------------------------------------------------------------------------
    // 1. Instruction Decoder (Level 1)
    // -------------------------------------------------------------------------
    control_unit_decoder_onehot u_decoder (
        .i_instr       (i_instr),
        .o_inst_onehot (w_inst_onehot)
    );

    // -------------------------------------------------------------------------
    // 2. Signal Generation Logic (Level 1)
    // -------------------------------------------------------------------------
    control_unit_signal_logic u_signal_logic (
        .i_inst_onehot  (w_inst_onehot),
        .i_flag_z       (i_flag_z),
        .i_flag_n       (i_flag_n),
        .i_flag_v       (i_flag_v),
        .o_reg_write_en (o_reg_write_en),
        .o_alu_op       (o_alu_op),
        .o_alu_src_sel  (o_alu_src_sel),
        .o_mem_write_en (o_mem_write_en),
        .o_wb_src_sel   (o_wb_src_sel),
        .o_pc_sel       (o_pc_sel),
        .o_imm_type     (o_imm_type)
        // loadiの仕様変更によりrdの位置が全命令で[7:4]に統一されたため、o_rd_loc_selを削除
    );

endmodule