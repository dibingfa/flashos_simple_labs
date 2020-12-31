%define	INITSEG		0x9000		;启动区代码加载自身到内存的段地址
%define	SETUPSEG	0x9020		;setup程序代码的段位置
%define SYSSEG		0x1000		;系统模块被加载到内存的段位置

start:
	mov ax,SETUPSEG
	mov ds,ax
	mov es,ax
	;显示字符串（详见说明/BIOS）
	mov ah,3h	;获取光标位置
	mov bh,0
	int 0x10
	mov	ah,13h	;打印字符串
	mov al,1
	mov	cx,23
	mov	bx,0x0007
	mov	bp,loading_setup_msg
	int	0x10
	
;;;;; 1.获取系统初始化所需要的参数 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 内存地址	 ; 字节 ; 内容				 ;
; 0x90000	; 2	;   光标位置			;
; 0x90002	; 2	;	扩展内存大小 		 ;
; 0x90004	; 2	;	显示页面			;
; 0x90006	; 1 ;	显示模式			;
; 0x90007	; 1 ;	字符列数			;
; 0x90008	; 2	;	??				   ;
; 0x9000A	; 1	;	安装的显示内存		 ;
; 0x9000B	; 1	;	显示状态(彩色/单色)	 ;
; 0x9000C	; 2	;	显示卡特性参数		 ;
; 0x9000E	; 1	;	屏幕当前行值		 ;
; 0x9000F	; 1	;	屏幕当前列值		 ;
; ...								   ;
; 0x90080	; 16;	第1个硬盘的参数表	  ;
; 0x90090	; 16;	第2个硬盘的参数表	  ;
; 0x901FC	; 2 ;	根文件系统所在的设备号（bootsec.s中设置）;

mov ax,INITSEG
mov ds,ax
mov es,ax

mov ah,0x88
int 0x15
mov [2],ax	;取从0x100000（1M）处开始的扩展内存大小（KB）

mov ah,0x12
mov bl,0x10
int 0x10
mov [0x8],ax
mov [0xa],bx
mov [0xc],cx

mov ah,80	;预设显卡行列值 80 列
mov al,25	;预设显卡行列值 25 行

;;; 获取光标位置
mov	ah,0x03
xor	bh,bh
int	0x10
mov	[0],dx

;准备开始进入保护模式！
cli

	mov ax,0x0000
	cld
do_move:
	mov es,ax	;目标地址 es:di
	add ax,0x1000
	cmp ax,0x9000
	jz end_move
	mov ds,ax	;源地址 ds:si
	sub di,di
	sub si,si
	mov cx,0x8000	;复制的字节数
	rep movsw
	jmp do_move
	
end_move:
	mov ax,SETUPSEG
	mov ds,ax
	lidt [idt_48]	;加载IDT寄存器
	lgdt [gdt_48]	;加载GDT寄存器
	
;打开A20地址线
	mov al,0xD1
	out 0x64,al
	mov al,0xDF
	out 0x60,al
	
; 希望以上一切正常。现在我们必须重新对中断进行编程 :-(
; 我们将它们放在正好处于intel保留的硬件中断后面，在int 0x20 - 0x2F。
; 在那里它们不会引起冲突。不幸的是IBM在原PC机中搞糟了，以后也没有纠正过来。
; PC机的BIOS将中断放在了0x08-0x0f，这些中断也被用于内部硬件中断。
; 所以我们就必须重新对8259中断控制器进行编程，这一点都没意思。
;对8259A重新变成，无聊
	mov	al,0x11		; initialization sequence
	out	0x20,al		; send it to 8259A-1
	dw	0x00eb,0x00eb		; jmp $+2, jmp $+2 	; $ 表示当前指令的地址，
	out	0xA0,al		; and to 8259A-2
	dw	0x00eb,0x00eb
	mov	al,0x20		; start of hardware int's (0x20)
	out	0x21,al
	dw	0x00eb,0x00eb
	mov	al,0x28		; start of hardware int's 2 (0x28)
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0x04		; 8259-1 is master
	out	0x21,al
	dw	0x00eb,0x00eb
	mov	al,0x02		; 8259-2 is slave
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0x01		; 8086 mode for both
	out	0x21,al
	dw	0x00eb,0x00eb
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0xFF		; mask off all interrupts for now
	out	0x21,al
	dw	0x00eb,0x00eb
	out	0xA1,al

;开启保护模式
	mov ax,0x0001
	lmsw ax	;加载机器状态字，效果就是把cro的位0置为1开启了保护模式
	jmp 8:0
	;jmp $
	
;-----------以下是数据方面的信息--------------
;屏幕显示的字符串
loading_setup_msg:
    db 13,10 ;13的ASCII为CR归位 10的ASCII为LF换行
    dd "Loading setup success"
	
;全局描述符表
;段描述符各位的含义
;[63 62 61 60 59 58 57 56]段基址31-24 
;[55]段界限粒度 [54]16位or32位 [53]是否是64位 [52]没用 [51 50 49 48]段界限19-16
;[47]是否在内存 [46 45]特权级 [44]是否为系统段 [43 42 41 40]非系统段则继续分代码段、数据段
;[39 38 37 36 35 34 33 32]段基址23-16
;[31-16]段基址15-0
;[15-0]段界限15-0
;0-7
gdt:
	; ------- 第一个描述符不用 -------
	dw	0,0,0,0	
	; ------- 第二个描述符（表示代码段）-------
	;2进制表示为 00000000_11000000_10011010_00000000_00000000_00000000_00000111_11111111
	;段基址为0: 00000000_00000000_00000000_00000000
	;段界限为8M(0x7FF+1)*4K：0000_00000111_11111111
	;段类型是可读可执行的代码段：0x9A
	dw	0x07FF,0x0000,0x9A00,0x00C0
	; ------- 第三个描述符（表示数据段）-------
	;2进制表示为 00000000_11000000_10010010_00000000_00000000_00000000_00000111_11111111
	;段基址为0: 00000000_00000000_00000000_00000000
	;段界限为8M(0x7FF+1)*4K：0000_00000111_11111111	
	;段类型是可读可写的数据段：0x92
	dw	0x07FF,0x0000,0x9200,0x00C0
	
idt_48:
	dw	0			;idt限长
	dw	0,0			;idt表在线性地址空间中的32位基址
	
gdt_48:
	dw	0x800		;gdt限长2k
	dw	512+gdt,0x9	;线性地址空间基址：0x90200+gdt



	
	
	
	
	
	
	
	
	
	
	
	
	
	