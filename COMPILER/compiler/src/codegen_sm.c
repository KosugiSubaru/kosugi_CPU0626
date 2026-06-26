#include "header.h"

//抽象構文木を再帰的に読み込み，アセンブリコード生成する

// r8:グローバル変数のベースアドレス
// r7:スタックポインタ
// r6:戻り番地のレジスタ
// r5:ベースポインタ

// caseブロックごとにレジスタの使用は独立している
// caseブロックをまたいだレジスタの生存は考えなくてよい

int label_num = 0;
# define MAX_IMM 7
# define MAX_IMM_LONG 127

void gen_val(Node *node) {
    if (node->kind == ND_DEREF){
        gen(node->lhs);
        return;
    }
    // if (node->kind != ND_LVAR ) {
    //     error("Compile error: The left-hand side value of the assignment is not a variable. Type: %d", node->kind);
    // }
    if (node->kind == ND_LVAR) {
        printf(" # 変数のアドレスを取得し，スタックにプッシュする\n");
        printf("  add r1, r0, r5\n");
    }
    else if (node->kind == ND_GVAR) {
        printf(" # グローバル変数のアドレスを取得し，スタックにプッシュする\n");
        printf("  add r1, r0, r8\n");
    }
    if (node->offset <= MAX_IMM && node->offset >= 0) {
        // fprintf(stderr, "offset: %d\n", node->offset);
        printf("  addi r1, r1, 0x%x\n", node->offset);
    } else {
        use_lui(node->offset, 14);
        printf("  add r1, r1, r14\n");
    }
    printf("  addi r7, r7, 0x1\n");
    printf("  store 0x0, r7, r1\n\n");
}

void use_lui(int val, int reg) {
    //15~8ビット→lui, 7~4ビット→asi, 3~0ビット→addiでロードする
    int upper = (val >> 8) & 0xFF;   //15~8ビット
    int middle = (val >> 4) & 0xF;   //7~4ビット
    int lower = val & 0xF;           //3~0ビット

    printf("  lui r%d, 0x%x\n", reg, upper);
    printf("  asi r%d, r%d, 0x%x\n", reg, reg, middle);
    // printf("  addi r%d, r%d, 0x%x\n", reg, reg, lower);
        if (lower <= MAX_IMM && lower >= 0) {
            printf("  addi r%d, r%d, 0x%x\n", reg, reg, lower);
        }
        else {
            printf("  addi r%d, r%d, 0x%x\n", reg, reg, MAX_IMM);
            for (int i = 0; i < lower - MAX_IMM; i++) {
                printf("  addi r%d, r%d, 0x1\n", reg, reg);
            }
        }
}

