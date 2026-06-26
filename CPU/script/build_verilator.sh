#!/bin/bash

# Verilatorビルドスクリプト
# 使用法: ./build_verilator.sh

# set -e  # エラーが発生したら即座に終了

echo "=========================================="
echo "  Verilator Build Script"
echo "=========================================="

# 作業ディレクトリ
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPU_DIR="${SCRIPT_DIR}/.."
cd "${CPU_DIR}"

# クリーンアップ（以前のビルドを削除）
if [ -d "output/obj_dir" ]; then
    echo "Cleaning previous build..."
    rm -rf output/obj_dir
fi
mkdir -p output/obj_dir

# Verilogファイルのリストを生成
echo "Collecting Verilog/SystemVerilog files..."

# トップレベルファイル
FILES="top_gen.v"

# メモリファイル
FILES="$FILES rtl/memory/imem/imem.v"
FILES="$FILES rtl/memory/dmem/dmem.v"

# SVAファイル
FILES="$FILES sva_cpu_gen.sv"
[ -f fp_verify_gen.sv ] && FILES="$FILES fp_verify_gen.sv"

# rtl/cpu配下の各モジュールのRTLファイル
RECONF_FILES=$(find rtl/cpu -path "*/rtl/*.v" -type f)
FILES="$FILES $RECONF_FILES"

# C++テストベンチ
CPP_FILES="tb_top_gen.cpp"

echo "Found $(echo $FILES | wc -w) Verilog/SystemVerilog files"
echo "Found $(echo $CPP_FILES | wc -w) C++ files"

# Verilatorの実行
echo ""
echo "Running Verilator..."
verilator \
    --cc \
    --exe \
    --build \
    --trace \
    --assert \
    -Wno-fatal \
    --top-module top \
    --Mdir output/obj_dir \
    $FILES \
    $CPP_FILES 2>&1 | tee simulation.log

# Verilatorの終了コードをチェック（警告は無視）
VERILATOR_EXIT=${PIPESTATUS[0]}
if [ $VERILATOR_EXIT -ne 0 ]; then #&& [ $VERILATOR_EXIT -ne 4 ]; then
    echo ""
    echo "=========================================="
    echo "  Build failed!"
    echo "=========================================="
    exit 1
fi

# ビルド成功の確認
if [ -f "output/obj_dir/Vtop" ]; then
    echo ""
    echo "=========================================="
    echo "  Build successful!"
    echo "=========================================="
    echo "Executable: ./output/obj_dir/Vtop"
    echo ""
    
    # シミュレーション実行
    echo "=========================================="
    echo "  Running Simulation..."
    echo "=========================================="
    echo ""
    
    ./output/obj_dir/Vtop 2>&1 | tee -a simulation.log
    
    SIMULATION_RESULT=${PIPESTATUS[0]}
    
    # SVAエラーをログから検出
    if grep -q "%Error:" simulation.log || grep -q "Assertion failed" simulation.log; then
        echo ""
        echo "=========================================="
        echo "  Simulation failed: SVA assertion error detected!"
        echo "=========================================="
        echo ""
        echo "Error details:"
        grep -A 2 "%Error:" simulation.log || grep -A 2 "Assertion failed" simulation.log
        echo ""
        echo "See simulation.log for full details"
        echo "=========================================="
        exit 1
    fi
    
    echo ""
    if [ $SIMULATION_RESULT -eq 0 ]; then
        echo "=========================================="
        echo "  Simulation completed successfully!"
        echo "=========================================="
        echo ""
        echo "Output files:"
        echo "  - Waveform: tb_top_gen.vcd"
        echo "  - Log: simulation.log"
        echo ""
        echo "To view waveform:"
        echo "  gtkwave tb_top_gen.vcd"
        echo "=========================================="
    else
        echo "=========================================="
        echo "  Simulation failed with exit code: $SIMULATION_RESULT"
        echo "=========================================="
        exit 1
    fi
else
    echo ""
    echo "=========================================="
    echo "  Build failed!"
    echo "=========================================="
    exit 1
fi
