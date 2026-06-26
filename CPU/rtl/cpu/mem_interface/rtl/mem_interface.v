module mem_interface (
    input  wire [15:0] i_alu_result,      // ALUからの演算結果（メモリアドレス）
    input  wire [15:0] i_rs2_data,        // レジスタからの書き込みデータ (store用)
    input  wire        i_mem_wen,         // メモリ書き込み有効信号 (Control Unitより)
    input  wire [15:0] i_dmem_data,       // 外部データメモリからの読み出しデータ
    output wire [15:0] o_addr_to_dmem,    // データメモリへのアドレス出力
    output wire [15:0] o_data_to_dmem,    // データメモリへの書き込みデータ出力
    output wire        o_dmem_wen,        // データメモリへの書き込み有効出力
    output wire [15:0] o_data_from_dmem   // CPU内部への読み出しデータ入力
);

    // 書き込み許可信号の極性管理とパススルー
    assign o_dmem_wen = i_mem_wen;

    // -------------------------------------------------------------------------
    // 1. Address Port (Level 1)
    // ALUの演算結果をデータメモリのアドレスバスへ引き渡すパスを構成
    // -------------------------------------------------------------------------
    mem_interface_addr_nbit u_addr_path (
        .i_addr (i_alu_result),
        .o_addr (o_addr_to_dmem)
    );

    // -------------------------------------------------------------------------
    // 2. Write Data Port (Level 1)
    // CPU内部のレジスタデータをメモリの入力バスへ引き渡すパスを構成
    // -------------------------------------------------------------------------
    mem_interface_wdata_nbit u_wdata_path (
        .i_wdata (i_rs2_data),
        .o_wdata (o_data_to_dmem)
    );

    // -------------------------------------------------------------------------
    // 3. Read Data Port (Level 1)
    // メモリからの読み出しデータをCPU内部のデータパスへ引き渡すパスを構成
    // -------------------------------------------------------------------------
    mem_interface_rdata_nbit u_rdata_path (
        .i_rdata (i_dmem_data),
        .o_rdata (o_data_from_dmem)
    );

endmodule