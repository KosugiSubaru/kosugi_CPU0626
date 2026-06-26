module register_file_mux_4to1_nbit (
    input  wire [1:0]  i_sel,
    input  wire [15:0] i_data0,
    input  wire [15:0] i_data1,
    input  wire [15:0] i_data2,
    input  wire [15:0] i_data3,
    output wire [15:0] o_data
);

    // 2ビットの選択信号に基づき、4つの16ビット入力から1つを選択する。
    // 論理合成後の回路図において、16ビット幅のデータパスを切り替える
    // マルチプレクサブロックとして視覚化される。
    assign o_data = (i_sel == 2'b00) ? i_data0 :
                    (i_sel == 2'b01) ? i_data1 :
                    (i_sel == 2'b10) ? i_data2 : i_data3;

endmodule