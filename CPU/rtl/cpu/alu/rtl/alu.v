module alu (
    input  wire [15:0] i_a,             // オペランドA (rs1)
    input  wire [15:0] i_b,             // オペランドB (rs2 または 即値)
    input  wire [3:0]  i_alu_op,        // 演算選択信号
    output wire [15:0] o_result,        // 演算結果 (rd)
    output wire        o_flag_z,        // ゼロフラグ
    output wire        o_flag_n,        // ネガティブフラグ
    output wire        o_flag_v         // オーバーフローフラグ
);

    // 内部ユニット接続用ワイヤ
    wire [15:0] w_add_sub_result;
    wire [15:0] w_logic_result;
    wire        w_is_sub;
    wire        w_add_v;
    wire        w_sub_v;

    // 演算種別の判定
    assign w_is_sub = (i_alu_op == 4'b0001);

    // -------------------------------------------------------------------------
    // 1. Arithmetic Unit (Level 1)
    // 加算および減算を実行するユニット
    // -------------------------------------------------------------------------
    alu_adder_nbit u_arith (
        .i_a    (i_a),
        .i_b    (i_b),
        .i_sub  (w_is_sub),
        .o_sum  (w_add_sub_result),
        .o_cout () // フラグ生成に内部ロジックを使用するため未使用
    );

    // -------------------------------------------------------------------------
    // 2. Logic Unit (Level 1)
    // ビットごとの論理演算(AND/OR)を実行するユニット
    // -------------------------------------------------------------------------
    alu_logic_nbit u_logic (
        .i_a    (i_a),
        .i_b    (i_b),
        .i_sel  (i_alu_op[0]), // 0010:AND (sel=0), 0011:OR (sel=1)
        .o_res  (w_logic_result)
    );

    // -------------------------------------------------------------------------
    // 3. Result Selector (Level 1)
    // 算術演算か論理演算かの結果を選択して出力する
    // -------------------------------------------------------------------------
    alu_mux_4to1_nbit u_mux (
        .i_sel   (i_alu_op[1:0]),
        .i_data0 (w_add_sub_result), // 00: add
        .i_data1 (w_add_sub_result), // 01: sub
        .i_data2 (w_logic_result),   // 10: and
        .i_data3 (w_logic_result),   // 11: or
        .o_data  (o_result)
    );

    // -------------------------------------------------------------------------
    // 4. Flag Generation Logic
    // ISAの定義に基づき、現在の演算結果に対するフラグを生成する
    // -------------------------------------------------------------------------
    
    // Zフラグ: 結果が0のとき1
    assign o_flag_z = (o_result == 16'h0000);

    // Nフラグ: 結果の最上位ビット（符号ビット）を抽出
    assign o_flag_n = o_result[15];

    // Vフラグ: 算術演算時のオーバーフローを判定 (ISA定義に準拠)
    // Addition: (rs1[15]==1) & (rs2[15]==1) & (rd[15]==0) | (rs1[15]==0) & (rs2[15]==0) & (rd[15]==1)
    assign w_add_v = (i_a[15] & i_b[15] & ~o_result[15]) | (~i_a[15] & ~i_b[15] & o_result[15]);

    // Subtraction: (rs1[15]==0) & (rs2[15]==1) & (rd[15]==1) | (rs1[15]==1) & (rs2[15]==0) & (rd[15]==0)
    assign w_sub_v = (~i_a[15] & i_b[15] & o_result[15]) | (i_a[15] & ~i_b[15] & ~o_result[15]);

    assign o_flag_v = (w_is_sub) ? w_sub_v : w_add_v;

endmodule