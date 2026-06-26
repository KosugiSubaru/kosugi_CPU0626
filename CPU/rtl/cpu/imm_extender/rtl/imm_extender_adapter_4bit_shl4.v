module imm_extender_adapter_4bit_shl4 (
    input  wire [3:0]  i_imm_part,
    output wire [15:0] o_imm_ext
);


    // assign o_imm_ext = { {8{i_imm_part[3]}}, i_imm_part, 4'b0000 };
    assign o_imm_ext = { 8'b00000000, i_imm_part, 4'b0000 };


endmodule