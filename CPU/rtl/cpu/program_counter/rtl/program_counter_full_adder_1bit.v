module program_counter_full_adder_1bit (
    input  wire i_a,
    input  wire i_b,
    input  wire i_cin,
    output wire o_sum,
    output wire o_cout
);

    assign o_sum  = i_a ^ i_b ^ i_cin;
    assign o_cout = (i_a & i_b) | (i_b & i_cin) | (i_cin & i_a);

endmodule