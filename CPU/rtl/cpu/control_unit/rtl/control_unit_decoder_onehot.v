module control_unit_decoder_onehot (
    input  wire [15:0] i_instr,
    output wire [15:0] o_inst_onehot
);

    // 命令のOpcodeが含まれる下位8ビットを抽出
    // ISA定義により、ほとんどの命令は[3:0]、loadiのみ[7:0]を使用するため8ビットで受ける
    wire [7:0] w_instr_op_part;
    assign w_instr_op_part = i_instr[7:0];

    // -------------------------------------------------------------------------
    // 16個の命令判定モジュールを並列に配置 (Pattern Structuring)
    // 各インスタンスが特定の命令（0:add 〜 15:auipc）に対応し、
    // 現在の命令が自身と一致する場合のみ信号を1にする。
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_inst_match
            control_unit_op_match u_match (
                .i_opcode (w_instr_op_part),
                .i_target (i[7:0]),
                .o_match  (o_inst_onehot[i])
            );
        end
    endgenerate

endmodule