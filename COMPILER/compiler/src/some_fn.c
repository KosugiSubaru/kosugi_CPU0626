# include "header.h"

void error(char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    exit(1);
}

//エラーを報告するための関数
void error_at(char *loc, char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);

    // int pos = loc - user_input;
    // fprintf(stderr, "%s\n", user_input);
    // fprintf(stderr, "%*s", pos, ""); // print pos spaces.
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, " \"%s\" ", loc);
    
    fprintf(stderr, "\n");
    exit(1);
}

bool consume(char *op) {
    if (token->kind != TK_RESERVED || strlen(op) != token->len ||
        memcmp(token->str, op, token->len))
        {
            return false; //falseの場合はトークンを進めない
        }
    token = token->next;
    return true;
}

Token *consume_ident() {
    if (token->kind != TK_IDENT) {
        return NULL;
    }
    Token *t = token;
    token = token->next;
    return t;
}

Token *consume_str() {
    if (token->kind != TK_STR) {
        return NULL;
    }
    Token *t = token;
    token = token->next;
    return t;
}

bool consume_keyword(char *op) {
    if (token->kind != TK_KEYWORD ||
        strlen(op) != token->len || memcmp(token->str, op, token->len)) {
        return false;
    }
    token = token->next;
    return true;
}

void expect(char *op) {
    if (token->kind != TK_RESERVED || strlen(op) != token->len ||
        memcmp(token->str, op, token->len)) {
        error_at(token->str, "Compile erorr: expected \"%s\"", op);
    }
    token = token->next;
}

int expect_number() {
    if (token->kind != TK_NUM) {
        error_at(token->str, "Compile erorr: Need a block after function defenition.");
    }
    int val = token->val;
    token = token->next;
    return val;
}

bool at_eof() {
    return token->kind == TK_EOF;
}

void add_function(Token *tok) {
    Function_table *func = calloc(1, sizeof(Function_table));
    func->funcname = calloc(100, sizeof(char));
    memcpy(func->funcname, tok->str, tok->len);
    func->next = function_table;
    func->len_funcname = tok->len;
    function_table = func;
}

Function_table *find_function(Node *node) {
    for (Function_table *func = function_table; func; func = func->next) {
        if (!memcmp(node->funcname, func->funcname, node->len_funcname)) {
            return func;
        }
    }
    return NULL;
}

void check_funcname(Token *tok) {
    for (Function_table *func = function_table; func; func = func->next) {
        if (!memcmp(tok->str, func->funcname, tok->len)) {
            error_at(tok->str, "Compile erorr: Function name is already defined.");
        }
    }
}

Lvar_list *find_lvar(Token *tok) {
    for (Lvar_list *lvar = function_table->lvar_list; lvar; lvar = lvar->next) {
        if (lvar->len_lvar_name == tok->len && 
            !memcmp(tok->str, lvar->lvar_name, lvar->len_lvar_name)) {
            return lvar;
        }
    }
    return NULL;
}

Gvar_list *find_gvar(Token *tok) {
    for (Gvar_list *gvar = gvar_list; gvar; gvar = gvar->next) {
        if (gvar->len_gvar_name == tok->len && 
            !memcmp(tok->str, gvar->gvar_name, gvar->len_gvar_name)) {
            return gvar;
        }
    }
    return NULL;
}

void add_lvar(Token *tok, Type *type, int size) {
    Lvar_list *lvar = calloc(1, sizeof(Lvar_list));
    lvar->lvar_name = calloc(100, sizeof(char));
    memcpy(lvar->lvar_name, tok->str, tok->len);
    lvar->next = function_table->lvar_list;
    lvar->len_lvar_name = tok->len;
    lvar->type = type;

    if (function_table->lvar_list != NULL) {
        lvar->offset = function_table->lvar_list_size + 1;
    } else {
        lvar->offset = 1;
    }
    function_table->lvar_list = lvar;
    function_table->lvar_list_size += size; 
}

void add_gvar(Token *tok, Type *type, int size) {
    Gvar_list *gvar = calloc(1, sizeof(Gvar_list));
    gvar->gvar_name = calloc(100, sizeof(char));
    memcpy(gvar->gvar_name, tok->str, tok->len);
    gvar->next = gvar_list;
    gvar->len_gvar_name = tok->len;
    gvar->type = type;

    if (gvar_list != NULL) {
        gvar->offset = Gvar_size + 1;
    } else {
        gvar->offset = 1;
    }
    gvar_list = gvar;
    Gvar_size += size;
}

Args_list *find_arg(Token *tok) {
    for (Args_list *arg = function_table->args_list; arg; arg = arg->next) {
        if (arg->len_arg_name == tok->len && 
            !memcmp(tok->str, arg->arg_name, arg->len_arg_name)) {
            return arg;
        }
    }
    return NULL;
}

void add_arg(Token *tok, Type *type) {
    Args_list *arg = calloc(1, sizeof(Args_list));
    arg->arg_name = calloc(100, sizeof(char));
    memcpy(arg->arg_name, tok->str, tok->len);
    arg->next = function_table->args_list;
    arg->len_arg_name = tok->len;
    arg->type = type;

    if (function_table->args_list != NULL) {
        arg->offset = function_table->args_list->offset + 1;
    } else {
        arg->offset = 1;//要注意
    }
    function_table->args_list = arg;
    function_table->args_list_size++;
}

Node *new_node(NodeKind kind) {
    Node *node = calloc(1, sizeof(Node));
    node->kind = kind;
    return node;
}

Node *new_num(int val) {
    Node *node = new_node(ND_NUM);
    node->val = val;
    return node;
}

Node *new_binary(NodeKind kind, Node *lhs, Node *rhs) {
    Node *node = new_node(kind);
    node->lhs = lhs;
    node->rhs = rhs;
    return node;
}

void print_function_table() {
    for (Function_table *func = function_table; func; func = func->next) {
        fprintf(stderr, "Function name: %s\n", func->funcname);
        fprintf(stderr, "Local variables:\n");
        for (Lvar_list *lvar = func->lvar_list; lvar; lvar = lvar->next) {
            fprintf(stderr, "  %s (offset: %d)\n", lvar->lvar_name, lvar->offset);
        }
        fprintf(stderr, "Arguments:\n");
        for (Args_list *arg = func->args_list; arg; arg = arg->next) {
            fprintf(stderr, "  %s (offset: %d)\n", arg->arg_name, arg->offset);
        }
        // その関数のローカル変数が確保するメモリサイズを出力
        fprintf(stderr, "Total local variable size: %d\n", func->lvar_list_size); 
        fprintf(stderr, "Total argument size: %d\n", func->args_list_size);
    }
}

void print_gvar_list() {
    fprintf(stderr, "Global variables:\n");
    for (Gvar_list *gvar = gvar_list; gvar; gvar = gvar->next) {
        fprintf(stderr, "  %s (offset: %d)\n", gvar->gvar_name, gvar->offset);
    }
}

void print_strings() {
    fprintf(stderr, "String literals:\n");
    for (String *str = strings; str; str = str->next) {
        fprintf(stderr, "  %s (offset: %d)\n", str->name, str->offset);
    }
}

void print_sizeofcode() {
    //　NULLでない要素の数を数える
    int count = 0;
    for (int i = 0; code[i] != NULL; i++) {
        count++;
    }
    fprintf(stderr, "Number of functions in code array: %d\n", count);
}