`timescale 1ns / 1ps

module svo_text_console #(
    parameter SVO_BITS_PER_PIXEL = 24
)(
    input  wire                           clk,
    input  wire                           resetn,

    // AXI4-Stream Video Interface
    output wire                           out_axis_tvalid,
    input  wire                           out_axis_tready,
    output reg  [SVO_BITS_PER_PIXEL-1:0] out_axis_tdata,
    output reg  [0:0]                     out_axis_tuser,  // [0] = SOF (Start of Frame)

    output wire [11:0]                   vram_rd_addr,   // VRAM読み出しアドレス (行列座標に基づく)
    input  wire [7:0]                    vram_rd_data    // VRAMから
);

    // VGA 640x480 描画領域定数
    localparam [9:0] H_ACTIVE = 10'd640;
    localparam [9:0] V_ACTIVE = 10'd480;

    // 内部座標カウンタ (現在のレイテンシなしのターゲット座標)
    reg [9:0] h_cnt;
    reg [9:0] v_cnt;
    
    // ハンドシェイク有効信号
    wire step = out_axis_tvalid && out_axis_tready;

    // 1. 2次元座標カウンタ生成
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end else if (step) begin
            if (h_cnt == H_ACTIVE - 1'b1) begin
                h_cnt <= 10'd0;
                if (v_cnt == V_ACTIVE - 1'b1)
                    v_cnt <= 10'd0;
                else
                    v_cnt <= v_cnt + 1'b1;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    // 2. テキスト・レンダリング構造の定義 (8x16ピクセルフォント)
    // 640/8 = 80列, 480/16 = 30行
    wire [6:0] char_col = h_cnt[9:3];
    wire [4:0] char_row = v_cnt[9:4];
    wire [3:0] font_row = v_cnt[3:0];
    wire [2:0] font_col = h_cnt[2:0];

    // 疑似VRAM: 画面位置に応じたテストパターン（文字コード）の確定
    // reg [6:0] vram_char_code;
    // always @(*) begin
    //     // デバッグ用表示: 画面全体に文字を巡回パターンで配置
    //     vram_char_code = 7'h41 + (char_row + char_col) % 7'd26; // 'A' - 'Z'
    // end

    // VRAMから文字コードを読み出すためのアドレス生成
    assign vram_rd_addr = char_row * 8'd80 + char_col; // 1行80文字

    // Font ROMの定義 (128文字 × 16ライン = 2048エントリー)
    reg [7:0] font_rom [0:2047];
    reg [7:0] font_data_line;

    // 初期データの設定方法の指定
    // 注: 本モジュールと同一ディレクトリに "font_data.hex" を配置する必要があります。
    initial begin
        $readmemh("font_data.hex", font_rom);
    end

    // 同期読み出し（Block RAMへの推論を促す構成）
    always @(posedge clk) begin
        if (step) begin
            font_data_line <= font_rom[{vram_rd_data[6:0], font_row}];
        end
    end

    // タイミング調整用のディレイパイプライン (2クロック分遅延)
    reg [2:0] font_col_d1, font_col_d2;
    reg [1:0] sof_pipe;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            font_col_d1 <= 3'd0; 
            font_col_d2 <= 3'd0; 
            sof_pipe <= 2'b0;
        end else if (step) begin
            font_col_d1 <= font_col;
            font_col_d2 <= font_col_d1;
            sof_pipe    <= {sof_pipe[0], (h_cnt == 10'd0 && v_cnt == 10'd0)};
        end
    end

    // 最終ピクセル出力
    assign out_axis_tvalid = resetn;
    wire pixel_bit = font_data_line[3'd7 - font_col_d2];

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            out_axis_tdata <= {SVO_BITS_PER_PIXEL{1'b0}};
            out_axis_tuser <= 1'b0;
        end else if (out_axis_tready) begin
            out_axis_tdata <= pixel_bit ? {SVO_BITS_PER_PIXEL{1'b1}} : {SVO_BITS_PER_PIXEL{1'b0}};
            out_axis_tuser[0] <= sof_pipe[1];
        end
    end

endmodule