module fpga_keyboardtop (
    input  wire r_clk,
    input  wire r_rst,

    input  wire [3:0] r_signal, // Input signal for the matrix key
    input  wire [3:0] r_buttons, // Input buttons

    output wire [5:0]  o_embeddedLEDs,
    output wire [11:0] o_LEDs,
    output wire [9:0]  o_control, // Control signals for the matrix key

    output  wire       tmds_clk_n,
    output  wire       tmds_clk_p,
    output  wire [2:0] tmds_d_n,
    output  wire [2:0] tmds_d_p
    // Add other ports as needed
    );

    wire i_rst;
    wire sys_resetp;

    wire [11:0] vram_rd_addr;   // VRAM読み出しアドレス
    wire [7:0]  vram_rd_data;   // VRAMからのデータ

    wire        w_dmem_wen;
    wire [15:0] w_addr_pc, w_addr_alu;
    wire [15:0] w_instr;
    wire [15:0] w_data_alu, w_data_dmem, w_data_key, w_data_inCPU;
    wire [15:0] w_observed_reg_data; // 観測用のレジスタデータ（R7）
    wire [15:0] w_observed_pc_data;  // 観測用のプログラムカウンタデータ（PC）
    
    reg  [11:0]  r_LEDs;         // Output LEDs
    reg  [5:0]   r_embeddedLEDs; // Embedded LEDs
    reg  [15:0]  r_data_inCPU;

    reg         i_clk = 1'b0;   // Internal clock signal for the CPU
    reg  [31:0] r_counter = 32'h00000000;

    assign i_rst = ~r_rst;
    assign sys_resetp = ~sys_resetn;

    assign w_data_inCPU = r_data_inCPU; // Data input to the CPU
    // assign o_embeddedLEDs = r_embeddedLEDs; // Output embedded LEDs
    // assign o_LEDs = r_LEDs; // Output LEDs

    cpu u_cpu (
        .i_clk            (i_clk           ),
        .i_rst_n          (sys_resetn         ),
        .i_instr          (w_instr         ),
        .i_data_from_dmem (w_data_inCPU),

        .o_addr_to_dmem   (w_addr_alu  ),
        .o_data_to_dmem   (w_data_alu  ),
        .o_addr_to_imem   (w_addr_pc  ),
        .o_dmem_wen       (w_dmem_wen      ),
        .o_observed_reg_data(w_observed_reg_data), // 観測用の出力データは未接続
        .o_observed_pc_data(w_observed_pc_data)  // 観測用のプログラムカウンタデータ（PC）
    );

    Gowin_pROM IMEM(
        .dout(w_instr), //output [15:0] dout
        .clk(i_clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(sys_resetp), //input reset
        .ad(w_addr_pc[15:0]) //input [15:0] ad
    );

    // dmem DMEM(
    //     .i_clk        (i_clk         ),
    //     .i_rst        (i_rst         ),
    //     .i_wen        (w_dmem_wen    ),
    //     .i_addr       (w_addr_alu    ),
    //     .i_data       (w_data_alu    ),
    //     .o_data       (w_data_dmem   )
    // );

    Gowin_SP DMEM(
        .dout(w_data_dmem), //output [15:0] dout
        .clk(~i_clk), //input clk
        .oce(1'b1), //input oce
        .ce(1'b1), //input ce
        .reset(sys_resetp), //input reset
        .wre(w_dmem_wen), //input wre
        .ad(w_addr_alu[12:0]), //input [12:0] ad
        .din(w_data_alu) //input [15:0] din
    );

    Gowin_SDPB VRAM(
        .dout(vram_rd_data), //output [7:0] dout
        .clka(~i_clk), //input clka
        .cea(w_dmem_wen), //input cea
        .reseta(sys_resetp), //input reseta
        .clkb(clk_p), //input clkb
        .ceb(1'b1), //input ceb
        .resetb(sys_resetp), //input resetb
        .oce(1'b1), //input oce
        .ada(w_addr_alu[12:0]), //input [12:0] ada
        .din(w_data_alu[7:0]), //input [7:0] din
        .adb(vram_rd_addr) //input [11:0] adb
    );

    driver_matrixkeyboard DRIVER_MATRIXKEYBOARD (
        .r_clk           (r_clk         ), // Use r_clk for the matrix key driver
        .r_rst           (sys_resetn     ), // Use system reset for the matrix key driver),
        .i_signal        (r_signal      ), // Assuming r_signal is used to store key data
        .o_control       (o_control     ), // Assuming w_addr_alu is used to control the key state
        .o_detected_key  (w_data_key    )  // Assuming w_data_alu is used to store key data
    );

    Gowin_rPLL u_pll (
        .clkin(r_clk),
        .clkout(clk_p5),
        .lock(pll_lock)
    );

    Gowin_CLKDIV u_div_5 (
        .clkout(clk_p),
        .hclkin(clk_p5),
        .resetn(pll_lock)
    );

    Reset_Sync u_Reset_Sync (
        .resetn(sys_resetn),
        .ext_reset(r_rst & pll_lock),
        .clk(clk_p)
    );

    svo_hdmi svo_hdmi_inst (
        .clk(clk_p),
        .resetn(sys_resetn),

        // video clocks
        .clk_pixel(clk_p),
        .clk_5x_pixel(clk_p5),
        .locked(pll_lock),

        // output signals
        .tmds_clk_n(tmds_clk_n),
        .tmds_clk_p(tmds_clk_p),
        .tmds_d_n(tmds_d_n),
        .tmds_d_p(tmds_d_p),

        // VRAMインターフェース
        .vram_rd_addr(vram_rd_addr), // VRAM読み出しアドレス
        .vram_rd_data(vram_rd_data)  // VRAMから
    );

    // Embedded LEDs
    // always @(posedge i_clk, posedge sys_resetp) begin
    //     if (sys_resetp) begin
    //         r_embeddedLEDs <= 6'b000000; // Reset embedded LEDs to off state
    //     end else if (w_dmem_wen && (w_addr_alu == 16'h1166)) begin
    //         r_embeddedLEDs <= w_data_alu[5:0]; // Update embedded LEDs with data from ALU
    //     end else begin
    //         r_embeddedLEDs <= o_embeddedLEDs; // Maintain current state of embedded LEDs
    //     end
    // end

    // Output LEDs
    // always @(posedge i_clk, posedge sys_resetp) begin
    //     if (sys_resetp) begin
    //         r_LEDs <= 12'b000000000000; // Reset output LEDs to off state
    //     end else if (w_dmem_wen && (w_addr_alu == 16'h1167)) begin
    //         r_LEDs <= w_data_alu[11:0]; // Update output LEDs with data from ALU
    //     end else begin
    //         r_LEDs <= o_LEDs; // Maintain current state of output LEDs
    //     end
    // end

    assign o_LEDs = w_observed_pc_data[13:2]; // Display the lower 12 bits of the observed program counter data on the output LEDs
    assign o_embeddedLEDs = w_observed_reg_data[5:0]; // Display the lower 6 bits of the observed register data on the embedded LEDs

    // Input Matrix Key, Buttons
    always @(*) begin //ワイルドカードでないとエラー
        if ((w_addr_alu == 16'h1168)) begin
            r_data_inCPU = w_data_key; // Read key data from the matrix key driver
        end else if ((w_addr_alu == 16'h1169)) begin
            r_data_inCPU = {12'h000, ~r_buttons}; // Read button data and store in CPU input
        end else begin
            r_data_inCPU = w_data_dmem; // Maintain the current data from DMEM
        end
    end


    // Clock for CPU
    always @(posedge r_clk) begin
        if (r_counter == 32'd27) begin
            r_counter <= 32'h00000000;
            i_clk <= ~i_clk;
        end else begin
            r_counter <= r_counter + 32'h00000001;
            i_clk <= i_clk;
        end
    end

endmodule

module Reset_Sync (
    input clk,
    input ext_reset,
    output resetn
    );

    reg [3:0] reset_cnt = 0;
    
    always @(posedge clk or negedge ext_reset) begin
        if (~ext_reset)
            reset_cnt <= 4'b0;
        else
            reset_cnt <= reset_cnt + !resetn;
    end
    
    assign resetn = &reset_cnt;

endmodule

