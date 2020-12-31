include ../Rules.make

all: debug.o

OBJECTS = dprintk.o

debug.o: $(OBJECTS)
	@ld -r -o debug.o $(OBJECTS)

dprintk.o: dprintk.c
	@echo [debug的子模块] 正在生成打印工具 dprintk.o
	@gcc -c -fno-builtin -I ../include -o dprintk.o dprintk.c

clean:
	del /q *.lst
	del /q *.bin
	del /q *.o
	del /q *.bin.large