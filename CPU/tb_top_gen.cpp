#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop.h"

// シミュレーション時間
vluint64_t main_time = 0;

// Verilatorのタイムスタンプ関数
double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {
    // コマンドライン引数の処理
    Verilated::commandArgs(argc, argv);
    
    // トップモジュールのインスタンス化
    Vtop* top = new Vtop;
    
    // VCDトレースの設定
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);  // トレース深度
    tfp->open("tb_top_gen.vcd");
    
    // 初期化
    top->i_clk = 0;
    top->i_rst_n = 0;
    
    // リセット期間（15ns相当 = 3サイクル）
    for (int i = 0; i < 3; i++) {
        // クロック立ち下がり
        top->i_clk = 0;
        top->eval();           // 組み合わせ回路の評価
        tfp->dump(main_time);  // 波形記録
        main_time += 5;
        
        // クロック立ち上がり
        top->i_clk = 1;
        top->eval();           // レジスタ更新
        tfp->dump(main_time);  // 波形記録
        main_time += 5;
    }
    
    // リセット解除
    top->i_rst_n = 1;
    
    // メインシミュレーションループ（500000ns = 50000サイクル）
    while (main_time < 200000 && !Verilated::gotFinish()) {
        // クロック立ち下がり
        top->i_clk = 0;
        top->eval();           // 組み合わせ回路の評価
        tfp->dump(main_time);  // 波形記録
        main_time += 5;
        
        // クロック立ち上がり
        top->i_clk = 1;
        top->eval();           // レジスタ更新
        tfp->dump(main_time);  // 波形記録
        main_time += 5;
        
        // 100サイクルごとに進捗表示
        if ((main_time / 10) % 100 == 0) {
            printf("Time: %lld ns (cycle %lld)\n", (long long)main_time, (long long)(main_time / 10));
        }
    }
    
    // 終了処理
    top->final();    // Verilog $finish相当の処理
    tfp->close();    // VCDファイルクローズ
    delete top;      // メモリ解放
    delete tfp;
    
    printf("\n========================================\n");
    printf("  Simulation completed at %lld ns\n", (long long)main_time);
    printf("========================================\n");
    
    return 0;
}
