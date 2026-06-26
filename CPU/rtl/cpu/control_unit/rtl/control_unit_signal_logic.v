module control_unit_signal_logic (
    input  wire [15:0] i_inst_onehot,
    input  wire        i_flag_z,
    input  wire        i_flag_n,
    input  wire        i_flag_v,
    output wire        o_reg_write_en,
    output wire [3:0]  o_alu_op,
    output wire        o_alu_src_sel,
    output wire        o_mem_write_en,
    output wire [2:0]  o_wb_src_sel,
    output wire [1:0]  o_pc_sel,
    output wire [2:0]  o_imm_type
);

    // 命令デコード信号のワイヤ展開
    wire is_add   = i_inst_onehot[0];
    wire is_sub   = i_inst_onehot[1];
    wire is_and   = i_inst_onehot[2];
    wire is_or    = i_inst_onehot[3];
    wire is_addi  = i_inst_onehot[4];
    wire is_asi   = i_inst_onehot[5];
    wire is_loadi = i_inst_onehot[6];
    wire is_lui   = i_inst_onehot[7];
    wire is_load  = i_inst_onehot[8];
    wire is_store = i_inst_onehot[9];
    wire is_blt   = i_inst_onehot[10];
    wire is_ble   = i_inst_onehot[11];
    wire is_bz    = i_inst_onehot[12];
    wire is_jal   = i_inst_onehot[13];
    wire is_jalr  = i_inst_onehot[14];
    wire is_auipc = i_inst_onehot[15];

    // 分岐成立条件判定ロジック
    wire branch_taken = (is_blt & (i_flag_n ^ i_flag_v)) |
                        (is_ble & ((i_flag_n ^ i_flag_v) | i_flag_z)) |
                        (is_bz  & i_flag_z);

    // 各種制御信号の論理合成
    assign o_reg_write_en = is_add | is_sub | is_and | is_or | is_addi | is_asi | 
                            is_loadi | is_lui | is_load | is_jal | is_jalr | is_auipc;

    assign o_mem_write_en = is_store;

    assign o_alu_src_sel = is_addi | is_asi | is_load | is_store | is_jalr;

    assign o_alu_op = (is_sub) ? 4'b0001 :
                      (is_and) ? 4'b0010 :
                      (is_or)  ? 4'b0011 : 4'b0000;

    assign o_pc_sel = (is_jal | branch_taken) ? 2'b01 :
                      (is_jalr)               ? 2'b10 : 2'b00;

    assign o_wb_src_sel = (is_load)           ? 3'd1 :
                          (is_jal | is_jalr)  ? 3'd2 :
                          (is_loadi | is_lui) ? 3'd3 :
                          (is_auipc)          ? 3'd4 : 3'd0;

    // 即値拡張形式選択 (imm_extenderの形式に合わせる)
    // loadiは、仕様変更により8bit即値([15:8])をそのまま使用するため、jalと同じ3'd3を選択する
    assign o_imm_type = (is_asi)                ? 3'd1 :
                        (is_store)              ? 3'd2 :
                        (is_jal | is_loadi)     ? 3'd3 :
                        (is_lui | is_auipc)     ? 3'd4 :
                        (is_blt | is_ble | is_bz) ? 3'd5 : 3'd0;

    // loadiのrd位置が[7:4]に統一されたため、o_rd_loc_selのロジックを削除

endmodule