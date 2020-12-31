#include <debug.h>
#include <asm/system.h>

// 为了证明确实执行到此处特意设置的无效值
static long count = 0;

static char buf[40*80];

int kernel_start() {

	debug_init();
	dprintk("debug init finish\n");

	sti();


	// 系统怠速
	for (;;) {
		count++;
	}
}

