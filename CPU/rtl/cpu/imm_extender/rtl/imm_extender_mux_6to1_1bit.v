module imm_extender_mux_6to1_1bit (
    input  wire [2:0] i_sel,
    input  wire       i_data0,
    input  wire       i_data1,
    input  wire       i_data2,
    input  wire       i_data3,
    input  wire       i_data4,
    input  wire       i_data5,
    output wire       o_data
);

    // 3ビットの選択信号(i_sel)に基づき、6つの入力から1つを選択する
    // 論理合成後、各ビットごとに独立した選択ロジックとして視覚化される
    assign o_data = (i_sel == 3'd0) ? i_data0 :
                    (i_sel == 3'd1) ? i_data1 :
                    (i_sel == 3'd2) ? i_data2 :
                    (i_sel == 3'd3) ? i_data3 :
                    (i_sel == 3'd4) ? i_data4 :
                    (i_sel == 3'd5) ? i_data5 : 1'b0;

endmodule