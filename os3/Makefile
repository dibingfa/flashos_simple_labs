include Rules.make

OBJECTS = boot/head.o init/main.o debug/debug.o

all: Image

Image: boot/bootsect.bin boot/setup.bin init/main.bin
	@bximage -mode=create -hd=60 -q $(BOCHS_HOME)/os.raw
	@dd if=boot/bootsect.bin of=$(BOCHS_HOME)/os.raw bs=512 count=1
	@dd if=boot/setup.bin of=$(BOCHS_HOME)/os.raw bs=512 count=4 seek=1
	@dd if=init/main.bin of=$(BOCHS_HOME)/os.raw bs=512 count=100 seek=5

######### 三个主文件，启动区(bootsect)、加载器(setup)、内核(main) #########
	
boot/bootsect.bin: boot/bootsect.s
	@echo 正在生成启动区 bootsect.bin
	@nasm -I include/ -o boot/bootsect.bin boot/bootsect.s -l boot/bootsect.lst
	
boot/setup.bin: boot/setup.s
	@echo 正在生成加载器 setup.bin
	@nasm -I include/ -o boot/setup.bin boot/setup.s -l boot/setup.lst

init/main.bin: $(OBJECTS)
	@echo 正在生成内核 main.bin
	@$(LD) $(OBJECTS) -Ttext 0x0 -e startup_32 -o init/main.bin.large
	@objcopy -O binary init/main.bin.large init/main.bin


######### 内核部分的各种目标文件 #########
	
boot/head.o: boot/head.s
	@echo 正在生成内核的头部目标文件 head.o
	@nasm -f elf -I include/ -o boot/head.o boot/head.s -l boot/head.lst

init/main.o: init/main.c
	@echo 正在生成内核目标文件 main.o
	@gcc -c -fno-builtin -I include -o init/main.o init/main.c
	
debug/debug.o:
	@echo 正在生成调试模块 debug
	@cd debug && @make

######### 各种命令 #########

run: Image
	@bochs -f bochsrc.disk -q
	
brun: Image
	@bochsdbg -f bochsrc.disk -q
	
clean:
	@echo 清理工作.....
	@del /q others\bochs\os.raw*
	@cd boot && make clean
	@cd debug && make clean
	@cd init && make clean