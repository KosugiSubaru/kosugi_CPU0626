module pc_logic_adder_nbit (
    input  wire [15:0] i_a,
    input  wire [15:0] i_b,
    input  wire        i_cin,
    output wire [15:0] o_sum,
    output wire        o_cout
);

    wire [15:0] w_carry;

    // 1ビット全加算器(pc_logic_full_adder_1bit)を16個接続し、リップルキャリー加算器を構成
    // 回路図上で、ビットごとの計算とキャリーの伝播が視覚的に表現される
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pc_fa
            pc_logic_full_adder_1bit u_fa (
                .i_a    (i_a[i]),
                .i_b    (i_b[i]),
                .i_cin  (i == 0 ? i_cin : w_carry[i-1]),
                .o_sum  (o_sum[i]),
                .o_cout (w_carry[i])
            );
        end
    endgenerate

    assign o_cout = w_carry[15];

endmodule