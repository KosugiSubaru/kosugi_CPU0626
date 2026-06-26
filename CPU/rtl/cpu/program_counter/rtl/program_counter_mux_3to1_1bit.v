module program_counter_mux_3to1_1bit (
    input  wire [1:0] i_sel,
    input  wire       i_data0,
    input  wire       i_data1,
    input  wire       i_data2,
    output wire       o_data
);

    assign o_data = (i_sel == 2'b00) ? i_data0 :
                    (i_sel == 2'b01) ? i_data1 :
                    (i_sel == 2'b10) ? i_data2 : 1'b0;

endmodule