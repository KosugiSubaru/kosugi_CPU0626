module control_unit_op_match (
    input  wire [7:0] i_opcode,
    input  wire [7:0] i_target,
    output wire       o_match
);

    // loadiの仕様変更により、Opcode幅が4ビットに短縮・統一されたため、
    // 例外的な8ビット比較を廃止し、一律で下位4ビットの比較を行う。
    assign o_match = (i_opcode[3:0] == i_target[3:0]);

endmodule