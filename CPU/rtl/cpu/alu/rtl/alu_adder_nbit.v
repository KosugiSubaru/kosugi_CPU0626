module alu_adder_nbit (
    input  wire [15:0] i_a,
    input  wire [15:0] i_b,
    input  wire        i_sub, // 0:加算, 1:減算
    output wire [15:0] o_sum,
    output wire        o_cout
);

    // 減算時に2の補数を作成するため、Bの各ビットを反転させた値を保持するワイヤ
    wire [15:0] w_b_xor;
    wire [15:0] w_all_sub_bits;
    
    assign w_all_sub_bits = {16{i_sub}};
    assign w_b_xor = i_b ^ w_all_sub_bits;

    // キャリー伝播用ワイヤ
    wire [15:0] w_carry;

    // -------------------------------------------------------------------------
    // 1ビット全加算器(alu_full_adder_1bit)を16個接続し、リップルキャリー加算器を構成
    // 減算時は cin に i_sub (1) を入力することで、(NOT B + 1) を実現する
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_adder
            alu_full_adder_1bit u_fa (
                .i_a    (i_a[i]),
                .i_b    (w_b_xor[i]),
                .i_cin  (i == 0 ? i_sub : w_carry[i-1]),
                .o_sum  (o_sum[i]),
                .o_cout (w_carry[i])
            );
        end
    endgenerate

    assign o_cout = w_carry[15];

endmodule