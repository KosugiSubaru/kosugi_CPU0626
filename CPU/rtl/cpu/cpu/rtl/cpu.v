module cpu (
    input  wire        i_clk,               // システムクロック
    input  wire        i_rst_n,             // 非同期リセット
    input  wire [15:0] i_instr,             // 命令メモリからの命令
    input  wire [15:0] i_data_from_dmem,    // データメモリからの読み出しデータ

    output wire [15:0] o_addr_to_dmem,      // データメモリへのアドレス
    output wire [15:0] o_data_to_dmem,      // データメモリへの書き込みデータ
    output wire [15:0] o_addr_to_imem,      // 命令メモリへのアドレス
    output wire        o_dmem_wen,          // データメモリ書き込み有効

    // 観察用の出力ポート
    output wire [15:0] o_observed_reg_data, // 観察用のレジスタデータ（R7）
    output wire [15:0] o_observed_pc_data,  // 観察用のプログラムカウンタデータ（PC）

    // デバッグ・SVA検証用ポート
    output wire [15:0] o_debug_instr,
    output wire [3:0]  o_debug_rs1_addr,
    output wire [15:0] o_debug_rs1_data,
    output wire [3:0]  o_debug_rs2_addr,
    output wire [15:0] o_debug_rs2_data,
    output wire [3:0]  o_debug_rd_addr,
    output wire [15:0] o_debug_rd_data,
    output wire        o_debug_regfile_wen,
    output wire        o_debug_dmem_wen,
    output wire [15:0] o_debug_adder_to_dmem,
    output wire [15:0] o_debug_data_to_dmem,
    output wire [15:0] o_debug_data_from_dmem,
    output wire [15:0] o_debug_now_pc,
    output wire        o_debug_flag_n,
    output wire        o_debug_flag_v,
    output wire        o_debug_flag_z
);

    // ---- 内部信号定義 ----
    wire [15:0] w_pc_current;
    wire [15:0] w_pc_next;
    wire [15:0] w_pc_plus_1;
    wire [15:0] w_imm_ext;
    wire [15:0] w_rs1_data;
    wire [15:0] w_rs2_data;
    wire [15:0] w_alu_b;
    wire [15:0] w_alu_result;
    wire [15:0] w_mem_rdata;
    reg  [15:0] r_wb_data;

    // 制御信号
    wire        w_reg_wen;
    wire [3:0]  w_alu_op;
    wire        w_alu_src_sel;
    wire        w_mem_wen;
    wire [2:0]  w_wb_src_sel;
    wire [2:0]  w_imm_type;
    
    // フラグ信号
    wire [2:0]  w_alu_flags; // [2]:Z, [1]:N, [0]:V
    wire        w_stored_z, w_stored_n, w_stored_v;

    // 命令フィールド分解
    wire [3:0] w_rs2_addr = i_instr[15:12];
    wire [3:0] w_rs1_addr = i_instr[11:8];
    // ISA変更により、全ての命令で書き込み先レジスタ(rd)の位置が [7:4] に統一された
    wire [3:0] w_rd_addr  = i_instr[7:4];

    // ---- モジュール・インスタンス化 ----

    // 1. Program Counter Register
    program_counter_reg_nbit u_pc_reg (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .i_data  (w_pc_next),
        .o_data  (w_pc_current)
    );
    assign o_addr_to_imem = w_pc_current;
    assign o_observed_pc_data = w_pc_current; 

    // 2. Control Unit
    control_unit u_cu (
        .i_instr       (i_instr),
        .i_flag_z      (w_stored_z),
        .i_flag_n      (w_stored_n),
        .i_flag_v      (w_stored_v),
        .o_reg_write_en(w_reg_wen),
        .o_alu_op      (w_alu_op),
        .o_alu_src_sel (w_alu_src_sel),
        .o_mem_write_en(w_mem_wen),
        .o_wb_src_sel  (w_wb_src_sel),
        .o_imm_type    (w_imm_type),
        .o_pc_sel      () // pc_logicで判定するため内部では未使用
    );

    // 3. Register File
    register_file u_regfile (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_rs1_addr(w_rs1_addr),
        .i_rs2_addr(w_rs2_addr),
        .i_rd_addr (w_rd_addr),
        .i_rd_data (r_wb_data),
        .i_wen     (w_reg_wen),
        .o_rs1_data(w_rs1_data),
        .o_rs2_data(w_rs2_data),
        .o_observed_data(o_observed_reg_data) // 観測用の出力データは未接続
    );

    // 4. Immediate Extender
    imm_extender u_imm_ext (
        .i_instr       (i_instr),
        .i_imm_type    (w_imm_type),
        .o_imm_extended(w_imm_ext)
    );

    // 5. ALU
    assign w_alu_b = (w_alu_src_sel) ? w_imm_ext : w_rs2_data;
    alu u_alu (
        .i_a      (w_rs1_data),
        .i_b      (w_alu_b),
        .i_alu_op (w_alu_op),
        .o_result (w_alu_result),
        .o_flag_z (w_alu_flags[2]),
        .o_flag_n (w_alu_flags[1]),
        .o_flag_v (w_alu_flags[0])
    );

    // 6. Flag Register
    wire w_flag_wen = (i_instr[3:2] == 2'b00) || (i_instr[3:0] == 4'b0100) || (i_instr[3:0] == 4'b0101);
    flag_reg u_flags (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_flag_wen (w_flag_wen),
        .i_alu_flags(w_alu_flags),
        .o_flag_z   (w_stored_z),
        .o_flag_n   (w_stored_n),
        .o_flag_v   (w_stored_v)
    );

    // 7. Memory Interface
    mem_interface u_mem_if (
        .i_alu_result      (w_alu_result),
        .i_rs2_data        (w_rs2_data),
        .i_mem_wen         (w_mem_wen),
        .i_dmem_data       (i_data_from_dmem),
        .o_addr_to_dmem    (o_addr_to_dmem),
        .o_data_to_dmem    (o_data_to_dmem),
        .o_dmem_wen        (o_dmem_wen),
        .o_data_from_dmem  (w_mem_rdata)
    );

    // 8. PC Logic
    pc_logic u_pc_logic (
        .i_pc_current(w_pc_current),
        .i_imm       (w_imm_ext),
        .i_rs1_data  (w_rs1_data),
        .i_flag_z    (w_stored_z),
        .i_flag_n    (w_stored_n),
        .i_flag_v    (w_stored_v),
        .i_is_blt    (i_instr[3:0] == 4'b1010),
        .i_is_ble    (i_instr[3:0] == 4'b1011),
        .i_is_bz     (i_instr[3:0] == 4'b1100),
        .i_is_jal    (i_instr[3:0] == 4'b1101),
        .i_is_jalr   (i_instr[3:0] == 4'b1110),
        .o_pc_next   (w_pc_next),
        .o_pc_plus_1 (w_pc_plus_1)
    );

    // Write Back Data Selector
    always @(*) begin
        case (w_wb_src_sel)
            3'd1:    r_wb_data = w_mem_rdata;                   // load
            3'd2:    r_wb_data = w_pc_plus_1;                   // jal, jalr
            3'd3:    r_wb_data = w_imm_ext;                     // loadi, lui
            3'd4:    r_wb_data = w_pc_current + w_imm_ext;      // auipc
            default: r_wb_data = w_alu_result;                  // ALU ops
        endcase
    end

    // ---- デバッグ出力接続 ----
    assign o_debug_instr          = i_instr;
    assign o_debug_rs1_addr       = w_rs1_addr;
    assign o_debug_rs1_data       = w_rs1_data;
    assign o_debug_rs2_addr       = w_rs2_addr;
    assign o_debug_rs2_data       = w_rs2_data;
    assign o_debug_rd_addr        = w_rd_addr;
    assign o_debug_rd_data        = r_wb_data;
    assign o_debug_regfile_wen    = w_reg_wen;
    assign o_debug_dmem_wen       = o_dmem_wen;
    assign o_debug_adder_to_dmem  = o_addr_to_dmem;
    assign o_debug_data_to_dmem   = o_data_to_dmem;
    assign o_debug_data_from_dmem = w_mem_rdata;
    assign o_debug_now_pc         = w_pc_current;
    assign o_debug_flag_n         = w_stored_n;
    assign o_debug_flag_v         = w_stored_v;
    assign o_debug_flag_z         = w_stored_z;

endmodule