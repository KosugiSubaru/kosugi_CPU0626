module alu_mux_4to1_1bit (
    input  wire [1:0] i_sel,
    input  wire       i_data0,
    input  wire       i_data1,
    input  wire       i_data2,
    input  wire       i_data3,
    output wire       o_data
);

    // 2ビットの選択信号に基づき、4つの入力から1つを選択する最小単位
    // 論理合成後の回路図において、演算結果の最終選択ロジックとして視覚化される
    assign o_data = (i_sel == 2'b00) ? i_data0 :
                    (i_sel == 2'b01) ? i_data1 :
                    (i_sel == 2'b10) ? i_data2 : i_data3;

endmodule