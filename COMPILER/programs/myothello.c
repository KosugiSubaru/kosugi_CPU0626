
int BOARDSIZE;
int ENPTY;
int BLACK;
int WHITE;
int *DISPLAY;
int *MATKAY;
int *BUTTON;
int *LEDs;
int DISPLAY_ROW_SIZE;
int DISPLAY_COL_SIZE;

int BOARD[64];
int BOARD_TMP[64];
int EVAL_MAP[64];
int USER_NAME[32];

int DX[8];
int DY[8];

int SCANBUF[32];

int welcome_user_name() {
    // USER_NAMEのゼロクリア
    int i;
    while (1) {
        for (i = 0; i < 32; i=i+1) {
            USER_NAME[i] = 0;
        }
        clear_screen();
        putchar("Enter your name: \ ");
        scan();
        // SCANBUFに入力された文字列をUSER_NAMEにコピーし、SCANBUFを0で埋める
        for (i = 0; i < 32; i=i+1) {
            USER_NAME[i] = SCANBUF[i];
            SCANBUF[i] = 0;
        }
        // USER_NAMEを表示
        putchar("\ Hello,  ");
        putchar(USER_NAME);
        putchar("! \ Let's play Othello with me. Do you want to play? (y/n) \ ");
        scan();
        if (SCANBUF[0] == 121) { // 'y' or 'Y'
            return 1; // プレイ
        }
    }
}

int initialize_board(int *board_ptr) {
    int i;
    int j;
    int *board;
    board = board_ptr;
    for (i = 0; i < 64; i=i+1) {
        board[i] = ENPTY;
    }
    // 初期配置
    board[3 * BOARDSIZE + 3] = WHITE;
    board[3 * BOARDSIZE + 4] = BLACK;
    board[4 * BOARDSIZE + 3] = BLACK;
    board[4 * BOARDSIZE + 4] = WHITE;
}

int print_board(int *board_ptr) {
    int i;
    int j;
    int *board;
    board = board_ptr;
    putchar("  0  1  2  3  4  5  6  7 \ ");

    for(i = 0; i < BOARDSIZE; i=i+1) {
        putint(i);
        putchar(" ");
        for(j = 0; j < BOARDSIZE; j=j+1) {
            if (board[i * BOARDSIZE + j] == BLACK) {
                putchar("O  ");
            }
            else if (board[i * BOARDSIZE + j] == WHITE) {
                putchar("X  ");
            }
            else if (board[i * BOARDSIZE + j] == ENPTY) {
                putchar(".  ");
            }
            else {
                putchar("?  ");
            }
        }
        putchar("\ \ ");
    }
}


int has_valid_move(int *board_ptr, int player) {
    int i;
    int j;
    for (i = 0; i < BOARDSIZE; i=i+1) {
        for (j = 0; j < BOARDSIZE; j=j+1) {
            // do_flip = 0 (シミュレーションモード) で反転可能数が1以上かチェック
            if (check_and_flip(board_ptr, i, j, player, 0) > 0) {
                return 1; // 1箇所でも置ける場所があれば即座に真を返す
            }
        }
    }
    return 0; // 全マス走査して置ける場所がなければ偽
}

int is_on_board(int x, int y) {
    return ((x >= 0) && (x < BOARDSIZE) && (y >= 0) && (y < BOARDSIZE));
}

int check_and_flip(int *board_ptr, int x, int y, int player, int do_flip) {
    int *board;
    board = board_ptr;
    // 既に石がある場所には置けない
    if (board[x * BOARDSIZE + y] != ENPTY) {
        return 0;
    }

    int total_flipped;
    total_flipped = 0;
    int opponent;
    opponent = -player; // 黒(1)の相手は白(-1)、白(-1)の相手は黒(1)
    int dir;

    int nx;
    int ny;
    int count;

    int fx;
    int fy;

    // 8方向を順次走査
    for (dir = 0; dir < 8; dir=dir+1) {
        nx=0;
        ny=0;
        nx = x + DX[dir];
        ny = y + DY[dir];
        count = 0;

        // 1. 隣から相手の石が連続している間、直進する
        while (is_on_board(nx, ny) && board[nx * BOARDSIZE + ny] == opponent) {
            nx = nx + DX[dir];
            ny = ny + DY[dir];
            count=count+1;
        }

        // 2. 相手の石が1枚以上連続し、かつ突き当たったマスが自分の石かチェック
        if (count > 0 && is_on_board(nx, ny) && board[nx * BOARDSIZE + ny] == player) {
            // この方向で挟むことに成功
            total_flipped = total_flipped + count;

            // do_flipフラグが真の場合、実際に石を裏返す
            if (do_flip) {
                fx = 0;
                fy = 0;
                fx = x + DX[dir];
                fy = y + DY[dir];
                // 突き当たった(nx, ny)の手前まで戻りながら反転
                while (fx != nx || fy != ny) {
                    board[fx * BOARDSIZE + fy] = player;
                    fx = fx + DX[dir];
                    fy = fy + DY[dir];
                }
            }
        }
    }

    // 1枚以上反転可能で、かつ更新フラグが立っていれば、着手マス自体にも自分の石を配置
    if (total_flipped > 0 && do_flip) {
        board[x * BOARDSIZE + y] = player;
    }

    return total_flipped; // 反転した総数を返す（0なら着手不可能を意味する）
}

