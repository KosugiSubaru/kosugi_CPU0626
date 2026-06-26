#include "header.h"

//再帰的下向き構文解析により，抽象構文木を生成する
#define DMEMCOUNT 1 //変数のサイズ。配列の場合は要素数*1

Node *code[256];

Function_table *function_table;
Function_table *head_function_table;
Gvar_list *gvar_list;
String *strings;

int Gvar_size;

//program    = func
void program() {
    int i = 0;
    while (at_eof() == false) {
        code[i++] = func();
    }
    code[i] = NULL;
}

//func       = int ident "(" ((int ident ",")* int ident)? ")" stmt
Node *func() {
    Node *node;

    //関数名＝識別子
    if (!consume_keyword("int")) {
        error("Compile error: Function return type is not found.");
    }

    Type *type = calloc(1, sizeof(Type));
    type->ty = INT;
    type->ptr_to = NULL;
    while (consume("*")) {
        Type *ptr_next = calloc(1, sizeof(Type));
        ptr_next->ty = PTR;
        ptr_next->ptr_to = type;
        type = ptr_next;
    }

    Token *tok = consume_ident();
    if (tok == NULL) {
        error("Compile error: Function name is not found.");
    }

    if (consume("(")) {
        //関数ノードの作成
        node = calloc(1, sizeof(Node));
        node->kind = ND_FUNCDEF;
        node->funcname = calloc(100, sizeof(char));
        node->len_funcname = tok->len;
        node->type = type;
        memcpy(node->funcname, tok->str, tok->len);

        check_funcname(tok);//関数名の重複チェック
        add_function(tok);//関数名を関数テーブルに追加

        // expect("(");

        while (consume(")") == false) {
            if (!consume_keyword("int")) {
                error("Compile error: Argument type is not found.");
            }
            Type *type = calloc(1, sizeof(Type));
            type->ty = INT;
            type->ptr_to = NULL;
            while (consume("*")) {
                Type *ptr_next = calloc(1, sizeof(Type));
                ptr_next->ty = PTR;
                ptr_next->ptr_to = type;
                type = ptr_next;
            }
            tok = consume_ident();

            if (find_arg(tok) != NULL) {
                error_at(tok->str, "Compile error: Argument name is already defined.");
            }
            add_arg(tok, type);

            if (consume(")") == true) {
                break;
            }
            expect(",");
        }
        node->lhs = stmt();
        return node;
    }
    else {
        // error("Compile error: global variable is not defined.");
        //グローバル変数の宣言
        int size = DMEMCOUNT;//変数のサイズ。配列の場合は要素数*1
        node = calloc(1, sizeof(Node));
        node->kind = ND_NULL;

        while (consume("[")) {
            Type *array_next = calloc(1, sizeof(Type));
            array_next->ty = ARRAY;
            array_next->ptr_to = type;
            array_next->array_size = expect_number();
            type = array_next;
            size *= array_next->array_size;
            // node->array_dim++;
            expect("]");
        }
        // node->len_gvar_name = tok->len;
        // node->gvar_name = calloc(100, sizeof(char));
        // memcpy(node->gvar_name, tok->str, tok->len);

        if (find_gvar(tok) != NULL) {
            error_at(tok->str, "Compile error: G Variable name is already defined.");
        }
        add_gvar(tok, type, size);
        // node->offset = gvar_list->offset;
        // node->type = type;

        expect(";");
        return node;
    }
}

//stmt       = expr ";"
        //    | "{" stmt* "}"
        //    | "if" "(" expr ")" stmt ("else" stmt)?
        //    | "while" "(" expr ")" stmt
        //    | "for" "(" expr? ";" expr? ";" expr? ")" stmt
        //    | "return" expr ";"
        //    | "int" "*"* ident ("[" num "]")* ";"

