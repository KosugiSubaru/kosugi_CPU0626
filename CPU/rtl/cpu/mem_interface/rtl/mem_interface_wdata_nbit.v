module mem_interface_wdata_nbit (
    input  wire [15:0] i_wdata,
    output wire [15:0] o_wdata
);

    // -------------------------------------------------------------------------
    // 1ビット信号線(mem_interface_line_1bit)を16個並列に配置する
    // CPUからデータメモリへ送る書き込みデータバスを回路図上で視覚化する
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_wdata_bus
            mem_interface_line_1bit u_line (
                .i_data (i_wdata[i]),
                .o_data (o_wdata[i])
            );
        end
    endgenerate

endmodule