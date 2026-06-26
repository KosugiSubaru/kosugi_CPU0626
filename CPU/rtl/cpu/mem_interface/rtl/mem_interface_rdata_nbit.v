module mem_interface_rdata_nbit (
    input  wire [15:0] i_rdata,
    output wire [15:0] o_rdata
);

    // -------------------------------------------------------------------------
    // 1ビット信号線(mem_interface_line_1bit)を16個並列に配置する
    // データメモリからCPU内部へ戻る読み出しデータバスを回路図上で視覚化する
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_rdata_bus
            mem_interface_line_1bit u_line (
                .i_data (i_rdata[i]),
                .o_data (o_rdata[i])
            );
        end
    endgenerate

endmodule