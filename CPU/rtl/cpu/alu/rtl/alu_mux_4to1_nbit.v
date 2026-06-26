module alu_mux_4to1_nbit (
    input  wire [1:0]  i_sel,   // 選択信号 (00:ADD, 01:SUB, 10:AND, 11:OR)
    input  wire [15:0] i_data0, // 入力0
    input  wire [15:0] i_data1, // 入力1
    input  wire [15:0] i_data2, // 入力2
    input  wire [15:0] i_data3, // 入力3
    output wire [15:0] o_data   // 選択された出力
);

    // -------------------------------------------------------------------------
    // 1ビット4入力セレクタ(alu_mux_4to1_1bit)を16個並列に配置する (Pattern Structuring)
    // ビットごとに独立して動作し、16ビット幅のデータパス選択を構成する
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_mux
            alu_mux_4to1_1bit u_mux_bit (
                .i_sel   (i_sel),
                .i_data0 (i_data0[i]),
                .i_data1 (i_data1[i]),
                .i_data2 (i_data2[i]),
                .i_data3 (i_data3[i]),
                .o_data  (o_data[i])
            );
        end
    endgenerate

endmodule