Node *stmt() {
    Node *node;
    if (consume("{")) {
        node = calloc(1, sizeof(Node));
        node->kind = ND_BLOCK;
        node->vec_block = calloc(256, sizeof(Node));
        for (int i = 0; !consume("}"); i++) {
            node->vec_block[i] = stmt();
        }
        return node;
    }
    else if (consume_keyword("if")) {
        node = calloc(1, sizeof(Node));
        node->kind = ND_IF;
        expect("(");
        node->lhs = expr();
        expect(")");
        node->rhs = stmt();//stmtはセミコロンを含む
        if (consume_keyword("else")) {
            Node *else_node = calloc(1, sizeof(Node));
            else_node->kind = ND_ELSE;
            else_node->lhs = node->rhs;
            else_node->rhs = stmt();
            node->rhs = else_node;
        }
        return node;
    }
    else if (consume_keyword("while")) {
        node = calloc(1, sizeof(Node));
        node->kind = ND_WHILE;
        expect("(");
        node->lhs = expr();
        expect(")");
        node->rhs = stmt();
        return node;
    }
    else if (consume_keyword("for")) {
        node = calloc(1, sizeof(Node));
        node->kind = ND_FOR;
        expect("(");

        Node *for_left = calloc(1, sizeof(Node));
        for_left->kind = ND_FOR_LEFT;
        Node *for_right = calloc(1, sizeof(Node));
        for_right->kind = ND_FOR_RIGHT;

        if (!consume(";")) {
            for_left->lhs = expr();
            expect(";");
        }
        if (!consume(";")) {
            for_left->rhs = expr();
            expect(";");
        }
        if (!consume(")")) {
            for_right->lhs = expr();
            expect(")");
        }
        for_right->rhs = stmt();

        node->lhs = for_left;
        node->rhs = for_right;
        return node;
    }
    else if (consume_keyword("return")) {
        node = calloc(1, sizeof(Node));
        node->kind = ND_RETURN;
        node->lhs = expr();
    }
    // ローカル変数宣言
    else if (consume_keyword("int")) {
        // Check for pointer syntax
        Type *type = calloc(1, sizeof(Type));
        type->ty = INT;
        type->ptr_to = NULL;

        int size = DMEMCOUNT;//変数のサイズ。配列の場合は要素数*1

        // int is_pointer = 0;
        // ポインタ宣言の場合
        while (consume("*")) {
            // is_pointer = 1;
            Type *ptr_next = calloc(1, sizeof(Type));
            ptr_next->ty = PTR;
            ptr_next->ptr_to = type;
            type = ptr_next;
        }

        // ローカル変数のノードを作成
        node = calloc(1, sizeof(Node));
        node->kind = ND_NULL;
        Token *tok = consume_ident();
        if (tok == NULL) {
            error("Compile error: Variable name is not found.");
        }

        // 配列の宣言の場合は型を配列型にして、サイズを計算
        while (consume("[")) {
            Type *array_next = calloc(1, sizeof(Type));
            array_next->ty = ARRAY;
            array_next->ptr_to = type;
            array_next->array_size = expect_number();
            type = array_next;
            size *= array_next->array_size;
            node->array_dim++;
            expect("]");
        }

        // 変数名の重複チェックと変数テーブルへの追加
        node->len_lvar_name = tok->len;
        node->lvar_name = calloc(100, sizeof(char));
        memcpy(node->lvar_name, tok->str, tok->len);

        if (find_lvar(tok) != NULL) {
            error_at(tok->str, "Compile error: Variable name is already defined.");
        }
        add_lvar(tok, type, size);
        node->offset = function_table->lvar_list->offset;
        node->type = type;

    }
    else {
        node = expr();
    }

    expect(";");
    return node;
}

// expr = assign
Node *expr() {
    return assign();
}

// assign = logior ("=" assign)?
Node *assign() {
    Node *node = logior();
    if (consume("="))
        node = new_binary(ND_ASSIGN, node, assign());
    return node;
}

// logior     = logiand ("||" logiand)*
Node *logior() {
    Node *node = logiand();

    for (;;) {
        if (consume("||"))
            node = new_binary(ND_LOGICAL_OR, node, logiand());
        else
            return node;
    }
}

// logiand    = equality ("&&" equality)*
Node *logiand() {
    Node *node = equality();

    for (;;) {
        if (consume("&&"))
            node = new_binary(ND_LOGICAL_AND, node, equality());
        else
            return node;
    }
}

// equality = relational ("==" relational | "!=" relational)*
Node *equality() {
    Node *node = relational();

    for (;;) {
        if (consume("=="))
            node = new_binary(ND_EQ, node, relational());
        else if (consume("!="))
            node = new_binary(ND_NE, node, relational());
        else
        return node;
    }
}

// relational = add ("<" add | "<=" add | ">" add | ">=" add)*
Node *relational() {
    Node *node = add();

    for (;;) {
        if (consume("<"))
            node = new_binary(ND_LT, node, add());
        else if (consume("<="))
            node = new_binary(ND_LE, node, add());
        else if (consume(">"))
            node = new_binary(ND_LT, add(), node);
        else if (consume(">="))
            node = new_binary(ND_LE, add(), node);
        else
        return node;
    }
}

// add = mul ("+" mul | "-" mul)*
Node *add() {
    Node *node = mul();

    for (;;) {
        if (consume("+"))
            node = new_binary(ND_ADD, node, mul());
        else if (consume("-"))
            node = new_binary(ND_SUB, node, mul());
        else
        return node;
    }
}