int evaluate_board(int *board_ptr, int player) {
    int *board;
    board = board_ptr;
    int score;
    score = 0;
    int i;
    int j;
    for (i = 0; i < BOARDSIZE; i=i+1) {
        for (j = 0; j < BOARDSIZE; j=j+1) {
            if (board[i * BOARDSIZE + j] == player) {
                score = score + EVAL_MAP[i * BOARDSIZE + j];
            }
            else if (board[i * BOARDSIZE + j] == -player) {
                score = score - EVAL_MAP[i * BOARDSIZE + j];
            }
        }
    }
    return score;
}

int think_ai_move(int player, int *out_x, int *out_y) {
    int *out_x_buf;
    int *out_y_buf;
    out_x_buf = out_x;
    out_y_buf = out_y;
    // ここにAIの思考ルーチンを実装する予定
    // 現在はダミーで、ユーザーからの入力を受け取る形になっている
    int current_score;
    int max_score;
    max_score = -9999; // 評価値の下限初期化
    int best_x;
    best_x = -1;
    int best_y;
    best_y = -1;
   
    // BOARD_TMPに現在の盤面をコピー
    int i;
    int j;
    int k;
    int l;

    for (i = 0; i < BOARDSIZE; i=i+1) {
        for (j = 0; j < BOARDSIZE; j=j+1) {
            for (k = 0; k < BOARDSIZE; k=k+1) {
                for (l = 0; l < BOARDSIZE; l=l+1) {
                    BOARD_TMP[k * BOARDSIZE + l] = BOARD[k * BOARDSIZE + l];
                }
            }
            // シミュレーションモード (do_flip=0) で着手可能か判定
            if (check_and_flip(BOARD_TMP, i, j, player, 0) > 0) {
                // 実際に仮配置・反転を行う (do_flip=1)
                check_and_flip(BOARD_TMP, i, j, player, 1);

                // 遷移後の盤面を評価
                current_score = evaluate_board(BOARD_TMP, player);
                putint(current_score);
                putchar(" ");
                // 最大値更新（Greedy法による最大化選択）
                if (current_score > max_score) {
                    max_score = current_score;
                    best_x = i;
                    best_y = j;
                }
            }
        }
    }
    putchar(" \ ");
    *out_x_buf = best_x;
    *out_y_buf = best_y;
    return 0;
}

int print_result(int *board_ptr) {
    int *board;
    board = board_ptr;
    int black_count;
    int white_count;
    black_count = 0;
    white_count = 0;
    int i;
    int j;
    for (i = 0; i < 64; i=i+1) {
        if (board[i] == BLACK) {
            black_count = black_count + 1;
        }
        else if (board[i] == WHITE) {
            white_count = white_count + 1;
        }
    }
    putchar("Game Over. Final Score: \ ");
    putchar("BLACK (O): ");
    putint(black_count);
    putchar(" \ ");
    putchar("WHITE (X): ");
    putint(white_count);
    putchar("\ ");
    putchar("Result: ");
    if (black_count > white_count) {
        putchar("BLACK (O) Wins! \ ");
    }
    else if (white_count > black_count) {
        putchar("WHITE (X) Wins! \ ");
    }
    else {
        putchar("Draw (Tie Game). \ ");
    }
}
    
