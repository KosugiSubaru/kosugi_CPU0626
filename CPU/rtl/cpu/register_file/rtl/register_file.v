module register_file (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire [3:0]  i_rs1_addr,
    input  wire [3:0]  i_rs2_addr,
    input  wire [3:0]  i_rd_addr,
    input  wire [15:0] i_rd_data,
    input  wire        i_wen,
    output wire [15:0] o_rs1_data,
    output wire [15:0] o_rs2_data,
    output wire [15:0] o_observed_data // 追加: 観測用の出力データ
);

    // 16本のレジスタに対応する書き込み有効信号（ワンホット）
    wire [15:0] w_reg_wen_onehot;
    // 全レジスタの出力データを集約したワイヤ (16ビット * 16本 = 256ビット)
    wire [255:0] w_all_regs_data;

    // -------------------------------------------------------------------------
    // 1. Write Decoder (Level 1)
    // 書き込みアドレスと有効信号から、対象レジスタ1本を特定する
    // -------------------------------------------------------------------------
    register_file_write_decoder u_write_decoder (
        .i_rd_addr (i_rd_addr),
        .i_wen     (i_wen),
        .o_wen_bus (w_reg_wen_onehot)
    );

    // -------------------------------------------------------------------------
    // 2. Register Bank (Level 1)
    // 16本の16ビットレジスタの実体。R0は常に0を出力する
    // -------------------------------------------------------------------------
    register_file_bank u_reg_bank (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_wen_bus  (w_reg_wen_onehot),
        .i_rd_data  (i_rd_data),
        .o_all_data (w_all_regs_data)
    );

    // -------------------------------------------------------------------------
    // 3. Read Selectors (Level 1)
    // 集約された全レジスタデータから、指定されたアドレスのデータを選択する
    // -------------------------------------------------------------------------
    
    // rs1用読み出しポート
    register_file_read_selector u_read_sel_rs1 (
        .i_addr     (i_rs1_addr),
        .i_all_data (w_all_regs_data),
        .o_data     (o_rs1_data)
    );

    // rs2用読み出しポート
    register_file_read_selector u_read_sel_rs2 (
        .i_addr     (i_rs2_addr),
        .i_all_data (w_all_regs_data),
        .o_data     (o_rs2_data)
    );

    // 観測用の出力データ（R7）
    assign o_observed_data = w_all_regs_data[7*16 +: 16];

endmodule