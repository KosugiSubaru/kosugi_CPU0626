module imm_extender_adapter_12bit (
    input  wire [11:0] i_imm_part,
    output wire [15:0] o_imm_ext
);

    // 分岐命令(blt, ble, bz)用: 12ビット即値を抽出し、符号拡張して16ビットにする
    // 最上位ビット(i_imm_part[11])を上位4ビット分コピーし、
    // PC相対ジャンプのアドレスオフセットとして計算可能な形式に拡張する
    assign o_imm_ext = { {4{i_imm_part[11]}}, i_imm_part };

endmodule