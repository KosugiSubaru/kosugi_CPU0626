#include <stdio.h>

#define BOARD_SIZE 8

// マスの状態を表す定数定義
enum CellState {
    EMPTY = 0,
    BLACK = 1,
    WHITE = -1
};

// 盤面を管理するデータ構造
typedef struct {
    int grid[BOARD_SIZE][BOARD_SIZE];
} Board;

/*
 * @brief 盤面をゲーム開始時の状態に初期化する
 * @param b 初期化対象の盤面構造体へのポインタ
 */

void initialize_board(Board *b) {
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            b->grid[i][j] = EMPTY;
        }
    }
    // 中央の初期配置 (黒・白が交差するように配置)
    b->grid[3][3] = WHITE;
    b->grid[3][4] = BLACK;
    b->grid[4][3] = BLACK;
    b->grid[4][4] = WHITE;
}

/*
 * @brief 現在の盤面を標準出力にレンダリングする
 * @param b 描画対象の盤面構造体へのポインタ
 */

void print_board(const Board *b) {
    // 列インデックスの表示
    printf("  0 1 2 3 4 5 6 7\n");

    for (int i = 0; i < BOARD_SIZE; i++) {
        // 行インデックスの表示
        printf("%d ", i);

        for (int j = 0; j < BOARD_SIZE; j++) {
            if (b->grid[i][j] == BLACK) {
                printf("X "); // 黒石を 'X' で表現
            } else if (b->grid[i][j] == WHITE) {
                printf("O "); // 白石を 'O' で表現
            } else {
                printf(". "); // 空マスを '.' で表現
            }
        }
        printf("\n");
    }
    printf("\n");
}

// 8方向のベクトル定義（行変化量 DX, 列変化量 DY）
// インデックス 0から7 で8方向すべてを網羅
static const int DX[8] = {-1,  1,  0,  0, -1, -1,  1,  1};
static const int DY[8] = { 0,  0, -1,  1, -1,  1, -1,  1};

/**
 * @brief 指定された座標が盤面の有効範囲内(0〜7)にあるか検証する
 * @return 1: 有効範囲内, 0: 範囲外
 */
int is_on_board(int x, int y) {
    return (x >= 0 && x < BOARD_SIZE && y >= 0 && y < BOARD_SIZE);
}

/*
 * @brief 指定座標に石を置いた際の合法手判定および反転処理
 *
 * @param b 盤面構造体へのポインタ
 * @param x 配置するマスの行番号 (0-7)
 * @param y 配置するマスの列番号 (0-7)
 * @param player 現在のプレイヤー (BLACK=1, WHITE=-1)
 * @param do_flip 1: 実際に盤面を更新(反転)する, 0: 判定のみ(盤面は変更しない)
 * @return int 反転できた（または反転できる）石の総数。0の場合は不適合（着手不可）
 */
int check_and_flip(Board *b, int x, int y, int player, int do_flip) {
    // 既に石がある場所には置けない
    if (b->grid[x][y] != EMPTY) {
        return 0;
    }

    int total_flipped = 0;
    int opponent = -player; // 黒(1)の相手は白(-1)、白(-1)の相手は黒(1)

    // 8方向を順次走査
    for (int dir = 0; dir < 8; dir++) {
        int nx = x + DX[dir];
        int ny = y + DY[dir];
        int count = 0;

        // 1. 隣から相手の石が連続している間、直進する
        while (is_on_board(nx, ny) && b->grid[nx][ny] == opponent) {
            nx += DX[dir];
            ny += DY[dir];
            count++;
        }

        // 2. 相手の石が1枚以上連続し、かつ突き当たったマスが自分の石かチェック
        if (count > 0 && is_on_board(nx, ny) && b->grid[nx][ny] == player) {
            // この方向で挟むことに成功
            total_flipped += count;

            // do_flipフラグが真の場合、実際に石を裏返す
            if (do_flip) {
                int fx = x + DX[dir];
                int fy = y + DY[dir];
                // 突き当たった(nx, ny)の手前まで戻りながら反転
                while (fx != nx || fy != ny) {
                    b->grid[fx][fy] = player;
                    fx += DX[dir];
                    fy += DY[dir];
                }
            }
        }
    }

    // 1枚以上反転可能で、かつ更新フラグが立っていれば、着手マス自体にも自分の石を配置
    if (total_flipped > 0 && do_flip) {
        b->grid[x][y] = player;
    }

    return total_flipped; // 反転した総数を返す（0なら着手不可能を意味する）
}

/*
 * @brief 指定されたプレイヤーに有効な着手（合法手）が1つ以上存在するか検査する
 * @param b 盤面構造体へのポインタ
 * @param player 検査対象のプレイヤー (BLACK=1, WHITE=-1)
 * @return int 1: 合法手が存在する（着手可能）, 0: 合法手が存在しない（パスが必要）
 */
int has_valid_move(Board *b, int player) {
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            // do_flip = 0 (シミュレーションモード) で反転可能数が1以上かチェック
            if (check_and_flip(b, i, j, player, 0) > 0) {
                return 1; // 1箇所でも置ける場所があれば即座に真を返す
            }
        }
    }
    return 0; // 全マス走査して置ける場所がなければ偽
}

/*
 * @brief ゲーム終了時に盤面の石数をカウントし、最終結果を表示する
 * @param b 盤面構造体へのポインタ
 */
