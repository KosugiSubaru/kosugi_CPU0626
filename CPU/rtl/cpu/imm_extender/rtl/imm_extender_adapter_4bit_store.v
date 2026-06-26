module imm_extender_adapter_4bit_store (
    input  wire [3:0]  i_imm_part,
    output wire [15:0] o_imm_ext
);

    // store命令用: 命令の[7:4]ビットに配置されている即値を抽出し、符号拡張する
    // 回路図上では、命令の特定のビット位置からデータを引き出し、
    // 16ビットへ拡張する専用のパスとして視覚化される
    assign o_imm_ext = { {12{i_imm_part[3]}}, i_imm_part };

endmodule