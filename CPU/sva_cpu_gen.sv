`ifndef SVA_CPU_GEN_SV
`define SVA_CPU_GEN_SV

// Auto-generated SVA verification module for ALU instructions
// Generated from ISA definition

module sva_cpu_gen (
    input wire        i_clk,
    input wire        i_rst_n,
    input wire [15:0] w_debug_instr,
    input wire [3:0]  w_debug_rs1_addr,
    input wire [15:0] w_debug_rs1_data,
    input wire [3:0]  w_debug_rs2_addr,
    input wire [15:0] w_debug_rs2_data,
    input wire [3:0]  w_debug_rd_addr,
    input wire [15:0] w_debug_rd_data,
    input wire        w_debug_regfile_wen,
    input wire        w_debug_dmem_wen,
    input wire [15:0] w_debug_adder_to_dmem,
    input wire [15:0] w_debug_data_to_dmem,
    input wire [15:0] w_debug_data_from_dmem,
    input wire [15:0] w_debug_now_pc,
    input wire        w_debug_flag_n,
    input wire        w_debug_flag_v,
    input wire        w_debug_flag_z

);

    //=========================================================================
    // Expected Result Calculation (ALU / compare)
    //=========================================================================

    // PC increment size (bytes) for link address and not-taken branch
    localparam [15:0] PC_INCR = 1;

    localparam [3:0] OP_ADD = 4'b0000;
    localparam [3:0] OP_SUB = 4'b0001;
    localparam [3:0] OP_AND = 4'b0010;
    localparam [3:0] OP_OR = 4'b0011;
    localparam [3:0] OP_ADDI = 4'b0100;
    localparam [3:0] OP_ASI = 4'b0101;
    localparam [3:0] OP_LOADI = 4'b0110;
    localparam [3:0] OP_LUI = 4'b0111;
    localparam [3:0] OP_LOAD = 4'b1000;
    localparam [3:0] OP_STORE = 4'b1001;
    localparam [3:0] OP_BLT = 4'b1010;
    localparam [3:0] OP_BLE = 4'b1011;
    localparam [3:0] OP_BZ = 4'b1100;
    localparam [3:0] OP_JAL = 4'b1101;
    localparam [3:0] OP_JALR = 4'b1110;
    localparam [3:0] OP_AUIPC = 4'b1111;

    //==========================================================================
    // Immediate Value Extraction
    //==========================================================================
    reg [15:0] imm_value;
    always@(*) begin
        imm_value = 16'h0000;
        if (w_debug_instr[3:0] == OP_ADDI) imm_value = {{12{w_debug_instr[15]}}, w_debug_instr[15:12]};
        if (w_debug_instr[3:0] == OP_ASI) imm_value = {{12'b000000000000}, w_debug_instr[15:12]};
        if (w_debug_instr[3:0] == OP_LOADI) imm_value = {{8{w_debug_instr[15]}}, w_debug_instr[15:8]};
        if (w_debug_instr[3:0] == OP_LUI) imm_value = {{8{w_debug_instr[15]}}, w_debug_instr[15:8]};
        if (w_debug_instr[3:0] == OP_LOAD) imm_value = {{12{w_debug_instr[15]}}, w_debug_instr[15:12]};
        if (w_debug_instr[3:0] == OP_STORE) imm_value = {{12{w_debug_instr[7]}}, w_debug_instr[7:4]};
        if (w_debug_instr[3:0] == OP_BLT) imm_value = {{4{w_debug_instr[15]}}, w_debug_instr[15:4]};
        if (w_debug_instr[3:0] == OP_BLE) imm_value = {{4{w_debug_instr[15]}}, w_debug_instr[15:4]};
        if (w_debug_instr[3:0] == OP_BZ) imm_value = {{4{w_debug_instr[15]}}, w_debug_instr[15:4]};
        if (w_debug_instr[3:0] == OP_JAL) imm_value = {{8{w_debug_instr[15]}}, w_debug_instr[15:8]};
        if (w_debug_instr[3:0] == OP_JALR) imm_value = {{12{w_debug_instr[15]}}, w_debug_instr[15:12]};
        if (w_debug_instr[3:0] == OP_AUIPC) imm_value = {{8{w_debug_instr[15]}}, w_debug_instr[15:8]};
    end

    //==========================================================================
    // Expected Result Calculation (ALU only)
    //==========================================================================
        reg signed [15:0] expected_result;
        always @(*) begin
        expected_result = 16'h0000;
        if (w_debug_instr[3:0] == OP_ADD) expected_result = w_debug_rs1_data + w_debug_rs2_data;
        if (w_debug_instr[3:0] == OP_SUB) expected_result = w_debug_rs1_data - w_debug_rs2_data;
        if (w_debug_instr[3:0] == OP_AND) expected_result = w_debug_rs1_data & w_debug_rs2_data;
        if (w_debug_instr[3:0] == OP_OR) expected_result = w_debug_rs1_data | w_debug_rs2_data;
        if (w_debug_instr[3:0] == OP_ADDI) expected_result = w_debug_rs1_data + imm_value;
        if (w_debug_instr[3:0] == OP_ASI) expected_result = w_debug_rs1_data + (imm_value << 4);
        if (w_debug_instr[3:0] == OP_LOADI) expected_result = imm_value;
        if (w_debug_instr[3:0] == OP_LUI) expected_result = (imm_value << 8);
        if (w_debug_instr[3:0] == OP_AUIPC) expected_result = w_debug_now_pc + (imm_value << 8);
        end

    //==========================================================================
    // Expected Memory Address / Store Data Calculation
    //==========================================================================
    reg [15:0] expected_mem_addr;
    reg [15:0] expected_store_data;
    always @(*) begin
        expected_mem_addr  = 16'h0000;
        expected_store_data = 16'h0000;
        if (w_debug_instr[3:0] == OP_LOAD) begin
            expected_mem_addr = w_debug_rs1_data + imm_value;
        end
        if (w_debug_instr[3:0] == OP_STORE) begin
            expected_mem_addr = w_debug_rs1_data + imm_value;
            expected_store_data = w_debug_rs2_data;
        end
    end


    //==========================================================================
    // Expected Jump Target Calculation
    //==========================================================================
    reg [15:0] expected_jump_target;
    always @(*) begin
        expected_jump_target = 16'h0000;
        if (w_debug_instr[3:0] == OP_JAL) expected_jump_target = w_debug_now_pc + imm_value;
        if (w_debug_instr[3:0] == OP_JALR) expected_jump_target = w_debug_rs1_data + imm_value;
    end


    //==========================================================================
    // Expected Branch Target Calculation
    // PC相対: w_debug_now_pc + imm_value / 絶対: imm_value or rs1+imm
    //==========================================================================
    reg [15:0] expected_branch_target;
    always @(*) begin
        expected_branch_target = 16'h0000;
        if (w_debug_instr[3:0] == OP_BLT) expected_branch_target = w_debug_now_pc + imm_value;
        if (w_debug_instr[3:0] == OP_BLE) expected_branch_target = w_debug_now_pc + imm_value;
        if (w_debug_instr[3:0] == OP_BZ) expected_branch_target = w_debug_now_pc + imm_value;
    end

    //==========================================================================
    // Instruction Verification (BRANCH Operations)
    // タイミング:
    //   現クロック(N)  : 命令デコード・条件評価、regfile_wen/dmem_wen == 0 を確認
    //   次クロック(N+1): PC が条件に応じて pc+imm もしくは pc+instr_bytes になることを確認
    //
    //  またがない方式 (BRANCH_REG): beq, blt など
    //    → 同一命令でレジスタ比較を行い、次サイクルのPCを検証
    //  またぐ方式 (BRANCH_FLAG): bz, bnz, bc など
    //    → 前命令のフラグ (w_debug_flag_*) を参照し、次サイクルのPCを検証
    //==========================================================================

    // branch less than (BLT)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_BLT) |=>
        ($past(w_debug_regfile_wen) == 0) && ($past(w_debug_dmem_wen) == 0) &&
        (w_debug_now_pc == ($past(w_debug_flag_n ^ w_debug_flag_v) ?
                                 $past(expected_branch_target) :
                                 $past(w_debug_now_pc) + PC_INCR))
    ) else $error("[TIME=%0t] BLT failed: cond=%b next_pc=0x%04h(exp_taken=0x%04h exp_notaken=0x%04h)",
                  $time, $past(w_debug_flag_n ^ w_debug_flag_v),
                  w_debug_now_pc, $past(expected_branch_target),
                  $past(w_debug_now_pc) + PC_INCR);

    // branch less than or equal (BLE)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_BLE) |=>
        ($past(w_debug_regfile_wen) == 0) && ($past(w_debug_dmem_wen) == 0) &&
        (w_debug_now_pc == ($past(w_debug_flag_n ^ w_debug_flag_v | w_debug_flag_z) ?
                                 $past(expected_branch_target) :
                                 $past(w_debug_now_pc) + PC_INCR))
    ) else $error("[TIME=%0t] BLE failed: cond=%b next_pc=0x%04h(exp_taken=0x%04h exp_notaken=0x%04h)",
                  $time, $past(w_debug_flag_n ^ w_debug_flag_v | w_debug_flag_z),
                  w_debug_now_pc, $past(expected_branch_target),
                  $past(w_debug_now_pc) + PC_INCR);

    // branch zero (BZ)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_BZ) |=>
        ($past(w_debug_regfile_wen) == 0) && ($past(w_debug_dmem_wen) == 0) &&
        (w_debug_now_pc == ($past(w_debug_flag_z) ?
                                 $past(expected_branch_target) :
                                 $past(w_debug_now_pc) + PC_INCR))
    ) else $error("[TIME=%0t] BZ failed: cond=%b next_pc=0x%04h(exp_taken=0x%04h exp_notaken=0x%04h)",
                  $time, $past(w_debug_flag_z),
                  w_debug_now_pc, $past(expected_branch_target),
                  $past(w_debug_now_pc) + PC_INCR);



    //==========================================================================
    // Zero Register Check (x0)
    //==========================================================================

    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_rs1_addr == 0) |-> (w_debug_rs1_data == 0)
    ) else $error("[TIME=%0t] Zero register (x0) is not zero (RS1): 0x%04h", $time, w_debug_rs1_data);

    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_rs2_addr == 0) |-> (w_debug_rs2_data == 0)
    ) else $error("[TIME=%0t] Zero register (x0) is not zero (RS2): 0x%04h", $time, w_debug_rs2_data);



    //==========================================================================
    // Instruction Verification (ALU Operations)
    //==========================================================================
    
    // addition (ADD)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_ADD) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] ADD failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // subtraction (SUB)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_SUB) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] SUB failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // logical and (AND)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_AND) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] AND failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // logical or (OR)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_OR) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] OR failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // add immediate (ADDI)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_ADDI) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] ADDI failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // add shifted immediate (ASI)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_ASI) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] ASI failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // load immediate (LOADI)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_LOADI) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] LOADI failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // load upper immediate (LUI)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_LUI) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] LUI failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    // add upper immediate to pc (AUIPC)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_AUIPC) |-> 
        ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] AUIPC failed: R%0d = 0x%04h, expected 0x%04h",
                  $time, w_debug_rd_addr, w_debug_rd_data, expected_result);

    

    //==========================================================================
    // Instruction Verification (LOAD Operations)
    //==========================================================================

    // load (LOAD)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_LOAD) |->
        ((w_debug_adder_to_dmem == expected_mem_addr) &&
         (w_debug_rd_data == w_debug_data_from_dmem) &&
         w_debug_regfile_wen && (w_debug_dmem_wen == 0))
    ) else $error("[TIME=%0t] LOAD failed: addr=0x%04h(exp=0x%04h) R%0d=0x%04h(mem=0x%04h)",
                  $time, w_debug_adder_to_dmem, expected_mem_addr,
                  w_debug_rd_addr, w_debug_rd_data, w_debug_data_from_dmem);

    //==========================================================================
    // Instruction Verification (STORE Operations)
    //==========================================================================

    // store (STORE)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_STORE) |->
        ((w_debug_adder_to_dmem == expected_mem_addr) &&
         (w_debug_data_to_dmem == expected_store_data) &&
         w_debug_dmem_wen && (w_debug_regfile_wen == 0))
    ) else $error("[TIME=%0t] STORE failed: addr=0x%04h(exp=0x%04h) wdata=0x%04h(exp=0x%04h)",
                  $time, w_debug_adder_to_dmem, expected_mem_addr,
                  w_debug_data_to_dmem, expected_store_data);



    //==========================================================================
    // Instruction Verification (JUMP Operations)
    // 現在クロック: リンクレジスタ書き込み確認（リンクあり命令のみ）
    // 次クロック  : w_debug_now_pc == expected_jump_target を確認（##1）
    //==========================================================================

    // jump and link (JAL)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_JAL) |=>
        ($past(w_debug_rd_data) == $past(w_debug_now_pc) + PC_INCR) &&
        $past(w_debug_regfile_wen) && ($past(w_debug_dmem_wen) == 0) &&
        (w_debug_now_pc == $past(expected_jump_target))
    ) else $error("[TIME=%0t] JAL failed: rd=0x%04h(link_exp=0x%04h) next_pc=0x%04h(jump_exp=0x%04h)",
                  $time, $past(w_debug_rd_data), $past(w_debug_now_pc) + PC_INCR,
                  w_debug_now_pc, $past(expected_jump_target));

    // jump and link register (JALR)
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_JALR) |=>
        ($past(w_debug_rd_data) == $past(w_debug_now_pc) + PC_INCR) &&
        $past(w_debug_regfile_wen) && ($past(w_debug_dmem_wen) == 0) &&
        (w_debug_now_pc == $past(expected_jump_target))
    ) else $error("[TIME=%0t] JALR failed: rd=0x%04h(link_exp=0x%04h) next_pc=0x%04h(jump_exp=0x%04h)",
                  $time, $past(w_debug_rd_data), $past(w_debug_now_pc) + PC_INCR,
                  w_debug_now_pc, $past(expected_jump_target));



    //==========================================================================
    // Flag Update Verification
    // flags: が定義された命令実行時、命令固有のフラグ条件式で
    // 各フラグが正しく更新されていることを次サイクルで検証する
    //==========================================================================

    // addition (ADD)
    wire expected_flag_add_z = (w_debug_rd_data==0);
    wire expected_flag_add_n = (w_debug_rd_data[15]);
    wire expected_flag_add_v = ((w_debug_rs1_data[15]==1) & (w_debug_rs2_data[15]==1) & (w_debug_rd_data[15]==0) | (w_debug_rs1_data[15]==0) & (w_debug_rs2_data[15]==0) & (w_debug_rd_data[15]==1));
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_ADD) |=>
        (w_debug_flag_z == $past(expected_flag_add_z)) &&
        (w_debug_flag_n == $past(expected_flag_add_n)) &&
        (w_debug_flag_v == $past(expected_flag_add_v))
    ) else $error("[TIME=%0t] ADD flag error: Z=%b(exp=%b) N=%b(exp=%b) V=%b(exp=%b)",
                  $time, w_debug_flag_z, $past(expected_flag_add_z), w_debug_flag_n, $past(expected_flag_add_n), w_debug_flag_v, $past(expected_flag_add_v));

    // subtraction (SUB)
    wire expected_flag_sub_z = (w_debug_rd_data==0);
    wire expected_flag_sub_n = (w_debug_rd_data[15]);
    wire expected_flag_sub_v = ((w_debug_rs1_data[15]==0) & (w_debug_rs2_data[15]==1) & (w_debug_rd_data[15]==1) | (w_debug_rs1_data[15]==1) & (w_debug_rs2_data[15]==0) & (w_debug_rd_data[15]==0));
    assert property (@(posedge i_clk) disable iff (!i_rst_n)
        (w_debug_instr[3:0] == OP_SUB) |=>
        (w_debug_flag_z == $past(expected_flag_sub_z)) &&
        (w_debug_flag_n == $past(expected_flag_sub_n)) &&
        (w_debug_flag_v == $past(expected_flag_sub_v))
    ) else $error("[TIME=%0t] SUB flag error: Z=%b(exp=%b) N=%b(exp=%b) V=%b(exp=%b)",
                  $time, w_debug_flag_z, $past(expected_flag_sub_z), w_debug_flag_n, $past(expected_flag_sub_n), w_debug_flag_v, $past(expected_flag_sub_v));


    //==========================================================================
    // Information Display
    //==========================================================================
    always @(posedge i_clk) begin
        if (i_rst_n) begin

            if (w_debug_instr[3:0] == OP_ADD) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: ADD R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_SUB) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: SUB R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_AND) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: AND R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_OR) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: OR R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_ADDI) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: ADDI R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_ASI) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: ASI R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_LOADI) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: LOADI R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_LUI) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: LUI R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end

            if (w_debug_instr[3:0] == OP_AUIPC) begin
                if ((w_debug_rd_data == expected_result) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: AUIPC R%0d = 0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data);
            end



            if (w_debug_instr[3:0] == OP_LOAD) begin
                if ((w_debug_adder_to_dmem == expected_mem_addr) && (w_debug_rd_data == w_debug_data_from_dmem) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: LOAD R%0d = MEM[0x%04h] = 0x%04h",
                             $time, w_debug_rd_addr, expected_mem_addr, w_debug_rd_data);
            end
            if (w_debug_instr[3:0] == OP_STORE) begin
                if ((w_debug_adder_to_dmem == expected_mem_addr) && (w_debug_data_to_dmem == expected_store_data) && w_debug_dmem_wen && (w_debug_regfile_wen == 0))
                    $display("[SVA OK] Time=%0t: STORE MEM[0x%04h] = 0x%04h",
                             $time, expected_mem_addr, expected_store_data);
            end


            if (w_debug_instr[3:0] == OP_JAL) begin
                if ((w_debug_rd_data == w_debug_now_pc + PC_INCR) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: JAL link R%0d=0x%04h target=0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data, expected_jump_target);
            end
            if (w_debug_instr[3:0] == OP_JALR) begin
                if ((w_debug_rd_data == w_debug_now_pc + PC_INCR) && w_debug_regfile_wen && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: JALR link R%0d=0x%04h target=0x%04h",
                             $time, w_debug_rd_addr, w_debug_rd_data, expected_jump_target);
            end


            if (w_debug_instr[3:0] == OP_BLT) begin
                if ((w_debug_regfile_wen == 0) && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: BLT cond=%b target=0x%04h notaken_pc=0x%04h",
                             $time, (w_debug_flag_n ^ w_debug_flag_v),
                             expected_branch_target, w_debug_now_pc + PC_INCR);
            end
            if (w_debug_instr[3:0] == OP_BLE) begin
                if ((w_debug_regfile_wen == 0) && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: BLE cond=%b target=0x%04h notaken_pc=0x%04h",
                             $time, (w_debug_flag_n ^ w_debug_flag_v | w_debug_flag_z),
                             expected_branch_target, w_debug_now_pc + PC_INCR);
            end
            if (w_debug_instr[3:0] == OP_BZ) begin
                if ((w_debug_regfile_wen == 0) && (w_debug_dmem_wen == 0))
                    $display("[SVA OK] Time=%0t: BZ cond=%b target=0x%04h notaken_pc=0x%04h",
                             $time, (w_debug_flag_z),
                             expected_branch_target, w_debug_now_pc + PC_INCR);
            end
        end
    end

endmodule

`endif
