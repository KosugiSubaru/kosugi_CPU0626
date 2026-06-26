module program_counter_reg_1bit (
    input  wire i_clk,
    input  wire i_rst_n,
    input  wire i_d,
    output reg  o_q
);

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_q <= 1'b0;
        end else begin
            o_q <= i_d;
        end
    end

endmodule