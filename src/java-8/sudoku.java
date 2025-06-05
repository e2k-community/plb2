import java.io.*;

class sudoku {
	int[][] R, C;
	public void genmat() {
		R = new int[324][9];
		C = new int[729][4];
		int[] nr = new int[324];
		int i, j, k, r, c, c2, r2;
		for (i = r = 0; i < 9; ++i) // generate c[729][4]
			for (j = 0; j < 9; ++j)
				for (k = 0; k < 9; ++k) { // this "9" means each cell has 9 possible numbers
					C[r][0] = 9 * i + j;                  // row-column constraint
					C[r][1] = (i/3*3 + j/3) * 9 + k + 81; // box-number constraint
					C[r][2] = 9 * i + k + 162;            // row-number constraint
					C[r][3] = 9 * j + k + 243;            // col-number constraint
					++r;
				}
		for (c = 0; c < 324; ++c) nr[c] = 0;
		for (r = 0; r < 729; ++r) // generate r[][] from c[][]
			for (c2 = 0; c2 < 4; ++c2) {
				k = C[r][c2]; R[k][nr[k]++] = r;
			}
	}
	private int sd_update(int[] sr, int[] sc, int r, int v) {
		int c2, min = 10, min_c = 0;
		for (c2 = 0; c2 < 4; ++c2) sc[C[r][c2]] += v<<7;
		for (c2 = 0; c2 < 4; ++c2) { // update # available choices
			int r2, rr, cc2, c = C[r][c2];
			if (v > 0) { // move forward
				for (r2 = 0; r2 < 9; ++r2) {
					if (sr[rr = R[c][r2]]++ != 0) continue; // update the row status
					for (cc2 = 0; cc2 < 4; ++cc2) {
						int cc = C[rr][cc2];
						if (--sc[cc] < min) { // update # allowed choices
							min = sc[cc]; min_c = cc; // register the minimum number
						}
					}
				}
			} else { // revert
				int[] p;
				for (r2 = 0; r2 < 9; ++r2) {
					if (--sr[rr = R[c][r2]] != 0) continue; // update the row status
					p = C[rr]; ++sc[p[0]]; ++sc[p[1]]; ++sc[p[2]]; ++sc[p[3]]; // update the count array
				}
			}
		}
		return min<<16 | min_c; // return the col that has been modified and with the minimal available choices
	}
	// solve a Sudoku; _s is the standard dot/number representation
	public int solve(String _s) {
		int i, j, r, c, r2, dir, cand, n = 0, min, hints = 0; // dir=1: forward; dir=-1: backtrack
		int[] sr = new int[729];
		int[] cr = new int[81];
		int[] sc = new int[324];
		int[] cc = new int[81];
		int[] out = new int[81];
		for (r = 0; r < 729; ++r) sr[r] = 0; // no row is forbidden
		for (c = 0; c < 324; ++c) sc[c] = 0<<7|9; // 9 allowed choices; no constraint has been used
		for (i = 0; i < 81; ++i) {
			int a = _s.charAt(i) >= '1' && _s.charAt(i) <= '9'? _s.codePointAt(i) - '1' : -1; // number from -1 to 8
			if (a >= 0) sd_update(sr, sc, i * 9 + a, 1); // set the choice
			if (a >= 0) ++hints; // count the number of hints
			cr[i] = cc[i] = -1; out[i] = a;
		}
		i = 0; dir = 1; cand = 10<<16|0;
		for (;;) {
			while (i >= 0 && i < 81 - hints) { // maximum 81-hints steps
				if (dir == 1) {
					min = cand>>16; cc[i] = cand&0xffff;
					if (min > 1) {
						for (c = 0; c < 324; ++c) {
							if (sc[c] < min) {
								min = sc[c]; cc[i] = c; // choose the top constraint
								if (min <= 1) break; // this is for acceleration; slower without this line
							}
						}
					}
					if (min == 0 || min == 10) cr[i--] = dir = -1; // backtrack
				}
				c = cc[i];
				if (dir == -1 && cr[i] >= 0) sd_update(sr, sc, R[c][cr[i]], -1); // revert the choice
				for (r2 = cr[i] + 1; r2 < 9; ++r2) // search for the choice to make
					if (sr[R[c][r2]] == 0) break; // found if the state equals 0
				if (r2 < 9) {
					cand = sd_update(sr, sc, R[c][r2], 1); // set the choice
					cr[i++] = r2; dir = 1; // moving forward
				} else cr[i--] = dir = -1; // backtrack
			}
			if (i < 0) break;
			char[] y = new char[81];
			for (j = 0; j < 81; ++j) y[j] = (char)(out[j] + '1');
			for (j = 0; j < i; ++j) { r = R[cc[j]][cr[j]]; y[r/9] = (char)(r%9 + '1'); }
			System.out.println(new String(y));
			++n; --i; dir = -1; // backtrack
		}
		return n;
	}
	public static void main(String[] args) throws Exception {
		String[] hard20 = {
			"..............3.85..1.2.......5.7.....4...1...9.......5......73..2.1........4...9",
			".......12........3..23..4....18....5.6..7.8.......9.....85.....9...4.5..47...6...",
			".2..5.7..4..1....68....3...2....8..3.4..2.5.....6...1...2.9.....9......57.4...9..",
			"........3..1..56...9..4..7......9.5.7.......8.5.4.2....8..2..9...35..1..6........",
			"12.3....435....1....4........54..2..6...7.........8.9...31..5.......9.7.....6...8",
			"1.......2.9.4...5...6...7...5.9.3.......7.......85..4.7.....6...3...9.8...2.....1",
			".......39.....1..5..3.5.8....8.9...6.7...2...1..4.......9.8..5..2....6..4..7.....",
			"12.3.....4.....3....3.5......42..5......8...9.6...5.7...15..2......9..6......7..8",
			"..3..6.8....1..2......7...4..9..8.6..3..4...1.7.2.....3....5.....5...6..98.....5.",
			"1.......9..67...2..8....4......75.3...5..2....6.3......9....8..6...4...1..25...6.",
			"..9...4...7.3...2.8...6...71..8....6....1..7.....56...3....5..1.4.....9...2...7..",
			"....9..5..1.....3...23..7....45...7.8.....2.......64...9..1.....8..6......54....7",
			"4...3.......6..8..........1....5..9..8....6...7.2........1.27..5.3....4.9........",
			"7.8...3.....2.1...5.........4.....263...8.......1...9..9.6....4....7.5...........",
			"3.7.4...........918........4.....7.....16.......25..........38..9....5...2.6.....",
			"........8..3...4...9..2..6.....79.......612...6.5.2.7...8...5...1.....2.4.5.....3",
			".......1.4.........2...........5.4.7..8...3....1.9....3..4..2...5.1........8.6...",
			".......12....35......6...7.7.....3.....4..8..1...........12.....8.....4..5....6..",
			"1.......2.9.4...5...6...7...5.3.4.......6........58.4...2...6...3...9.8.7.......1",
			".....1.2.3...4.5.....6....7..2.....1.8..9..3.4.....8..5....2....9..3.4....67....."
		};
		sudoku a = new sudoku();
		a.genmat();
		int n = 200;
		for (int i = 0; i < n; ++i) {
			for (int j = 0; j < hard20.length; ++j) {
				if (hard20[j].length() >= 81) {
					a.solve(hard20[j]);
					System.out.println();
				}
			}
		}
	}
}
