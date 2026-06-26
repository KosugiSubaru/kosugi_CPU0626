#include "header.h"

// コンパイラのメイン関数

char *user_input;

int main(int argc, char **argv) {
    if (argc != 2) {
        error("Compile error: Incorrect number of arguments.");
        return 1;
    }

    FILE *input_program = fopen(argv[1], "r");
    int program_size;
    if (input_program == NULL) {
        error("Compile error: Cannot open program file.");
        fclose(input_program);
        return 1;
    }
    fseek(input_program, 0, SEEK_END);  //ファイルポインタをファイルの最後に移動
    program_size = ftell(input_program);//ファイルポインタの現在位置を取得
    rewind(input_program);              //ファイルポインタを先頭に戻す

    user_input = malloc(program_size + 2);//プログラムのサイズ+2バイト分のメモリを確保
    fread(user_input, program_size, 1, input_program);
    user_input[program_size] = '\0';
    fclose(input_program);
  

  // トークナイズする/トークンの連結リストを作成する
    token = tokenize();
    fprintf(stderr, "Successfully tokenized.\n\n");

  //パースする/抽象構文木を作成する
    program();
    fprintf(stderr, "Successfully parsed.\n\n");
    print_function_table();
    print_gvar_list();
    fprintf(stderr, "Global_size: %d\n\n", Gvar_size);
    print_strings();
    print_sizeofcode();

//   抽象構文木を下りながらコード生成
//   printBootStack();
    init();
    // gen_string_ascii();
    for (int i = 0; code[i]; i++) {
        gen(code[i]);
        printf(" # 文が終わるごとにスタックトップをポップ\n");
        printf("  addi r7, r7, -1\n\n");
    }

  //3アドレスコード生成
//   printBootReg();
//   now_quad = calloc(1, sizeof(Quadruple));
//   for (int i = 0; code[i]; i++) {
//     gen_tac(code[i]);
//   }
//   printQuads();

//   //関数ブロック生成
//   gen_FB();
//   printFunc();

//   //基本ブロック生成
//   gen_BB();

//   //生存解析
//   livness_analysis();

//   //アセンブリコード生成
  
//   gen_machinecode();

    return 0;
}