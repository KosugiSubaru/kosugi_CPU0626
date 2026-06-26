#!/bin/bash

# 論理合成と回路図可視化スクリプト（全ファイル列挙モード）

set -e  # エラーが発生した場合にスクリプトを終了

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPU_DIR="${SCRIPT_DIR}/.."
cd "${CPU_DIR}"

# 色付きログ出力用
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 使用方法表示
usage() {
    echo "使用方法: $0 [OPTIONS]"
    echo ""
    echo "オプション:"
    echo "  -h, --help       このヘルプを表示"
    exit 0
}

# 引数解析
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                ;;
            *)
                log_error "不明なオプション: $1"
                usage
                ;;
        esac
    done
}

# 必要なツールの確認
check_dependencies() {
    log_info "必要なツールの確認中..."
    
    if ! command -v yosys &> /dev/null; then
        log_error "yosysが見つかりません。インストールしてください: sudo apt install yosys"
        exit 1
    fi
    
    if ! command -v netlistsvg &> /dev/null; then
        log_error "netlistsvgが見つかりません。インストールしてください: npm install -g netlistsvg"
        exit 1
    fi
    
    log_success "必要なツールが全て利用可能です"
}

# ディレクトリ作成
create_directories() {
    local base_dir="$1"
    log_info "${base_dir} 用のディレクトリを作成中..."
    
    mkdir -p "${base_dir}/json"
    mkdir -p "${base_dir}/svg"
    
    log_success "${base_dir} のディレクトリを作成しました"
}

