#include "header.h"

//入力文字列をトークン列に変換する

Token *token;

const struct {
    char *name;
    int   len;
} keywords[] = {
    {"return", 6},
    {"if", 2},
    {"else", 4},
    {"while", 5},
    {"for", 3},
    {"int", 3},
};


Token *new_token(TokenKind kind, Token *cur, char *str, int len) {
    Token *tok = calloc(1, sizeof(Token));
    tok->kind = kind;
    tok->str = str;
    tok->len = len;
    cur->next = tok;
    return tok;
}

int is_alnum(char c) {
    return ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z') || ('0' <= c && c <= '9') || c == '_';
}

bool startswith(char *p, char *q) {
    return strncmp(p, q, strlen(q)) == 0;
}

//トークン列を作成する関数
Token *tokenize() {
    char *p = user_input;
    Token head;
    head.next = NULL;
    Token *cur = &head;

    while (*p) {
    // スペースをスキップ
    if (isspace(*p)) {
        p++;
        continue;
    }

    if (strncmp(p, "//", 2) == 0) {
        p += 2;
        while (*p != '\n') {
            p++; 
        }
        continue;
    }

    //比較演算子
    if (startswith(p, "==") || startswith(p, "!=") ||
        startswith(p, "<=") || startswith(p, ">=")) {
        cur = new_token(TK_RESERVED, cur, p, 2);
        p += 2;
        continue;
    }

    //論理演算子
    if (startswith(p, "&&") || startswith(p, "||")) {
        cur = new_token(TK_RESERVED, cur, p, 2);
        p += 2;
        continue;
    }

    //演算子
    if (strchr("+-*/%()<>=;{},&[]", *p)) {
        cur = new_token(TK_RESERVED, cur, p++, 1);
        continue;
    }

    //整数
    if (isdigit(*p)) {
        cur = new_token(TK_NUM, cur, p, 0);
        char *q = p;
        cur->val = strtol(p, &p, 10);
        cur->len = p - q;//進んだ後のアドレスから進んだ前のアドレスを引くことで長さを求める
        continue;
    }

    //キーワード
    bool is_keyword = false;
    for (int i = 0; i < sizeof(keywords) / sizeof(keywords[0]); i++) {
        if (strncmp(p, keywords[i].name, keywords[i].len) == 0 && !is_alnum(p[keywords[i].len])) {
        cur = new_token(TK_KEYWORD, cur, p, keywords[i].len);
        p += keywords[i].len;
        is_keyword = true;
        break;
        }
    }
    if (is_keyword) {
        continue;
    }

    // Identifier(関数名/変数名)
    if ('a' <= *p && *p <= 'z' || 'A' <= *p && *p <= 'Z') {
        char *c = p;
        while ('a' <= *c && *c <= 'z' || 'A' <= *c && *c <= 'Z' || '0' <= *c && *c <= '9' || *c == '_') {
        c++;
        }
        int len = c - p;
        cur = new_token(TK_IDENT, cur, p, len);
        p = c;
        continue;
    }

    
    if (*p == '"') {
        p++;
        char *c = p;
        while (*c != '"') {
            c++;
        }
        int len = c - p;
        cur = new_token(TK_STR, cur, p, len);
        p = c + 1; // 終了のダブルクォートをスキップ
        continue;
    }

    error_at(p, "Compile error: invalid token");
    }

    new_token(TK_EOF, cur, p, 0);
    return head.next;
}