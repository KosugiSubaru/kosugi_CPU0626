module imm_extender_adapter_8bit_shl8 (
    input  wire [7:0]  i_imm_part,
    output wire [15:0] o_imm_ext
);

    // lui, auipc命令用: 8ビット即値を抽出し、符号拡張後に左へ8ビットシフトする
    // 回路的には、入力された8ビットを[15:8]ビット目に配線し、
    // 下位8ビットを0で埋めることで、上位ビットへのデータロードを実現する
    assign o_imm_ext = { i_imm_part, 8'b00000000 };

endmodule