# 論理合成実行（全ファイル列挙モード - include文不要）
synthesize_verilog_all() {
    local rtl_dir_src="$1"
    local json_dir="$2"
    local module_name="$3"
    local base_name="$4"  # モジュールベース名（cpuの場合に特別処理）
    
    log_info "論理合成実行中: ${module_name} (全ファイル列挙モード)"
    
    # rtlディレクトリ内の全.vファイルを収集
    local all_verilog_files=()
    
    # cpuモジュールの場合は、rtl/cpu配下の全.vファイルを収集
    if [[ "$base_name" == "cpu" ]]; then
        log_info "  → CPU統合モード: rtl/cpu/ 配下の全Verilogファイルを収集"
        while IFS= read -r -d '' file; do
            all_verilog_files+=("$file")
        done < <(find "rtl/cpu" -name "*.v" -type f -print0)
    else
        # 通常のモジュールは指定ディレクトリ内のみ
        while IFS= read -r -d '' file; do
            all_verilog_files+=("$file")
        done < <(find "${rtl_dir_src}" -name "*.v" -type f -print0)
    fi
    
    if [[ ${#all_verilog_files[@]} -eq 0 ]]; then
        log_error "${rtl_dir_src} に .v ファイルが見つかりません"
        return 1
    fi
    
    log_info "  → ${#all_verilog_files[@]} 個のVerilogファイルを検出"
    
    # Yosysスクリプト生成
    local yosys_script="${json_dir}/${module_name}.ys"
    cat > "${yosys_script}" << EOF
# Yosys synthesis script for ${module_name}
# All files mode - include directives not required

EOF
    
    # 全ファイルをread_verilogコマンドに追加
    echo "# Reading all Verilog files:" >> "${yosys_script}"
    for vfile in "${all_verilog_files[@]}"; do
        echo "read_verilog ${vfile}" >> "${yosys_script}"
    done
    
    cat >> "${yosys_script}" << EOF

hierarchy -top ${module_name}
proc; opt_clean
techmap
opt_clean
hierarchy -check

# Generate gate count statistics
stat

# Write JSON
write_json ${json_dir}/${module_name}.json

EOF

    # 論理合成実行
    if yosys -s "${yosys_script}" > "${json_dir}/${module_name}_synthesis.log" 2>&1; then
        log_success "論理合成完了: ${module_name}"
        rm "${yosys_script}"  # 成功時はスクリプト削除
        return 0
    else
        log_error "論理合成失敗: ${module_name}"
        cat "${json_dir}/${module_name}_synthesis.log"
        return 1
    fi
}

# SVG生成
generate_svg() {
    local json_file="$1"
    local svg_file="$2"
    local module_name="$3"
    
    log_info "SVG生成中: ${module_name}"
    
    if netlistsvg "${json_file}" -o "${svg_file}" ; then
        log_success "SVG生成完了: ${module_name}"
        return 0
    else
        log_error "SVG生成失敗: ${module_name}"
        return 1
    fi
}

# モジュール名を抽出する関数
extract_module_name() {
    local verilog_file="$1"
    
    # Verilogファイルからmodule行を抽出してモジュール名を取得
    if [[ -f "$verilog_file" ]]; then
        grep -m 1 "^module" "$verilog_file" | awk '{print $2}' | sed 's/[();]//g'
    else
        # ファイルが存在しない場合は、ファイル名から推測
        basename "$verilog_file" .v
    fi
}

# メイン処理
main() {
    log_info "論理合成と回路図可視化スクリプト開始"
    echo ""
    
    # 依存関係チェック
    check_dependencies
    echo ""
    
    local rtl_dir="$1"
    local base_name="$2"
    
    log_info "=== ${base_name} の処理開始 ==="
    
    if [[ ! -d "$rtl_dir" ]]; then
        log_error "${rtl_dir} ディレクトリが見つかりません。"
        exit 1
    fi
    
    # ディレクトリ作成
    create_directories "$rtl_dir"
    
    local json_dir="${rtl_dir}/json"
    local svg_dir="${rtl_dir}/svg"
    local rtl_src_dir="${rtl_dir}/rtl"
    local success_count=0
    local total_count=0
    
    # 全ファイル列挙モード：各.vファイルを個別に処理
    log_info "全ファイル列挙モードで処理します"
    
    # .vファイルをすべて処理
    for verilog_file in "${rtl_src_dir}"/*.v; do
            if [[ -f "$verilog_file" ]]; then
                local filename=$(basename "$verilog_file")
                local module_name=$(extract_module_name "$verilog_file")
                
                # モジュール名が取得できない場合はファイル名を使用
                if [[ -z "$module_name" ]]; then
                    module_name=$(basename "$filename" .v)
                fi
                
                total_count=$((total_count + 1))
                
                log_info "処理中 (${total_count}): ${filename} (モジュール: ${module_name})"
                
                # 全ファイル列挙モードで論理合成（base_nameを渡す）
                if synthesize_verilog_all "$rtl_src_dir" "$json_dir" "$module_name" "$base_name"; then
                    # SVG生成
                    local json_file="${json_dir}/${module_name}.json"
                    local svg_file="${svg_dir}/${module_name}.svg"
                    
                    if generate_svg "$json_file" "$svg_file" "$module_name"; then
                        success_count=$((success_count + 1))
                    fi
                fi
                
                echo ""  # 改行で見やすく
            fi
    done

    log_success "=== ${base_name} 処理完了: ${success_count}/${total_count} 成功 ==="
    echo ""
    
    # 結果サマリー表示
    # log_info "=== 結果サマリー ==="
    # local json_count=$(find "${base_name}/json" -name "*.json" -type f 2>/dev/null | wc -l)
    # local svg_count=$(find "${base_name}/svg" -name "*.svg" -type f 2>/dev/null | wc -l)
    # echo "${base_name}: JSON=${json_count}, SVG=${svg_count}"

    echo ""
    log_info "生成されたファイルの場所:"
    echo "  - ${base_name}/json/  : 論理合成結果 (JSON)"
    echo "  - ${base_name}/svg/   : 回路図 (SVG)"
    echo ""
    log_success "${base_name} の全ての処理が完了しました！"
}

# スクリプト実行
# 引数解析
parse_arguments "$@"

log_info "=== 論理合成対象の自動検出開始 ==="
echo ""

# rtl/cpu配下の各モジュールディレクトリを処理対象とする
TARGET_DIRS=("rtl/cpu")

for target_dir in "${TARGET_DIRS[@]}"; do
    if [[ ! -d "$target_dir" ]]; then
        log_warning "${target_dir} ディレクトリが見つかりません。スキップします。"
        continue
    fi
    
    log_info "${target_dir}/ 以下のモジュールを検索中..."
    
    # サブディレクトリを探索
    for module_dir in "${target_dir}"/*; do
        if [[ -d "$module_dir" ]]; then
            rtl_subdir="${module_dir}/rtl"
            
            # rtlディレクトリが存在し、.vファイルがある場合のみ処理
            if [[ -d "$rtl_subdir" ]] && ls "${rtl_subdir}"/*.v 1> /dev/null 2>&1; then
                module_name=$(basename "$module_dir")
                log_info "  → 検出: ${target_dir}/${module_name}"
                main "$module_dir" "$module_name"
            fi
        fi
    done
    
    echo ""
done

log_success "=== すべての論理合成処理が完了しました ==="