module imm_extender (
    input  wire [15:0] i_instr,        // 16ビット命令
    input  wire [2:0]  i_imm_type,     // 即値拡張形式選択 (control_unitより)
    output wire [15:0] o_imm_extended  // 拡張済み16ビット即値
);

    // 各アダプタモジュールからの16ビット出力を接続するワイヤ
    wire [15:0] w_imm_4bit;
    wire [15:0] w_imm_4bit_shl4;
    wire [15:0] w_imm_4bit_store;
    wire [15:0] w_imm_8bit;
    wire [15:0] w_imm_8bit_shl8;
    wire [15:0] w_imm_12bit;

    // -------------------------------------------------------------------------
    // 1. Immediate Adapters (Level 1)
    // 命令の各フィールドから即値を抽出し、ISAの規定に基づき符号拡張・シフトを行う
    // -------------------------------------------------------------------------

    // 4ビット符号拡張 [15:12] (addi, load, jalr, loadi用)
    imm_extender_adapter_4bit u_adapter_4bit (
        .i_imm_part (i_instr[15:12]),
        .o_imm_ext  (w_imm_4bit)
    );

    // 4ビット符号拡張 + 左4ビットシフト [15:12] (asi用)
    imm_extender_adapter_4bit_shl4 u_adapter_4bit_shl4 (
        .i_imm_part (i_instr[15:12]),
        .o_imm_ext  (w_imm_4bit_shl4)
    );

    // 4ビット符号拡張 [7:4] (store用)
    imm_extender_adapter_4bit_store u_adapter_4bit_store (
        .i_imm_part (i_instr[7:4]),
        .o_imm_ext  (w_imm_4bit_store)
    );

    // 8ビット符号拡張 [15:8] (jal用)
    imm_extender_adapter_8bit u_adapter_8bit (
        .i_imm_part (i_instr[15:8]),
        .o_imm_ext  (w_imm_8bit)
    );

    // 8ビット符号拡張 + 左8ビットシフト [15:8] (lui, auipc用)
    imm_extender_adapter_8bit_shl8 u_adapter_8bit_shl8 (
        .i_imm_part (i_instr[15:8]),
        .o_imm_ext  (w_imm_8bit_shl8)
    );

    // 12ビット符号拡張 [15:4] (分岐命令用)
    imm_extender_adapter_12bit u_adapter_12bit (
        .i_imm_part (i_instr[15:4]),
        .o_imm_ext  (w_imm_12bit)
    );

    // -------------------------------------------------------------------------
    // 2. Output Selector (Level 1)
    // 制御信号(i_imm_type)に基づき、最終的な16ビット即値を選択する
    // -------------------------------------------------------------------------
    imm_extender_mux_6to1_nbit u_imm_mux (
        .i_sel   (i_imm_type),
        .i_data0 (w_imm_4bit),
        .i_data1 (w_imm_4bit_shl4),
        .i_data2 (w_imm_4bit_store),
        .i_data3 (w_imm_8bit),
        .i_data4 (w_imm_8bit_shl8),
        .i_data5 (w_imm_12bit),
        .o_data  (o_imm_extended)
    );

endmodule