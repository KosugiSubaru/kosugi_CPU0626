module alu_logic_1bit (
    input  wire i_a,
    input  wire i_b,
    input  wire i_sel, // 0: AND, 1: OR
    output wire o_res
);

    // 1ビット単位の論理演算（ANDまたはOR）を実行する
    // ISAの定義に基づくビットごとの論理演算を、ゲートレベルで視覚化する
    assign o_res = (i_sel == 1'b0) ? (i_a & i_b) : (i_a | i_b);

endmodule