module pc_logic_mux_3to1_nbit (
    input  wire [1:0]  i_sel,   // 選択信号 (00:PC+1, 01:PC+imm, 10:rs1+imm)
    input  wire [15:0] i_data0, // 入力0 (PC+1)
    input  wire [15:0] i_data1, // 入力1 (PC+imm)
    input  wire [15:0] i_data2, // 入力2 (rs1+imm)
    output wire [15:0] o_data   // 選択された次のPC値
);

    // -------------------------------------------------------------------------
    // 1ビット3入力セレクタ(pc_logic_mux_3to1_1bit)を16個並列に配置する
    // 回路図上で、16ビット幅のデータパスが切り替わる様子が視覚化される
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pc_mux
            pc_logic_mux_3to1_1bit u_mux_bit (
                .i_sel   (i_sel),
                .i_data0 (i_data0[i]),
                .i_data1 (i_data1[i]),
                .i_data2 (i_data2[i]),
                .o_data  (o_data[i])
            );
        end
    endgenerate

endmodule