int main () {
    // int DX[8];
    // int DY[8];

    BOARDSIZE = 8;
    ENPTY = 0;
    BLACK = 1;
    WHITE = -1;
    DISPLAY = 1;
    LEDs = 4455;
    MATKAY = 4456;
    BUTTON = 4457;


    DISPLAY_ROW_SIZE = 25;
    DISPLAY_COL_SIZE = 80;

    DX[0] = -1; DX[1] =  1; DX[2] =  0; DX[3] =  0; DX[4] = -1; DX[5] = -1; DX[6] =  1; DX[7] =  1;
    DY[0] =  0; DY[1] =  0; DY[2] = -1; DY[3] =  1; DY[4] = -1; DY[5] =  1; DY[6] = -1; DY[7] =  1;

    int i;
    int j;
    int display_buf;

    // SCANBUFのゼロクリア
    for (i = 0; i < 32; i=i+1) {
        SCANBUF[i] = 0;
    }
    
    // display_buf = DISPLAY;
    welcome_user_name();
    // DISPLAY = display_buf;

    // EVAL_MAPの初期化は、USER_NAMEの値（ASCII）より、ランダムに重み付け
    EVAL_MAP[0] = USER_NAME[0]-97; EVAL_MAP[1] = USER_NAME[1]-97; EVAL_MAP[2] = USER_NAME[2]-97; EVAL_MAP[3] = USER_NAME[3]-97; EVAL_MAP[4] = USER_NAME[4]-97; EVAL_MAP[5] = USER_NAME[5]-97; EVAL_MAP[6] = USER_NAME[6]-97; EVAL_MAP[7] = USER_NAME[7]-97;
    EVAL_MAP[8] = USER_NAME[8]-97; EVAL_MAP[9] = USER_NAME[9]-97; EVAL_MAP[10] = USER_NAME[10]-97; EVAL_MAP[11] = USER_NAME[11]-97; EVAL_MAP[12] = USER_NAME[12]-97; EVAL_MAP[13] = USER_NAME[13]-97; EVAL_MAP[14] = USER_NAME[14]-97; EVAL_MAP[15] = USER_NAME[15]-97;
    EVAL_MAP[16] = USER_NAME[16]-97; EVAL_MAP[17] = USER_NAME[17]-97; EVAL_MAP[18] = USER_NAME[18]-97; EVAL_MAP[19] = USER_NAME[19]-97; EVAL_MAP[20] = USER_NAME[20]-97; EVAL_MAP[21] = USER_NAME[21]-97; EVAL_MAP[22] = USER_NAME[22]-97; EVAL_MAP[23] = USER_NAME[23]-97;
    EVAL_MAP[24] = USER_NAME[24]-97; EVAL_MAP[25] = USER_NAME[25]-97; EVAL_MAP[26] = USER_NAME[26]-97; EVAL_MAP[27] = USER_NAME[27]-97; EVAL_MAP[28] = USER_NAME[28]-97; EVAL_MAP[29] = USER_NAME[29]-97; EVAL_MAP[30] = USER_NAME[30]-97; EVAL_MAP[31] = USER_NAME[31]-97;
    EVAL_MAP[32] = USER_NAME[0]-97; EVAL_MAP[33] = USER_NAME[1]-97; EVAL_MAP[34] = USER_NAME[2]-97; EVAL_MAP[35] = USER_NAME[3]-97; EVAL_MAP[36] = USER_NAME[4]-97; EVAL_MAP[37] = USER_NAME[5]-97; EVAL_MAP[38] = USER_NAME[6]-97; EVAL_MAP[39] = USER_NAME[7]-97;
    EVAL_MAP[40] = USER_NAME[8]-97; EVAL_MAP[41] = USER_NAME[9]-97; EVAL_MAP[42] = USER_NAME[10]-97; EVAL_MAP[43] = USER_NAME[11]-97; EVAL_MAP[44] = USER_NAME[12]-97; EVAL_MAP[45] = USER_NAME[13]-97; EVAL_MAP[46] = USER_NAME[14]-97; EVAL_MAP[47] = USER_NAME[15]-97;
    EVAL_MAP[48] = USER_NAME[16]-97; EVAL_MAP[49] = USER_NAME[17]-97; EVAL_MAP[50] = USER_NAME[18]-97; EVAL_MAP[51] = USER_NAME[19]-97; EVAL_MAP[52] = USER_NAME[20]-97; EVAL_MAP[53] = USER_NAME[21]-97; EVAL_MAP[54] = USER_NAME[22]-97; EVAL_MAP[55] = USER_NAME[23]-97;
    EVAL_MAP[56] = USER_NAME[24]-97; EVAL_MAP[57] = USER_NAME[25]-97; EVAL_MAP[58] = USER_NAME[26]-97; EVAL_MAP[59] = USER_NAME[27]-97; EVAL_MAP[60] = USER_NAME[28]-97; EVAL_MAP[61] = USER_NAME[29]-97; EVAL_MAP[62] = USER_NAME[30]-97; EVAL_MAP[63] = USER_NAME[31]-97;
    // EVAL_MAP[0] = 99 + USER_NAME[0]-97; 
    // EVAL_MAP[1] = -8; EVAL_MAP[2] = 8 + USER_NAME[1]-97; EVAL_MAP[3] = 6; EVAL_MAP[4] = 6; EVAL_MAP[5] = 8; EVAL_MAP[6] = -8; EVAL_MAP[7] = 99;
    // EVAL_MAP[8] = -8; EVAL_MAP[9] = -24; EVAL_MAP[10] = -4; EVAL_MAP[11] = -3; EVAL_MAP[12] = -3; EVAL_MAP[13] = -4; EVAL_MAP[14] = -24; EVAL_MAP[15] = -8;
    // EVAL_MAP[16] = 8; EVAL_MAP[17] = -4; EVAL_MAP[18] = 7; EVAL_MAP[19] = 4; EVAL_MAP[20] = 4; EVAL_MAP[21] = 7; EVAL_MAP[22] = -4; EVAL_MAP[23] = 8;
    // EVAL_MAP[24] = 6; EVAL_MAP[25] = -3; EVAL_MAP[26] = 4; EVAL_MAP[27] = 0; EVAL_MAP[28] = 0; EVAL_MAP[29] = 4; EVAL_MAP[30] = -3; EVAL_MAP[31] = 6;
    // EVAL_MAP[32] = 6; EVAL_MAP[33] = -3; EVAL_MAP[34] = 4; EVAL_MAP[35] = 0; EVAL_MAP[36] = 0; EVAL_MAP[37] = 4; EVAL_MAP[38] = -3; EVAL_MAP[39] = 6;
    // EVAL_MAP[40] = 8; EVAL_MAP[41] = -4; EVAL_MAP[42] = 7; EVAL_MAP[43] = 4; EVAL_MAP[44] = 4; EVAL_MAP[45] = 7; EVAL_MAP[46] = -4; EVAL_MAP[47] = 8;
    // EVAL_MAP[48] = -8; EVAL_MAP[49] = -24; EVAL_MAP[50] = -4; EVAL_MAP[51] = -3; EVAL_MAP[52] = -3; EVAL_MAP[53] = -4; EVAL_MAP[54] = -24; EVAL_MAP[55] = -8;
    // EVAL_MAP[56] = 99; EVAL_MAP[57] = -8; EVAL_MAP[58] = 8; EVAL_MAP[59] = 6; EVAL_MAP[60] = 6; EVAL_MAP[61] = 8; EVAL_MAP[62] = -8; EVAL_MAP[63] = 99;    

    clear_screen();
    initialize_board(BOARD);
    // print_board(BOARD);

    int current_player;
    current_player = BLACK;

    int consecutive_passes;
    consecutive_passes = 0;

    // display_buf = DISPLAY;

    // // fill_screen();
    // return 0;

    while (consecutive_passes < 2) {
        // DISPLAY = display_buf;
        print_board(BOARD);
        if (current_player == BLACK) {
            putchar("\ Turn: BLACK (O)\ ");
        }
        else {
            putchar("\ Turn: WHITE (X)\ ");
        }

        if (has_valid_move(BOARD, current_player)==0) {
            consecutive_passes = consecutive_passes + 1;
            if (current_player == BLACK) {
                putchar("BLACK has no valid moves. Passing...\ ");
            }
            else {
                putchar("WHITE has no valid moves. Passing...\ ");
            }
            current_player = -current_player;
        }
        else {
            consecutive_passes = 0;
            int x;
            int y;
            x = -1;
            y = -1;
            int move_made;
            move_made = 0;
            if (current_player == BLACK) {
                putchar(USER_NAME);
                putchar(", enter your move (row col): \ ");
                scan();
                putchar("\ ");
                //アスキーから数値への変換
                x = SCANBUF[0] - 48;
                y = SCANBUF[1] - 48;
                move_made = check_and_flip(BOARD, x, y, current_player, 1);
                if (move_made == 0) {
                    putchar("Invalid move. Try again.\ ");
                }
                // think_ai_move(current_player, &x, &y);
                // putint(x);
                // putint(y);
                // putchar("\ ");
                // move_made = check_and_flip(BOARD, x, y, current_player, 1);
                // if (move_made == 0) {
                //     putchar("AI made an invalid move.\ ");
                // }

            }
            else {
                putchar("AI is thinking... \ ");
                //一時的に人間
                // scan();
                // putchar("\ ");
                // x = SCANBUF[0] - 48;
                // y = SCANBUF[1] - 48;
                // move_made = check_and_flip(BOARD, x, y, current_player, 1);
                // if (move_made == 0) {
                //     putchar("Invalid move. Try again.\ ");
                // }
                think_ai_move(current_player, &x, &y);
                putint(x);
                putint(y);
                putchar("\ ");
                move_made = check_and_flip(BOARD, x, y, current_player, 1);
                if (move_made == 0) {
                    putchar("AI made an invalid move.\ ");
                }
            }
            if (move_made != 0) {
                // print_board();
                current_player = -current_player;
            }

        }
        clear_screen();
    }
    // DISPLAY = display_buf;
    print_board(BOARD);
    print_result(BOARD);
    // putchar("program finished. \ ");
    return 0;
}


