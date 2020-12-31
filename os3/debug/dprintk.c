#include <debug.h>
#include <asm/io.h>

#define ORIG_X (*(unsigned char *)0x90000)
#define ORIG_Y (*(unsigned char *)0x90001)

static unsigned int columns_in_bytes = 160;
static unsigned int columns_in_chars = 80;

static unsigned int total_rows = 25;

static unsigned int video_port_reg = 0x3d4;
static unsigned int video_port_val = 0x3d5;

unsigned int x;
unsigned int y;
unsigned int pos;
unsigned int origin;


static inline void set_cursor() {
	outb_p(14, video_port_reg);
	outb_p(0xff & ((pos - origin) >> 9), video_port_val);
	outb_p(15, video_port_reg);
	outb_p(0xff & ((pos - origin) >> 1), video_port_val);
}

/* 向上卷动一行屏幕 */
static void scrup(void) {
	for (int row = 0; row < total_rows; row++) {
		for (int column = 0; column < columns_in_bytes; column += 2) {
			char* from_pos = (char*)(origin + (row + 1) * columns_in_bytes + column);
			char* to_pos = (char*)(origin + row * columns_in_bytes + column);
			if (row == total_rows - 1) {
				*to_pos = ' ';
				*(to_pos+1) = 0x07;
			} else {
				*to_pos = *from_pos;
				*(to_pos+1) = *(from_pos+1);
			}
		}
	}
}

/* 归位行首 */
static void cr(void) {
	pos -= x << 1;
	x = 0;
}

/* 换行 */
static void lf(void) {
	if (y + 1 < total_rows) {
		y++;
		pos += columns_in_bytes;
	} else {
		scrup();
	}
	
}

void gotoxy(int new_x, int new_y) {
	x = new_x;
	y = new_y;
	pos = origin + y * columns_in_bytes + (x << 1);
	set_cursor();
}

void debug_init() {
	origin = 0xb8000;
	columns_in_bytes = 160;
	video_port_reg = 0x3d4;
	video_port_val = 0x3d5;
	gotoxy(0, ORIG_Y+3);
}

void put_char(char c, char color, char* vram) {
	*vram++ = c;
	*vram++ = color;
}

void put_hex(int num, char color, char* vram) {
	put_char('0', color, vram);
	vram += 2;
	put_char('x', color, vram);
	vram += 2;
	put_char('0', color, vram);
	vram += 2;

	int start_not_zero = 0;

	for (int i = 7; i >= 0; i--) {
		int cur_index_num = ((num >> (i * 4)) & 0x0000000f);
		char c;
		if (cur_index_num != 0) {
			start_not_zero = 1;
		}
		if (cur_index_num < 10) {
			c = (char)(cur_index_num)+0x30;
		} else {
			c = (char)(cur_index_num)+0x57;
		}

		if (start_not_zero) {
			put_char(c, color, vram);
			vram += 2;
		}

	}

	put_char(' ', color, vram);
	vram += 2;

	// 刷新光标
	set_cursor();
}

void dprintk(const char* str) {
	char c;
	while ((c = *str++)) {
		// ls换行符 \n
		if (c == 10) {
			cr();
			lf();
			break;
		}
		// cr归位键 \r
		if (c == 13) {
			cr();
			break;
		}
		// 自动换行
		if (x >= columns_in_chars) {
			x -= columns_in_chars;
			pos -= columns_in_bytes;
			lf();
		}
		put_char(c, 0x07, (char*)(pos));
		pos += 2;
		x++;
	}
	// 刷新光标
	set_cursor();
	return;
}

void dprintc(char c) {
	// 自动换行
	if (x >= columns_in_chars) {
		x -= columns_in_chars;
		pos -= columns_in_bytes;
		lf();
	}
	put_char(c, 0x07, (char*)(pos));
	pos += 2;
	x++;
	// 刷新光标
	set_cursor();
	return;
}

void dprint_info(const char* str) {
	char* vram = (char*) origin;
	char c;
	while ((c = *str++)) {
		put_char(c, 0x0e, vram);
		vram += 2;
	}
	return;
}

void dprint_info_hex(int num, int row) {
	char* vram = (char*) origin + (row * columns_in_bytes);
	put_hex(num, 0x0e, vram);
	return;
}

void print_cursor_info() {
	dprint_info_hex(x, 0);
	dprint_info_hex(y, 1);
	dprint_info_hex(pos, 2);
}