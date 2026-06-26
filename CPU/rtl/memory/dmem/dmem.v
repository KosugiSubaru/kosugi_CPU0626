// データメモリ
// 32768 x 16bitのメモリ
// 同期読み出し、同期書き込み（シングルサイクルCPUに対応するため、i_clkを反転させて使用）

module dmem (
    input  wire        i_clk,
    input  wire        i_rst_n,
    input  wire [15:0] i_addr,
    input  wire        i_wen,
    input  wire [15:0] i_data,
    output wire [15:0] o_data
    );
    
    //データメモリ本体
    // 256 x 16bitのメモリ
    reg [15:0] datamem [5000:0];//[32767:0];
    reg [15:0] o;

    // バイトアドレッシング対応
    // wire [15:0] addr;
    // assign addr = {1'b0, i_addr[15:1]}; // 下位1ビットを無視してアドレスを取得

    wire [12:0] addr_extract;
    assign addr_extract = i_addr[12:0]; // 下位13ビット
    
    //非同期読み出し
    // assign o_data = datamem[addr_extract];

    // 同期読み出し
    // シングルサイクルCPUに対応するため、i_clkを反転させて使用
    assign o_data = o;
    always @(posedge ~i_clk) begin
        if (!i_wen) begin
            o <= datamem[addr_extract];
        end
    end

    //データの初期化
    initial begin
        
        $readmemh("rtl/memory/dmem/datamem.dat", datamem);

        $monitor("dmem[0]:%h, dmem[1]:%h, dmem[2405]:%h, dmem[2406]:%h, dmem[2407]:%h, dmem[2408]:%h, dmem[2409]:%h, dmem[2410]:%h, dmem[2411]:%h, dmem[2412]:%h, dmem[2413]:%h, dmem[2414]:%h, dmem[2415]:%h, dmem[2416]:%h, dmem[2417]:%h",
				 datamem[0], datamem[1], datamem[2405], datamem[2406], datamem[2407], datamem[2408], datamem[2409], datamem[2410], datamem[2411], datamem[2412], datamem[2413], datamem[2414], datamem[2415], datamem[2416], datamem[2417]);
    end

    //リセット処理(シミュレーションでは初期化ファイルで対応するため、リセット処理はコメントアウト)
    // integer i;
    // always @(posedge ~i_clk) begin
    //     if (!i_rst_n) begin
    //         for (i = 0; i < 256; i = i + 1) begin
    //             datamem[i] <= 8'h00; // リセット時に全てのメモリを0に初期化
    //         end
    //     end
    // end

    //書き込み
    always @(posedge ~i_clk) begin
        if (i_wen) begin
            datamem[addr_extract] <= i_data;
        end
    end

    
endmodule