void gen(Node *node) {
    if (!node) {
        return;
    }
    label_num++;
    int id = label_num; //再帰から戻ってきた時に，ラベルを分けるためのid
    int arg_count = 0;

    switch (node->kind) {
        //修正済み
        case ND_FUNCCALL:
            printf(" # 関数呼び出し\n");
            printf("  # 引数の計算\n");

            printf("  # r6の値をスタックに退避\n");
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r6\n");

        //最終引数から順にスタックにプッシュ
            for (int i = node->len_args; i > 0; i--) {
                gen(node->vec_funcarg[i-1]);
            }
            printf(" # 呼び出し先(%s)へジャンプ\n", node->funcname);
            printf("  jal r6, L_%s\n", node->funcname);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            // printf("  sub x0, x0 x0\n");
            // printf("  bz L_%s\n", node->funcname);
            printf("  # ---ここが戻り番地---#\n");
            //引数の数だけスタックポインタをデクリメント
            for (int i = 0; i < node->len_args; i++) {
                printf("  addi r7, r7, -1\n");
            }
            printf("  # r6の値をスタックから復帰\n");
            printf("  load r6, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");

            printf("  # 関数の戻り値をスタックにプッシュする（戻り値はx1に入っている）\n");
            printf("  addi r7, r7, 0x1\n");
            // printf("  store x1, x7, 0x0\n\n");                //関数の返り値はスタックにプッシュしないといけない
            printf("  store 0x0, r7, r1\n\n");
            return;
        //

    // 修正済み
        case ND_FUNCDEF:
            printf(" # ---ここから関数%sの定義---#\n", node->funcname);
            printf("L_%s:\n", node->funcname);
            //ローカル変数の領域計算
            //   lvar_list_table *now_locals_list = find_lvar_list_table(node);
            Function_table *now_func = find_function(node);
            int size = now_func->lvar_list_size;
            //プロローグ
            printf("  # 関数フレームのプロローグ/変数用領域確保\n");
            printf("  addi r7, r7, 0x1\n");
            // printf("  store r5, r7 0x0\n");                 //ベースポインタのpush
            printf("  store 0x0, r7, r5\n");                 //ベースポインタのpush
            printf("  add r5, r0, r7\n");
            //ローカル変数の領域確保
            if (size <= MAX_IMM && size >= 0) {
                printf("  addi r7, r7, 0x%x\n", size);
            } else {
                use_lui(size, 14);
                printf("  add r7, r7, r14\n");
                // error("Compile error: Too many local variables. The maximum number of local variables is 7.");
            }
            // printf("  addi r7, r7, 0x%x\n\n", size);

            gen(node->lhs);
            //returnにより，x1に戻り値が残っている
            //以下，returnがなかった場合のエピローグ
            printf("  add r7, r0, r5\n");
            printf("  load r5, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");                    //この時点でスタックトップは戻り番地
            //ここから疑似ret命令
            printf("  jalr r0, r6, 0x0\n");
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("  # ---ここまで関数%sの定義---#\n\n", node->funcname);
            return;
        //

        //修正済み
        case ND_BLOCK:
            for (int i = 0; node->vec_block[i]; i++) {
                gen(node->vec_block[i]);
                printf(" # ブロック{...}の中の文が終わるごとにスタックトップをポップ\n");
                printf("  addi r7, r7, -1\n\n");
            }
            return;
        //

        // 修正済み
        case ND_IF:
            printf(" # ここからif文の処理\n");
            printf("  # if文の条件式の計算\n");
            gen(node->lhs);
            printf("  # if文の条件式の結果をr1にポップする\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # if文の条件式の評価\n");
            printf("  sub r0, r1, r0\n");
            printf("  bz Lelse_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            //成り立っている場合
            if (node->rhs->kind == ND_ELSE) {
                printf("  # if文の中身の文の処理/ if(A) B else C のBの処理\n");
                gen(node->rhs->lhs);
                if (node->rhs->lhs->kind != ND_BLOCK) {
                    printf("  addi r7, r7, -1\n");            //if文の中身が1つの式の場合，スタックポインタをデクリメントする
                }                              
            } else {
                printf("  # if文の中身の文の処理/ if(A) B のBの処理\n");
                gen(node->rhs);
                if (node->rhs->kind != ND_BLOCK) {
                    printf("  addi r7, r7, -1\n");            //if文の中身が1つの式の場合，スタックポインタをデクリメントする
                }                             
            }
            printf("  sub r0, r0, r0\n");
            printf("  bz Lend_%x\n", id);
            // printf("  jal r0, Lend_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("Lelse_%x:\n", id);
            if (node->rhs->kind == ND_ELSE) {
                printf("  # else文の中身の文の処理/ if(A) B else C のCの処理\n");
                gen(node->rhs->rhs);
                if (node->rhs->rhs->kind != ND_BLOCK) {
                    printf("  addi r7, r7, -1\n");            //else文の中身が1つの式の場合，スタックポインタをデクリメントする
                }                              
            }
            printf("Lend_%x:\n", id);
            printf("  addi r7, r7, 0x1\n"); //謎
            printf(" # ここまでif文の処理\n\n");
            return;
        //

        //修正済み
        case ND_RETURN:                               //(裏ワザ：全ての計算結果はx1に残っているから，returnを書かなくてもretunrできる．
            printf(" # ここからreturnの処理\n");          //ただし，returnの後に文がある場合は不可)
            gen(node->lhs);
            printf("  # returnしたい値をr1にロード\n");
            printf("  load r1, r7, 0x0\n");
            
            //エピローグ
            printf("  add r7, r0, r5\n");
            printf("  load r5, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");                //この時点でスタックトップは戻り番地
            //ここから疑似ret命令
            printf("  jalr r0, r6, 0x0\n");
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("  # ---returnにより関数終了---#\n\n");
            return;
        //

        // 修正済み
        case ND_WHILE:
            printf(" # ここからwhile文の処理\n");
            printf("LWHILE_%x:\n", id);
            printf("  # while文の条件式の計算\n");
            gen(node->lhs);
            printf("  # while文の条件式の結果をr1にポップする\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # while文の条件分岐\n");
            printf("  sub r0, r1, r0\n");
            printf("  bz LWHILE_END_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("  # while文の中身の文の計算\n");
            gen(node->rhs);
            if (node->rhs->kind != ND_BLOCK) {
                printf("  addi r7, r7, -1\n");              //while文の中身が1つの式の場合，スタックポインタをデクリメントする
            }
            printf("  sub r0, r0, r0\n");
            printf("  bz LWHILE_%x\n", id);
            // printf("  jal r0, LWHILE_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("LWHILE_END_%x:\n", id);
            printf("  addi r7, r7, 0x1\n");              //スタックポインタインクリメントがないと，gen関数が終了した後にスタックポインタがずれる
            printf("  # ここまでwhile文の処理\n\n");
            return;
        //

        // 修正済み
        case ND_FOR:
            printf(" # ここからfor文の処理\n");
            printf("  # for文の初期化式の計算\n");
            gen(node->lhs->lhs);
            if (node->lhs->lhs != NULL) {
                printf("  addi r7, r7, -1\n");              //初期化式の結果がスタックトップに残っているので，スタックポインタをデクリメントする
            }
            printf("LFOR_%x:\n", id);
            printf("  # for文の条件式の計算\n");
            gen(node->lhs->rhs);
            if (!node->lhs->rhs) {
                //条件式がない場合は常に真なので，スタックに1をプッシュする
                printf("  addi r7, r7, 0x1\n");
                printf("  addi r1, r0, 0x1\n");
                printf("  store 0x0, r7, r1\n");
            }
            printf("  # for文の条件式の結果をr1にポップする\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # for文の条件式の評価\n");
            printf("  sub r0, r1, r0\n");
            printf("  bz LFOR_END_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("  # for文の中身の文の計算/ for(A;B;C)D のDの計算\n");
            gen(node->rhs->rhs);
            if (node ->rhs->rhs->kind != ND_BLOCK) { 
                printf("  addi r7, r7, -1\n");              //for文の中身が1つの式の場合，スタックポインタをデクリメントする
            }         
            printf("  # for文の文の計算/ for(A;B;C)D のCの計算\n");                     
            gen(node->rhs->lhs);
            if (node->rhs->lhs != NULL) {
                printf("  addi r7, r7, -1\n");              //更新式の結果がスタックトップに残っているので，スタックポインタをデクリメントする
            }
            printf("  sub r0, r0, r0\n");
            printf("  bz LFOR_%x\n", id);
            // printf("  jal r0, LFOR_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("LFOR_END_%x:\n", id);
            printf("  addi r7, r7, 0x1\n");              //スタックポインタインクリメントがないと，gen関数が終了した後にスタックポインタがずれる
            printf("  # ここまでfor\n\n");
            return;
        //

        // 修正済み
        case ND_NUM:
            printf(" # スタックトップに0x%xをプッシュする\n", node->val);
            if (node->val <= 127 && node->val >= -128) {
                printf("  loadi r1, %d\n", node->val);
            }
            else {
                use_lui(node->val, 1);
                // error("Compile error: Out of imm range (-128 to 127).");
                // exit(1);
            }
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r1\n\n");
            return;
        //

        case ND_LVAR:
            gen_val(node);
            if (node->type && node->type->ty == ARRAY) { //配列の場合
                // fprintf(stderr, "Generating code for array variable: %s\n", node->lvar_name);
                return; //配列のアドレスがスタックにプッシュされている状態で十分
            }
            // fprintf(stderr, "Generating code for local variable: %s\n", node->lvar_name);
            // fprintf(stderr, "Variable type: %d\n", node->type->ty);
            printf(" # 変数の値をロードしてスタックにプッシュする\n");
            printf("  # スタックトップにある変数のアドレスをポップする\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # アドレスから，変数の値をロードしてスタックにプッシュする\n");
            printf("  load r1, r1, 0x0\n");
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r1\n\n");
            return;

        case ND_GVAR:
            gen_val(node);
            if (node->type && node->type->ty == ARRAY) { //配列の場合
                // fprintf(stderr, "Generating code for array variable: %s\n", node->gvar_name);
                return; //配列のアドレスがスタックにプッシュされている状態で十分
            }
            // fprintf(stderr, "Generating code for global variable: %s\n", node->gvar_name);
            // fprintf(stderr, "Variable type: %d\n", node->type->ty);
            printf(" # グローバル変数の値をロードしてスタックにプッシュする\n");
            printf("  # スタックトップにあるグローバル変数のアドレスをポップする\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # アドレスから，グローバル変数の値をロードしてスタックにプッシュする\n");
            printf("  load r1, r1, 0x0\n");
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r1\n\n");
            return;

        case ND_ARG:
            printf("  add r1, r0, r5\n");
            if (node->offset <= MAX_IMM_LONG && node->offset >= 0) {
                // printf("  addi r2, r0, 0x%x\n", node->offset);
                printf("  loadi r2, 0x%x\n", node->offset);
            }
            else {
                use_lui(node->offset, 2);
                // error("Compile error: Out of argument offset range (0 to 7).");
            }
            printf("  sub r1, r1, r2\n");
            printf("  load r1, r1, 0x0\n");
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r1\n\n");
            return;

        case ND_ASSIGN:
            gen_val(node->lhs);
            gen(node->rhs);
            printf(" # 左辺への代入\n");
            printf("  # 右辺の値をr1にロードする(pop)\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # 左辺のアドレスをr2にロードする(pop)\n");
            printf("  load r2, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # 左辺のアドレスの変数に右辺の値をストアし，スタックにプッシュ\n");
            printf("  store 0x0, r2, r1\n");
            printf("  addi r7, r7, 0x1\n\n");
            // printf("  store 0x0, r7, r1\n\n"); //必要ないので無効
            return;

        case ND_ADDR:
            gen_val(node->lhs);
            return;

        case ND_DEREF:
            gen(node->lhs);
            printf(" # ポインタの値をロードしてスタックにプッシュする\n");
            printf("  # スタックトップにあるポインタのアドレスをポップする\n");
            printf("  load r1, r7, 0x0\n");
            printf("  addi r7, r7, -1\n");
            printf("  # ポインタの値をロードしてスタックにプッシュする\n");
            printf("  load r1, r1, 0x0\n");
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r1\n\n");
            return;


        case ND_STR:
            printf(" # 文字列リテラルのアドレスをスタックにプッシュする\n");
            printf("  add r1, r0, r8\n");
            if (node->offset <= MAX_IMM && node->offset >= 0) {
                printf("  addi r1, r1, 0x%x\n", node->offset);
            } else {
                use_lui(node->offset, 14);
                printf("  add r1, r1, r14\n");
                // error("Compile error: Out of string literal offset range (0 to 127).");
            }
            printf("  addi r7, r7, 0x1\n");
            printf("  store 0x0, r7, r1\n\n");
            return;
        
        case ND_NULL: // 演算のコード生成はこのswitchをすり抜けるので、defaultはダメ
            // スタックポインタをインクリメント
            printf("  addi r7, r7, 0x1\n");
            return;
        }
        

    gen(node->lhs);
    gen(node->rhs);

    printf(" # スタックトップから2つの値をポップしてr1, r2にロードする\n");
    //pop r1
    printf("  load r1, r7, 0x0\n");
    printf("  addi r7, r7, -1\n");
    //pop r2
    printf("  load r2, r7, 0x0\n");
    printf("  addi r7, r7, -1\n\n");

    switch (node->kind) {
        case ND_ADD:
            printf("  add r1, r2, r1\n\n");
            break;

        case ND_SUB:
            printf("  sub r1, r2, r1\n\n");
            break;

        case ND_MUL:
            printf(" # 乗算（加算の繰り返し）\n");// shiftあればそっちでもいいかも
            printf("  addi r3, r0, 0x0\n");  //r3を0にする
            printf("  addi r4, r0, 0x0\n");  //r4を0にする
            printf("  sub r0, r1, r0\n");
            printf("  bz LMULEND_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            // printf("  sub r1, r1, r6\n");    //r1をデクリメントする
            printf("LMULLOOP_%x:\n", id);   //ループのラベル
            printf("  add r4, r4, r2\n");    //r4にr2を加算
            printf("  addi r3, r3, 0x1\n");  //r3をインクリメント
            printf("  sub r0, r3, r1\n");    //r3とr1を比較して，r1が0になるまでループ
            printf("  blt LMULLOOP_%x\n", id); 
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("LMULEND_%x:\n", id);    
            printf("  add r1, r0, r4\n\n");    //r1にr4を加算（戻り値）
        break;
        //ここまで修正済み

        case ND_DIV:
        //bleがないときついかも
            printf(" # 除算（減算の繰り返し）\n");
            printf("  addi r3, r0, 0x0\n");
            printf("  sub r0, r2, r1\n");
            printf("  blt LDIVEND_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            // printf("  sub r0, r0, r0\n");
            // printf("  bz LDIVEND_%x\n", id);
            printf("LDIVLOOP_%x:\n", id);
            printf("  sub r2, r2, r1\n");
            printf("  addi r3, r3, 0x1\n");
            printf("  sub r0, r1, r2\n");
            printf("  ble LDIVLOOP_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("LDIVEND_%x:\n", id);
            // printf("  addi, r3, r3, 0x1\n");// この時点で、r3=商-1なので、r3に1を加算する
            printf("  add r1, r0, r3\n\n");//余りはr2に入っている
            break;

        case ND_REM:
            printf(" # 剰余（減算の繰り返し）\n");
            printf("  addi r3, r0, 0x0\n");
            printf("  sub r0, r2, r1\n");
            printf("  blt LREMEND_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            // printf("  sub r0, r0, r0\n");
            // printf("  bz LDIVEND_%x\n", id);
            printf("LREMLOOP_%x:\n", id);
            printf("  sub r2, r2, r1\n");
            printf("  addi r3, r3, 0x1\n");
            printf("  sub r0, r1, r2\n");
            printf("  ble LREMLOOP_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("LREMEND_%x:\n", id);
            // printf("  addi, r3, r3, 0x1\n");// この時点で、r3=商-1なので、r3に1を加算する
            printf("  add r1, r0, r2\n\n");//余りはr2に入っている
            break;

        case ND_EQ:
            printf(" # 条件式 == の処理\n");
            printf("  addi r3, r0, 0x1\n");
            printf("  sub r0, r2, r1\n");
            printf("  bz LEQ_%x\n", id);
            printf("  addi r0, r0, 0x0\n"); //分岐、ジャンプ命令との後にnopを入れる
            printf("  addi r3, r0, 0x0\n");
            printf("LEQ_%x:\n", id);
            printf("  add r1, r0, r3\n\n");
            break;

        case ND_NE:
            printf(" # 条件式 != の処理\n");
            printf("  addi r3, r0, 0x0\n");
            printf("  sub r0, r2, r1\n");
            printf("  bz LNE_%x\n", id);
            printf("  addi r0, r0, 0x0\n"); //分岐、ジャンプ命令との後にnopを入れる
            printf("  addi r3, r0, 0x1\n");
            printf("LNE_%x:\n", id);
            printf("  add r1, r0, r3\n\n");
            break;

        case ND_LT:
            printf(" # 条件式 < の処理\n");
            printf("  addi r3, r0, 0x1\n");
            printf("  sub r0, r2, r1\n");
            printf("  blt LLT_%x\n", id);
            printf("  addi r0, r0, 0x0\n"); //分岐、ジャンプ命令との後にnopを入れる
            printf("  addi r3, r0, 0x0\n");
            printf("LLT_%x:\n", id);
            printf("  add r1, r0, r3\n\n");
            break;

        case ND_LE:
            printf(" # 条件式 <= の処理\n");
            printf("  addi r3, r0, 0x1\n");
            printf("  sub r0, r2, r1\n");
            printf("  ble LLE_%x\n", id);
            printf("  addi r0, r0, 0x0\n");                    //分岐、ジャンプ命令との後にnopを入れる
            printf("  addi r3, r0, 0x0\n");
            printf("LLE_%x:\n", id);
            printf("  add r1, r0, r3\n\n");
            break;

        case ND_LOGICAL_AND:
            printf(" # 論理演算 && の処理\n");
            printf("  and r1, r1, r2\n\n");
            break;

        case ND_LOGICAL_OR:
            printf(" # 論理演算 || の処理\n");
            printf("  or r1, r1, r2\n\n");
            break;
        
        default:
            return;
    }
  
    printf(" # スタックトップに演算or条件式の結果(r1)をプッシュする\n");
    printf("  addi r7, r7, 0x1\n");
    printf("  store 0x0, r7, r1\n\n");
}

void init() {
    printf("# CPU初期化関数の定義\n");
    printf(" # スタックポインタを初期化\n");
    // printf("  loadi r7, 100\n"); //スタックポインタを初期化（スタックは下に伸びる）
    printf("   lui r7, 0xd\n");
    printf("   asi r7, r7, 0x4\n");
    printf("  addi r7, r7, 0x7\n");

    printf(" # グローバル変数のベースアドレスを初期化\n");
    printf("  lui r8, 0x9\n");
    printf("  asi r8, r8, 0x6\n");
    printf("  addi r8, r8, 0x5\n");

    gen_string_ascii();

    printf(" # main関数へジャンプ\n");
    printf("  jal r6, L_main\n");
    printf("  addi r0, r0, 0x0\n"); //分岐、ジャンプ命令との後にnopを入れる

    // printf("  sub r0, r0, r0\n");
    // printf("  bz L_main\n");
    
    printf("  # ---ここがCPU初期化関数の戻り番地---#\n");
    printf("  # プログラム終了の処理\n");
    printf("  store 0x0, r0, r1\n"); //0x0番地に0x1を格納
    printf("L_HALT:\n");
    // printf("  sub r0, r0, r0\n");
    // printf("  bz L_HALT\n");
    printf("  jal r0, L_HALT\n");
    printf("  addi r0, r0, 0x0\n"); //分岐、ジャンプ命令との後にnopを入れる
  
    printf(" # ここまでCPU初期化関数\n\n");
}

void gen_string_ascii() {
    while (strings) {
        printf(" # 文字列%sの定義\n", strings->name);

        char *string = strings->name;
        int now_offset = strings->offset;
        printf(" # 文字列の先頭アドレスをr9にロードする\n");
            if (now_offset <= MAX_IMM && now_offset >= 0) {
                printf("  addi r9, r8, 0x%x\n", now_offset);
            } else {
                use_lui(now_offset, 14);
                printf("  add r9, r8, r14\n");
            }
        for (int start =strings->offset; start < strings->offset + strings->len; start++) {
            // 文字列の一文字ずつを順にメモリに格納する
            printf("  loadi r1, 0x%x\n", string[start - strings->offset]);
            printf("  store 0x0, r9, r1\n");
            printf("  addi r9, r9, 0x1\n\n");
        }
        // 文字列の最後にヌル文字を格納する
        // printf("  loadi r1, 0x0\n");
        // printf("  store 0x0, r9, r1\n\n");
        strings = strings->next;
    }
}

