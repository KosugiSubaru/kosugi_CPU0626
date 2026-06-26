
def trim_to_mi(dat, mem_depth, bit_width) -> None:
    """
    .dat形式のバイナリコードを.mi形式に変換し、保存する
    """
    # datの中のバイナリコードから@xx（番地）を削除して、命令コードのみを抽出する
    mi_lines = []
    for line in dat.splitlines():
        if line.startswith("@"):
            parts = line.split()
            if len(parts) == 2:
                mi_lines.append(parts[1])  # 命令コードのみを追加
    # メモリの深さとビット幅に合わせて、ファイル先頭に
    #File_format=Bin
    #Address_depth=2048
    #Data_width=8
    #を追加する
    header = f"#File_format=Bin\n#Address_depth={mem_depth}\n#Data_width={bit_width}\n"
    mi_content = header + "\n".join(mi_lines)
    # .miファイルとして保存する
    with open("program.mi", "w") as f:
        f.write(mi_content)
    
    print(f".miファイルを保存しました。")

def main():
    # コマンドライン引数で.datファイルを読み込む
    import sys
    if len(sys.argv) != 2:
        print("Usage: python generated_mi.py <input.dat>")
        return
    
    dat_file = sys.argv[1]
    with open(dat_file, "r") as f:
        dat_content = f.read()
    # メモリの深さとビット幅を指定して、.mi形式に変換して保存する
    mem_depth = 16384  # 例: 16384ワード
    bit_width = 16     # 例: 16ビット幅
    trim_to_mi(dat_content, mem_depth, bit_width)

if __name__ == "__main__":
    main()