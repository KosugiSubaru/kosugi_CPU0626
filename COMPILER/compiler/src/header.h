#include <ctype.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TK_RESERVED,    // Operator or separator
    TK_KEYWORD,     // Keyword
    TK_IDENT,       // Identifiers
    TK_NUM,         // Integer literals
    TK_EOF,         // End-of-file markers
    TK_TYPE,        // Types
    TK_STR,         // String literals
} TokenKind;

typedef struct Type Type;
struct Type {
    enum {INT, PTR, ARRAY} ty; // Type kind
    Type *ptr_to;       // If ty == PTR, the type pointed to
    int array_size;  // If ty == ARRAY, the size of the array
};

// Token type
typedef struct Token Token;
struct Token {
    TokenKind kind; // Token kind
    Token    *next; // Next token
    int       val;  // If kind is TK_NUM, its value
    char     *str;  // Token string
    int       len;  // Token length
};

typedef struct String String;
struct String {
    char *name;
    int len;
    int offset; //文字列リテラルの位置
    String *next;
};

typedef struct Lvar_list Lvar_list;
struct Lvar_list {
    char *lvar_name; //ローカル変数名
    int len_lvar_name;
    int offset; //スタックにおけるローカル変数の位置
    Type *type; //変数の型
    Lvar_list *next;
};

typedef struct Args_list Args_list;
struct Args_list {
    char *arg_name; //引数名
    int len_arg_name;
    int offset; //スタックにおける引数の位置
    Type *type; //引数の型
    Args_list *next;
};

typedef struct Gvar_list Gvar_list;
struct Gvar_list {
    char *gvar_name; //グローバル変数名
    int len_gvar_name;
    int offset; //グローバル変数の位置
    Type *type; //グローバル変数の型
    Gvar_list *next;
};

typedef struct Function_table Function_table;
struct Function_table {
    char *funcname; //関数名
    int len_funcname;
    Function_table *next;
    Lvar_list *lvar_list; //ローカル変数リスト
    int lvar_list_size;   //その関数のローカル変数が確保するメモリサイズ
    Args_list *args_list; //引数リスト
    int args_list_size;
};

typedef enum {
    ND_NULL,        // Null code生成しない
    ND_ADD,         // +
    ND_SUB,         // -
    ND_MUL,         // *
    ND_DIV,         // /
    ND_REM,         // %
    ND_EQ,          // ==
    ND_NE,          // !=
    ND_LT,          // <
    ND_LE,          // <=
    ND_ASSIGN,      // =
    ND_LOGICAL_AND, // &&
    ND_LOGICAL_OR,  // ||
    ND_LVAR,        // Local variable
    ND_GVAR,        // Global variable
    ND_NUM,         // Integer
    ND_RETURN,      // Return
    ND_IF,          // If
    ND_ELSE,        // Else
    ND_WHILE,       // While
    ND_FOR,         // For
    ND_FOR_LEFT,    // For left
    ND_FOR_RIGHT,   // For right
    ND_BLOCK,       // Block
    ND_FUNCCALL,     // Function call
    ND_FUNCDEF,     // Function definition
    ND_ARG,         // Function argument
    ND_ADDR,        // &
    ND_DEREF,       // *
    ND_STR,         // String literal
    // ND_PRINT_NUM,   // Print number
    // ND_PRINT_STR,   // Print string
    // ND_SCAN,       // Scan
} NodeKind;

// AST node type
typedef struct Node Node;
struct Node {
    NodeKind kind;      // Node kind
    Node *lhs;          // Left-hand side
    Node *rhs;          // Right-hand side
    int val;            // Used if kind == ND_NUM or SCAN
    char *lvar_name;    // Used if kind == ND_LVAR
    int len_lvar_name;  // Used if kind == ND_LVAR
    int offset;         // Used if kind == ND_LVAR or ND_ARG or ND_STR or ND_GVAR
    char *funcname;     // Used if kind == FUNCCALL
    int len_funcname;   
    char *arg_name;     // Used if kind == ND_ARG
    int len_arg_name;
    int len_args;       // Used if kind == FUNCCALL
    Node **vec_block;   // Used if kind == ND_BLOCK
    Node **vec_funcarg; // Used if kind == FUNCCALL or FUNCDEF
    Type *type;         // Used if kind == ND_LVAR or ND_ARG or ND_GVAR or FUNCDEF
    int array_dim;   // If ARRAY, the dimension of the array
    int len_gvar_name;  // Used if kind == ND_GVAR
    char *gvar_name;    // Used if kind == ND_GVAR
    String *str;        // Used if kind == ND_STR
};


extern Token *token;
extern char *user_input;
extern Function_table *function_table;
extern Node *code[256];
extern Gvar_list *gvar_list;
extern String *strings;
extern int Gvar_size;

void error(char *fmt, ...);
void error_at(char *loc, char *fmt, ...);
Token *tokenize();
bool startswith(char *p, char *q);
Token *consume_ident();
Token *consume_str();
void expect(char *op);
void add_function(Token *tok);
void check_funcname(Token *tok);
void add_lvar(Token *tok, Type *type, int size);
void add_gvar(Token *tok, Type *type, int size);
void add_arg(Token *tok, Type *type);
Args_list *find_arg(Token *tok);
Lvar_list *find_lvar(Token *tok);
Gvar_list *find_gvar(Token *tok);
bool consume(char *op);
bool consume_keyword(char *keyword);
int expect_number();
bool at_eof();
Node *new_node(NodeKind kind);
Node *new_binary(NodeKind kind, Node *lhs, Node *rhs);
Node *new_num(int val);
void print_function_table();
void print_gvar_list();
void gen(Node *node);
Function_table *find_function(Node *node);
void init();
void gen_string_ascii();
void use_lui(int val, int reg);


void program();
Node *func();
Node *stmt();
Node *expr();
Node *assign();
Node *logior();
Node *logiand();
Node *equality();
Node *relational();
Node *add();
Node *mul();
Node *unary();
Node *primary();
