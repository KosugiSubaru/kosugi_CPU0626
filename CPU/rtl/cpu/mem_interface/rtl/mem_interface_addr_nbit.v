module mem_interface_addr_nbit (
    input  wire [15:0] i_addr,
    output wire [15:0] o_addr
);

    // -------------------------------------------------------------------------
    // 1ビット信号線(mem_interface_line_1bit)を16個並列に配置する
    // 回路図上で、アドレス情報を運ぶ16ビットのバス構造として視覚化される
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_addr_bus
            mem_interface_line_1bit u_line (
                .i_data (i_addr[i]),
                .o_data (o_addr[i])
            );
        end
    endgenerate

endmodule