// 以下、I/O関数の実装

int putchar(int *c) {
    // int display_col_size;
    int now_row;
    int *C_buf;

    C_buf = c;
    // display_col_size = 80;
    now_row = DISPLAY / DISPLAY_COL_SIZE;

    while (*C_buf) {
        if (*C_buf == 92) {
            DISPLAY = DISPLAY_COL_SIZE * (now_row + 1);
            now_row = now_row + 1;
        }
        else {
            *DISPLAY = *(C_buf);
            DISPLAY = DISPLAY + 1;
        }
        
        C_buf = C_buf + 1;
    }
}

int putint(int num) {
    // int display_col_size;
    int now_row;
    int buf[12];
    int i;
    int j;
    int num_buf;

    // display_col_size = 80;
    now_row = DISPLAY / DISPLAY_COL_SIZE;

    if (num == 0) {
        *DISPLAY = 48; // '0'
        DISPLAY = DISPLAY + 1;
        return 0;
    }
    i = 0;
    num_buf = num;
    while (num_buf > 0) {
        buf[i] = num_buf % 10 + 48; // 数字を文字に変換
        num_buf = num_buf / 10;
        i = i + 1;
    }

    for (j = i - 1; j >= 0; j=j-1) {
        *DISPLAY = buf[j];
        DISPLAY = DISPLAY + 1;
    }
}