// mul = unary ("*" unary | "/" unary | "%" unary)*
Node *mul() {
  Node *node = unary();

    for (;;) {
        if (consume("*"))
            node = new_binary(ND_MUL, node, unary());
        else if (consume("/"))
            node = new_binary(ND_DIV, node, unary());
        else if (consume("%"))
            node = new_binary(ND_REM, node, unary());
        else
        return node;
    }
}

// unary = "+"? primary
    //   | "-"? primary
    //   | "*" unary
    //   | "&" unary
Node *unary() {
    if (consume("+"))
        return unary();
    if (consume("-"))
        return new_binary(ND_SUB, new_num(0), unary());
    if (consume("&"))
        return new_binary(ND_ADDR, unary(), NULL);
    if (consume("*"))
        return new_binary(ND_DEREF, unary(), NULL);
    return primary();
}

// primary    = num 
//            | ident ("(" ((expr ",")* expr)? ")")? 
//            | "(" expr ")" 
Node *primary() {
  // 次のトークンが"("なら、"(" expr ")"
    if (consume("(") == true) {
        Node *node = expr();
        expect(")");
        return node;
    }

    Token *tok = consume_ident();
    //次のトークンが識別子の場合
    if (tok) {
        // その次のトークンが"("なら、関数呼び出し
        if (consume("(")) {
            Node *node = calloc(1, sizeof(Node));
            node->kind = ND_FUNCCALL;
            node->funcname = calloc(100, sizeof(char));
            memcpy(node->funcname, tok->str, tok->len);
            node->vec_funcarg = calloc(256, sizeof(Node));

            for (int i = 0; consume(")") == false; i++) {
                node->vec_funcarg[i] = expr();
                node->len_args = i+1;
                if (consume(")"))
                break;
                expect(",");
            }
        return node;
        }

        //その次のトークンが"("でない場合
        //まずは引数であるかを確認
        Args_list *arg = find_arg(tok);
        if (arg != NULL) {
            Node *node = calloc(1, sizeof(Node));
            node->kind = ND_ARG;
            node->offset = arg->offset;
            node->len_arg_name = tok->len;
            node->arg_name = calloc(100, sizeof(char));
            memcpy(node->arg_name, tok->str, tok->len);
            return node;
        }
    
        //次にローカル変数を確認
        Lvar_list *lvar = find_lvar(tok);
        if (lvar != NULL) {
            Node *node = calloc(1, sizeof(Node));
            node->kind = ND_LVAR;
            node->len_lvar_name = tok->len;
            node->lvar_name = calloc(100, sizeof(char));
            memcpy(node->lvar_name, tok->str, tok->len);
            node->offset = lvar->offset;
            node->type = lvar->type;

                    // 配列の場合の処理
            while (consume("[")) {
                Node *index_node = calloc(1, sizeof(Node));
                index_node->kind = ND_ADD;
                index_node->lhs = node;
                index_node->rhs = expr();

                node = calloc(1, sizeof(Node));
                node->kind = ND_DEREF;
                node->lhs = index_node;
                expect("]");
            }
        return node;
        } 
        else if (find_gvar(tok) != NULL) {
            Node *node = calloc(1, sizeof(Node));
            node->kind = ND_GVAR;
            node->len_gvar_name = tok->len;
            node->gvar_name = calloc(100, sizeof(char));
            memcpy(node->gvar_name, tok->str, tok->len);
            node->offset = find_gvar(tok)->offset;
            node->type = find_gvar(tok)->type;

                // 配列の場合の処理
            while (consume("[")) {
                Node *index_node = calloc(1, sizeof(Node));
                index_node->kind = ND_ADD;
                index_node->lhs = node;
                index_node->rhs = expr();

                node = calloc(1, sizeof(Node));
                node->kind = ND_DEREF;
                node->lhs = index_node;
                expect("]");
            }
            return node;
        }
        else {
            error_at(tok->str, "Compile error: Variable is not defined.");
        }
    }

    tok = consume_str();
    if (tok) {
        // fprintf(stderr, "String literal: %.*s\n", token->len, token->str);
        // error_at(token->str, "Compile error: String literal is not supported.");
        String *str = calloc(1, sizeof(String));
        str->name = calloc(100, sizeof(char));
        memcpy(str->name, tok->str, tok->len);
        str->len = tok->len+1;//ヌル文字分も含める
        str->next = strings;
        str->offset = Gvar_size + 1;
        Gvar_size += str->len;
        strings = str;

        Node *node = calloc(1, sizeof(Node));
        node->kind = ND_STR;
        node->str = str;
        node->offset = str->offset;
        return node;
    }
    
  // そうでなければ数値
  return new_num(expect_number());
}