void count_and_print_result(const Board *b) {
    int black_count = 0;
    int white_count = 0;

    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            if (b->grid[i][j] == BLACK) black_count++;
            else if (b->grid[i][j] == WHITE) white_count++;
        }
    }

    printf("=== GAME OVER ===\n");
    printf("Final Score:\n");
    printf("BLACK (X): %d\n", black_count);
    printf("WHITE (O): %d\n\n", white_count);

    if (black_count > white_count) {
        printf("Result: BLACK (X) Wins!\n");
    } else if (white_count > black_count) {
        printf("Result: WHITE (O) Wins!\n");
    } else {
        printf("Result: Draw (Tie Game).\n");
    }
}

// 位置特性評価マップ (Positional Weight Matrix)
// 4隅（角）を最大値とし、角を奪われるリスクのあるX打ち（1,1など）やC打ち（0,1など）を負の値として定義。
// 符号付き整数型 (int) で表現。
static const int EVAL_MAP[BOARD_SIZE][BOARD_SIZE] = {
    {  30, -12,   0,  -1,  -1,   0, -12,  30},
    { -12, -15,  -3,  -3,  -3,  -3, -15, -12},
    {   0,  -3,   0,  -1,  -1,   0,  -3,   0},
    {  -1,  -3,  -1,  -1,  -1,  -1,  -3,  -1},
    {  -1,  -3,  -1,  -1,  -1,  -1,  -3,  -1},
    {   0,  -3,   0,  -1,  -1,   0,  -3,   0},
    { -12, -15,  -3,  -3,  -3,  -3, -15, -12},
    {  30, -12,   0,  -1,  -1,   0, -12,  30}
};

/*
 * @brief 局面の静的評価値を算出する関数
 * @param b 盤面構造体へのポインタ
 * @param player 評価の基準となるプレイヤー (WHITE=-1 を基準とする)
 * @return int 評価スコア（高いほどplayerにとって有利）
 */
int evaluate_board(const Board *b, int player) {
    int score = 0;
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            if (b->grid[i][j] == player) {
                score += EVAL_MAP[i][j];
            } else if (b->grid[i][j] == -player) {
                score -= EVAL_MAP[i][j];
            }
        }
    }
    return score;
}

/*
 * @brief 1手読み(1-ply)によって最適な着手を決定するAIエンジン
 * @param b 現在の盤面構造体へのポインタ
 * @param player AIのプレイヤー識別子 (WHITE)
 * @param out_x 最善手の行インデックスを出力するポインタ
 * @param out_y 最善手の列インデックスを出力するポインタ
 */
void think_ai_move(const Board *b, int player, int *out_x, int *out_y) {
    int max_score = -999999; // 評価値の下限初期化
    int best_x = -1;
    int best_y = -1;

    // 全マスを走査し、合法手を検出
    for (int i = 0; i < BOARD_SIZE; i++) {
        for (int j = 0; j < BOARD_SIZE; j++) {
            // シミュレーションモード (do_flip=0) で着手可能か判定
            Board temp_board = *b; // 盤面状態をスタックにコピー（非破壊シミュレーション）

            if (check_and_flip(&temp_board, i, j, player, 0) > 0) {
                // 実際に仮配置・反転を行う (do_flip=1)
                check_and_flip(&temp_board, i, j, player, 1);

                // 遷移後の盤面を評価
                int current_score = evaluate_board(&temp_board, player);

                // 最大値更新（Greedy法による最大化選択）
                if (current_score > max_score) {
                    max_score = current_score;
                    best_x = i;
                    best_y = j;
                }
            }
        }
    }

    *out_x = best_x;
    *out_y = best_y;
}

int main(void) {
Board board;
    initialize_board(&board);

    int current_player = BLACK;
    int consecutive_passes = 0;

    printf("--- Othello Simulator: Human (BLACK) vs AI (WHITE) ---\n\n");

    while (consecutive_passes < 2) {
        print_board(&board);
        printf("Current Turn: %s\n", (current_player == BLACK) ? "BLACK (X)" : "WHITE (O)");

        if (!has_valid_move(&board, current_player)) {
            printf("No valid moves. Player %s PASSES.\n\n",
                   (current_player == BLACK) ? "BLACK (X)" : "WHITE (O)");
            consecutive_passes++;
            current_player = -current_player;
        } else {
            consecutive_passes = 0;

            int x = -1, y = -1;
            int move_made = 0;

            if (current_player == BLACK) {
                // 人間プレイヤーの入力処理
                printf("Enter your move (row[0-7] col[0-7]): ");
                if (scanf("%d %d", &x, &y) != 2) {
                    while (getchar() != '\n');
                    printf("Invalid input format. Use 'row col'.\n\n");
                } else if (check_and_flip(&board, x, y, current_player, 1) == 0) {
                    printf("Invalid move! Position (%d, %d) is illegal.\n\n", x, y);
                } else {
                    move_made = 1;
                }
            } else {
                // AIプレイヤーの思考・着手処理
                printf("AI is evaluating positions...\n");
                think_ai_move(&board, current_player, &x, &y);

                // AIが決定した合法手を実行
                check_and_flip(&board, x, y, current_player, 1);
                printf("AI placed a piece at: row %d, col %d\n\n", x, y);
                move_made = 1;
            }

            if (move_made) {
                current_player = -current_player;
            }
        }
    }

    print_board(&board);
    count_and_print_result(&board);

    return 0;
}