int scan () {
    int keybuf;
    int keydisp;
    int butbuf;
    int prev_matkay;
    int prev_button;
    int buf;
    int count;

    // =0だと、押したまま関数に入ったときに、意図せず押したことになる
    prev_matkay = *MATKAY;
    prev_button = *BUTTON;
    buf = 1;
    count = 0;

    while(buf) {
        keybuf = *MATKAY;
        butbuf = *BUTTON;
        if (((prev_matkay != keybuf) && (keybuf != 0))) {
            // Shiftボタンが押された場合、入力文字を大文字に変換(Shiftは押しっぱなしで入力することを想定)
            keydisp = keybuf;
            if (butbuf == 8) {
                if ((keybuf >= 97) && (keybuf <= 122)) {
                    keydisp = keybuf - 32; // 小文字を大文字に変換
                }
            }
            *DISPLAY = keydisp;
            SCANBUF[count] = keydisp;
            count = count + 1;
            DISPLAY = DISPLAY + 1;
        }
        // Spaceボタンが押された場合、スペースを入力
        if ((butbuf == 4) && (prev_button != butbuf)) {
            *DISPLAY = 32; // スペースのASCIIコード
            SCANBUF[count] = 32;
            count = count + 1;
            DISPLAY = DISPLAY + 1;
        }
        // Backspaceボタンが押された場合、最後の文字を消す
        if ((butbuf == 1) && (prev_button != butbuf)) {
            if (count > 0) {
                count = count - 1;
                DISPLAY = DISPLAY - 1;
                *DISPLAY = 0; // NULL文字で消す
                // SCANBUFの最後の文字も消す
                SCANBUF[count] = 0;
            }
        }
        // Enterボタンが押されたか、または32文字入力されたら終了
        if ((butbuf == 2) && (prev_button != butbuf) || (count >= 32)) {
            buf = 0;
        }
        prev_matkay = keybuf;
        prev_button = butbuf;

    }

    return 0;
}

int clear_screen() {
    int i;
    // int point_buf;
    // point_buf = DISPLAY;
    DISPLAY = 1;
    for (i = 0; i < DISPLAY_ROW_SIZE * DISPLAY_COL_SIZE; i=i+1) {
        *DISPLAY = 0; // NULL文字
        DISPLAY = DISPLAY + 1;
    }
    DISPLAY = 1;
}