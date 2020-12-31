%define BOOTSEG 	0x07c0		;BIOS加载启动区到内存的段地址
%define	INITSEG		0x9000		;启动区代码加载自身到内存的段地址
%define	SETUPSEG	0x9020		;setup程序代码的段位置
%define	SETUPLEN 	4			;setup程序加载的扇区数
%define SYSSEG		0x1000		;系统模块被加载到内存的段位置
%define SYSSIZE		0x3000		;内核系统模块的默认最大节数(1节=16bit)
%define ENDSEG		SYSSEG+SYSSIZE

start:				;梦开始的地方
	;将自身(bootsect)从0x7c00移动到0x90000处，共512字节
	mov	ax,BOOTSEG
	mov	ds,ax
	sub	si,si       ; 源地址 ds:si = 0x07c0:0x0000
	mov	ax,INITSEG
	mov	es,ax
	sub	di,di       ; 目标地址 es:di = 0x9000:0x0000
	mov	cx,512		; 512字节
	rep movsb
	;跳转到0x90000处偏移go的位置上继续执行
	jmp INITSEG:(go-start)


go:					;这里已经转移到0x90000处（当然同时已经偏移到go处了）
	;统一各个段
	mov ax,cs	;代码段寄存器拿出来
	mov ds,ax	;数据段寄存器
	mov es,ax	;附加段寄存器
	mov ss,ax	;堆栈段寄存器
	mov dx,0xfef4
	mov sp,dx	;堆栈指针要远大于512字节偏移（0x200），加上setup程序（大约4个扇区0x800），加上堆栈本身的大小
				;此处设置为0x9ff00-12(参数表长度)，即sp = 0xfef4
	

.print_loading:		;卷屏并打印字符串“Loading bootsect success”
	;读光标位置（详见说明/BIOS）
	mov	ah,0x03
	xor	bh,bh
	int	0x10
	;卷屏（详见说明/BIOS）
	mov ax,0x0600
	mov bx,0x0700
	mov cx,0
	mov dx,0x184f
	int 0x10
	;置光标位置为最上面（详见说明/BIOS）
	mov ah,0x02
	mov bh,0
	mov dx,0
	int 0x10
	;显示字符串（详见说明/BIOS）
	mov	ah,0x13
	mov al,0x01
	mov	cx,26
	mov	bx,0x0007
	mov	bp,msg1
	int	0x10


load_setup:			;加载setup模块到0x90200开始处，共读取4个扇区
					;加载setup完毕，原linux代码还会判断如果读取失败的处理流程，这里简化直接按成功处理
	mov eax,0x01	;起始扇区lba地址，LBA=(柱面号*磁头数+磁头号)*扇区数+扇区编号-1
	mov bx,0x200	;写入的内存地址，之后用
	mov cx,SETUPLEN	;待读入的扇区数
	call read_disk
	
load_system:		

	mov	ax,SYSSEG
	mov	ds,ax
	mov eax,0x05	;起始扇区lba地址，LBA=(柱面号*磁头数+磁头号)*扇区数+扇区编号-1
	mov bx,0x000	;写入的内存地址，之后用
	mov cx,384	;待读入的扇区数
	call read_disk

	jmp SETUPSEG:0
	

;----读硬盘方法，eax为lba扇区号，bx为待写入内存地址，cx为读入的扇区数
read_disk:
	mov esi,eax	;备份
	mov di,cx	;备份

;第一步，设置要读取的扇区数
	mov dx,0x1f2
	mov al,cl
	out dx,al
	mov eax,esi	;恢复
	
;第二步，设置LBA地址
	mov cl,8
	;0-7位写入0x1f3
	mov dx,0x1f3
	out dx,al
	;8-15位写入0x1f4
	mov dx,0x1f4
	shr eax,cl
	out dx,al
	;16-23位写入0x1f5
	mov dx,0x1f5
	shr eax,cl
	out dx,al
	;24-27位写入0x1f6
	mov dx,0x1f6
	shr eax,cl
	and al,0x0f	;lba的24-27位
	or al,0xe0	;另外4位为1110，表示lba模式
	out dx,al
	
;第三步，写入读命令
	mov dx,0x1f7
	mov al,0x20
	out dx,al

;第四步，检测硬盘状态
.not_ready:
	nop
	in al,dx
	and al,0x88	;第4位为1表示准备好，第7位为1表示忙
	cmp al,0x08
	jnz .not_ready
	
;第五步，读数据
	mov ax,di
	mov dx,256
	mul dx
	mov cx,ax ;恢复
	
	mov dx,0x1f0
	.go_on_read:
		in ax,dx
		mov [bx],ax
		add bx,2
		loop .go_on_read
		ret
	
msg1:
    db 13,10 ;13的ASCII为CR归位 10的ASCII为LF换行
    dd "Loading bootsect success"

;----512字节的最后两字节是启动区标识
times 510-($-$$) db 0

boot_flag:
	dw 0xaa55
