module imm_extender_adapter_4bit (
    input  wire [3:0]  i_imm_part,
    output wire [15:0] o_imm_ext
);

    // 4ビット即値の最上位ビット(i_imm_part[3])を符号ビットとして、
    // 上位12ビット分コピー（符号拡張）して16ビットにする。
    assign o_imm_ext = { {12{i_imm_part[3]}}, i_imm_part };

endmodule