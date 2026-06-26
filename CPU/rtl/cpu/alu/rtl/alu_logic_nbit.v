module alu_logic_nbit (
    input  wire [15:0] i_a,
    input  wire [15:0] i_b,
    input  wire        i_sel, // 0: AND, 1: OR
    output wire [15:0] o_res
);

    // -------------------------------------------------------------------------
    // 1ビット論理演算器(alu_logic_1bit)を16個並列に配置する (Pattern Structuring)
    // ビットごとに独立した論理演算を行うため、ビット間のキャリー伝播は存在しない
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_logic
            alu_logic_1bit u_logic_bit (
                .i_a   (i_a[i]),
                .i_b   (i_b[i]),
                .i_sel (i_sel),
                .o_res (o_res[i])
            );
        end
    endgenerate

endmodule