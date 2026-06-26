#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

compile() {
    input="$1"

    compiler/src/compiler "$input" > compiler/asm/result.s
    if [ $? -ne 0 ]; then
        echo "compile error"
        exit 1
    fi
}

assemble() {
    input="$1"

    python3 assembler/generated_test_useforkey.py "$input" > compiler/bin/result.dat
    python3 assembler/generated_mi.py compiler/bin/result.dat
    if [ $? -ne 0 ]; then
        echo "assemble error"
        exit 1
    fi
#   spim -file "$input" > result.txt
#   if [ $? -ne 0 ]; then
#     echo "assemble error"
#     exit 1
#   fi
}

compile "programs/myothello.c"
assemble "compiler/asm/result.s"

cp compiler/bin/result.dat ../CPU/rtl/memory/imem/machine_code_bin.dat
echo "Compilation and assembly successful. Machine code written to compiler/bin/result.dat"
