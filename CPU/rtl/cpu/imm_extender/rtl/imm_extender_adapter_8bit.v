module imm_extender_adapter_8bit (
    input  wire [7:0]  i_imm_part,
    output wire [15:0] o_imm_ext
);

    // jal命令用: 8ビット即値を抽出し、符号拡張して16ビットにする
    // 符号ビット(i_imm_part[7])を上位8ビットにコピーすることで、
    // 正負を維持したままデータ幅を拡張する
    assign o_imm_ext = { {8{i_imm_part[7]}}, i_imm_part };

endmodule