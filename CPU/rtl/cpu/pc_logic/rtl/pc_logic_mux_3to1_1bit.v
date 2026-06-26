module pc_logic_mux_3to1_1bit (
    input  wire [1:0] i_sel,
    input  wire       i_data0,
    input  wire       i_data1,
    input  wire       i_data2,
    output wire       o_data
);

    // 2ビットの選択信号に基づき、3つの入力から1つを選択する
    // 論理合成後の回路図において、次PC値の最終決定ロジックの最小単位として視覚化される
    assign o_data = (i_sel == 2'b00) ? i_data0 :
                    (i_sel == 2'b01) ? i_data1 :
                    (i_sel == 2'b10) ? i_data2 : 1'b0;

endmodule