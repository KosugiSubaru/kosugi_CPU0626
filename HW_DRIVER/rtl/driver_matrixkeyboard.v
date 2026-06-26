// 4x3 matrix key driver
// The key is driven by dynamic control signals

`define control0 4'b0000 // Control signal for first row
`define control1 4'b0001 // Control signal for second row
`define control2 4'b0010 // Control signal for third row
`define control3 4'b0011
`define control4 4'b0100
`define control5 4'b0101
`define control6 4'b0110
`define control7 4'b0111
`define control8 4'b1000
`define control9 4'b1001 
`define controlNA 4'b1111 // No control signal

module driver_matrixkeyboard (
    input wire        r_clk, r_rst,
    input wire [3:0]  i_signal, // Input signal for the matrix key

    output reg [9:0]  o_control, // Control signals for the matrix key
    output reg [15:0] o_detected_key     // Output key for CPU processing
    );

    wire overflow;                  // Overflow signal for dynamic control
    wire i_clk, i_rst;

    assign i_clk = r_clk;
    assign i_rst = ~r_rst;

    reg [3:0] control_cnt;          // Control counter for dynamic control
    reg [3:0] control_state;        // State of the control signals
    reg [2:0] key_state;            // State of the keys

    reg [39:0] frame;


    reg [39:0] complete_frame;
    reg [15:0] decoded_now;
    

    // 12bit frame -> key code
    function [15:0] decode_frame;
        input [39:0] f;
        begin
            case (f)
                40'h0000000001: decode_frame = 16'h0031;
                40'h0000000002: decode_frame = 16'h0071;
                40'h0000000004: decode_frame = 16'h0061;
                40'h0000000008: decode_frame = 16'h007a;

                40'h0000000010: decode_frame = 16'h0032;
                40'h0000000020: decode_frame = 16'h0077;
                40'h0000000040: decode_frame = 16'h0073;
                40'h0000000080: decode_frame = 16'h0078;

                40'h0000000100: decode_frame = 16'h0033;
                40'h0000000200: decode_frame = 16'h0065;
                40'h0000000400: decode_frame = 16'h0064;
                40'h0000000800: decode_frame = 16'h0063;

                40'h0000001000: decode_frame = 16'h0034;
                40'h0000002000: decode_frame = 16'h0072;
                40'h0000004000: decode_frame = 16'h0066;
                40'h0000008000: decode_frame = 16'h0076;

                40'h0000010000: decode_frame = 16'h0035;
                40'h0000020000: decode_frame = 16'h0074;
                40'h0000040000: decode_frame = 16'h0067;
                40'h0000080000: decode_frame = 16'h0062;

                40'h0000100000: decode_frame = 16'h0036;
                40'h0000200000: decode_frame = 16'h0079;
                40'h0000400000: decode_frame = 16'h0068;
                40'h0000800000: decode_frame = 16'h006e;

                40'h0001000000: decode_frame = 16'h0037;
                40'h0002000000: decode_frame = 16'h0075;
                40'h0004000000: decode_frame = 16'h006a;
                40'h0008000000: decode_frame = 16'h006d;

                40'h0010000000: decode_frame = 16'h0038;
                40'h0020000000: decode_frame = 16'h0069;
                40'h0040000000: decode_frame = 16'h006b;
                40'h0080000000: decode_frame = 16'h0011;

                40'h0100000000: decode_frame = 16'h0039;
                40'h0200000000: decode_frame = 16'h006f;
                40'h0400000000: decode_frame = 16'h006c;
                40'h0800000000: decode_frame = 16'h0012;

                40'h1000000000: decode_frame = 16'h0030;
                40'h2000000000: decode_frame = 16'h0070;
                40'h4000000000: decode_frame = 16'h0013;
                40'h8000000000: decode_frame = 16'h0014;

                default:        decode_frame = 16'h0000;
            endcase
        end
    endfunction

    // Lotation for control signals based on the control counter
    always @(posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            control_cnt <= 4'b0000;               // Reset control counter
        end else if (overflow) begin
            if (control_cnt >= 4'b1001) begin
                control_cnt <= 4'b0000;           // Reset control counter after reaching max
            end else begin
                control_cnt <= control_cnt + 4'b0001; // Increment control counter
            end
        end
    end

    // Set control signals based on control_cnt
    always @(*) begin
        case (control_cnt)
            4'b0000: begin 
                o_control = 10'b1111111110;         // Enable first control signal
                control_state = `control0;  // Set control state for first row
            end
            4'b0001: begin
                o_control = 10'b1111111101;         // Enable second control signal
                control_state = `control1;  // Set control state for second row
            end
            4'b0010: begin
                o_control = 10'b1111111011;         // Enable third control signal
                control_state = `control2;  // Set control state for third row
            end
            4'b0011: begin
                o_control = 10'b1111110111;
                control_state = `control3;
            end
            4'b0100: begin
                o_control = 10'b1111101111;
                control_state = `control4;
            end
            4'b0101: begin
                o_control = 10'b1111011111;
                control_state = `control5;
            end
            4'b0110: begin
                o_control = 10'b1110111111;
                control_state = `control6;
            end
            4'b0111: begin
                o_control = 10'b1101111111;
                control_state = `control7;
            end
            4'b1000: begin
                o_control = 10'b1011111111;
                control_state = `control8;
            end
            4'b1001: begin
                o_control = 10'b0111111111;
                control_state = `control9;
            end
            default: begin
                o_control = 10'b1111111111;         // Default case
                control_state = `controlNA; // Default control state 
            end    
        endcase
    end

    // Set output key based on control state and key state
    always @(posedge i_clk, posedge i_rst) begin
        if (i_rst) begin
            frame <= 40'h0000000000; // Reset frame counter
            o_detected_key <= 16'h0000; // Reset detected key
        end else begin
            case (control_state)
                `control0: begin
                    frame[3:0] <= ~i_signal; // Update frame with stable signal
                end
                `control1: begin
                    frame[7:4] <= ~i_signal; // Update frame with stable signal
                end
                `control2: begin
                    frame[11:8] <= ~i_signal; // Update frame with stable signal
                end
                `control3: begin
                    frame[15:12] <= ~i_signal;
                end
                `control4: begin
                    frame[19:16] <= ~i_signal;
                end
                `control5: begin
                    frame[23:20] <= ~i_signal;
                end
                `control6: begin
                    frame[27:24] <= ~i_signal;
                end
                `control7: begin
                    frame[31:28] <= ~i_signal;
                end
                `control8: begin
                    frame[35:32] <= ~i_signal;
                end
                `control9: begin
                    frame[39:36] <= ~i_signal;
                
                    complete_frame = {~i_signal, frame[35:0]};
                    decoded_now = decode_frame(complete_frame);

                    o_detected_key <= decoded_now; // Update detected key with the decoded value
                end
                default: begin
                    // frame <= 12'h000; // Default case
                end    
            endcase
        end
    end

    // Timer for dynamic control
    timer_matrixkey TIMER (
        .i_clk (i_clk),
        .i_rst (i_rst),
        .overflow (overflow)
    );

endmodule

module timer_matrixkey (
    input  wire i_clk, i_rst,
    output reg  overflow
    );

    reg [31:0] cnt; // Counter for timing

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            cnt <= 32'h00000000; // Reset counter
            overflow <= 1'b0;    // Reset overflow signal
        end else if (cnt == 32'd27) begin
            cnt <= 32'h00000000; // Reset counter after reaching limit
            overflow <= 1'b1;    // Set overflow signal
        end else begin
            cnt <= cnt + 32'h00000001;  // Increment counter
            overflow <= 1'b0;           // Clear overflow signal
        end
    end
endmodule
