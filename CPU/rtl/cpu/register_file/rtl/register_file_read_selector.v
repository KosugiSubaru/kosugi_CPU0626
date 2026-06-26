module register_file_read_selector (
    input  wire [3:0]   i_addr,
    input  wire [255:0] i_all_data,
    output wire [15:0]  o_data
);

    // 第1段目のMUXの出力を集約 (16ビット * 4個 = 64ビット)
    wire [63:0] w_stage1_data;

    // -------------------------------------------------------------------------
    // 第1段目: 16入力を4つのグループに分け、下位2ビット(addr[1:0])で選択
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_mux_stage1
            register_file_mux_4to1_nbit u_mux_s1 (
                .i_sel   (i_addr[1:0]),
                .i_data0 (i_all_data[(i*4+0)*16 +: 16]),
                .i_data1 (i_all_data[(i*4+1)*16 +: 16]),
                .i_data2 (i_all_data[(i*4+2)*16 +: 16]),
                .i_data3 (i_all_data[(i*4+3)*16 +: 16]),
                .o_data  (w_stage1_data[i*16 +: 16])
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 第2段目: 第1段目の4つの結果から、上位2ビット(addr[3:2])で最終的な1つを選択
    // -------------------------------------------------------------------------
    register_file_mux_4to1_nbit u_mux_stage2 (
        .i_sel   (i_addr[3:2]),
        .i_data0 (w_stage1_data[15:0]),
        .i_data1 (w_stage1_data[31:16]),
        .i_data2 (w_stage1_data[47:32]),
        .i_data3 (w_stage1_data[63:48]),
        .o_data  (o_data)
    );

endmodule