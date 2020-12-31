%define stack_start	0x0200

extern _kernel_start

[bits 32]

global startup_32

;页目录表 0x0000
_pg_dir:

startup_32:
	;转变各个段寄存器为保护模式下，指向第二个段描述符，就是代码段描述符（基址为0x0000）
	mov eax,0x10
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	;设置系统堆栈
	mov esp,stack_start
	
	;设置中断和全局描述符表
	call setup_idt
    call setup_gdt
	
	;因为修改了gdt（段描述符中的段限长8MB改成了16MB），重新加载段寄存器
	mov eax,0x10
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	mov esp,stack_start
	
	;显示字符串（详见说明/BIOS）
	mov byte [gs:0xb81e0],'l'
	mov byte [gs:0xb81e2],'o'
	mov byte [gs:0xb81e4],'a'
	mov byte [gs:0xb81e6],'d'
	mov byte [gs:0xb81e8],'i'
	mov byte [gs:0xb81ea],'n'
	mov byte [gs:0xb81ec],'g'
	mov byte [gs:0xb81ee],' '
	mov byte [gs:0xb81f0],'h'
	mov byte [gs:0xb81f2],'e'
	mov byte [gs:0xb81f4],'a'
	mov byte [gs:0xb81f6],'d'
	mov byte [gs:0xb81f8],''
	mov byte [gs:0xb81fa],'s'
	mov byte [gs:0xb81fc],'u'
	mov byte [gs:0xb81fe],'c'
	mov byte [gs:0xb8200],'c'
	mov byte [gs:0xb8202],'e'
	mov byte [gs:0xb8204],'s'
	mov byte [gs:0xb8206],'s'

; 将这些表的地址信息保存起来
; 内存地址	 ; 字节 ; 内容			;
; 0x91000	; 4	;    gdt
; 0x90004	; 4	;	 idt 		 
; 0x90008	; 4	;	 pg_dir			;

	mov dword [0x91000], gdt
	mov dword [0x91004], idt
	mov dword [0x91008], _pg_dir
	
	jmp after_page_tables
		
setup_idt:
	lea edx,ignore_int
	or eax, 0x00080000
	mov ax,dx
	mov dx,0x8E00
	lea edi,idt
	mov ecx,256
rp_sidt:
	mov [edi],eax
	mov 4[edi],edx
	add edi,8
	dec ecx
	jne rp_sidt
	lidt [idt_descr]
	ret
	
setup_gdt:
	lgdt [gdt_descr]
	ret
	
;第1个页表
times 0x1000-($-$$) db 0	
pg0:
;第2个页表
times 0x2000-($-$$) db 0	
pg1:
;第3个页表
times 0x3000-($-$$) db 0	
pg2:
;第4个页表
times 0x4000-($-$$) db 0	
pg3:

times 0x5000-($-$$) db 0	
	
after_page_tables:
	push 0		;main函数参数envp
	push 0		;main函数参数argv
	push 0		;main函数参数argc
	push L6		;返回地址
	push _kernel_start	;main函数入口地址
	jmp setup_paging
L6:
	jmp L6		;main函数其实不会返回的，为了以防万一做这样的事


;启用分页机制，初始化页目录表前4项和4个页表
setup_paging:
	mov ecx,1024*5
	xor eax,eax
	xor edi,edi
	cld
	
	;将4个页目录项填写好
	mov dword [_pg_dir],	pg0+7	;第一个页目录项0x00001007解析后表示，页表地址0x1000，页存在且可读写0x07
	mov dword [_pg_dir+4],	pg1+7
	mov dword [_pg_dir+8],	pg2+7
	mov dword [_pg_dir+12],	pg3+7
	
	;设置4个页表中所有项的内容（4096项）从最后一个页表的最后一项倒着写
;	mov edi, pg3_mem+4092	;此时edi值表示最后一个页表的最后一项
;	mov eax, 0xfff007		;16Mb - 4096 + 7(r/w user,p)
;	std	;edi递减（4字节）
;cp:	mov dword [edi],eax
;	sub eax,0x1000	;物理地址值递减0x1000
;	jge cp
;	cld
	

	;mov ecx, (pg3_mem+4092)/4
	mov ecx, 1000
	mov edi, pg3+4092
	mov eax, 0xfff007
	mov dword [edi],eax
cp: sub eax,0x1000
	sub edi,4
	mov dword [edi],eax
	cmp eax,0x007
	jne cp

	;设置页目录表基址寄存器cr3
	xor eax,eax
	mov cr3,eax
	;启用分页机制(cr0的PG标志，在31位)
	mov eax,cr0
	or eax,0x80000000
	mov cr0,eax
	
	ret
	
int_msg:
    dd "Unknown interrupt\n\r"

align 4
ignore_int:
    push eax
    push ecx
    push edx
    push ds
    push es
    push fs
    
    mov eax, 0x10			; 设置段选择符(使ds，es，fs指向gdt表中的数据段)
    mov ds,ax
    mov es,ax
    mov fs,ax
    ;push int_msg
    ;call printk						# 该函数在kernel/printk.c中
    pop eax
    
    pop fs
    pop es
    pop ds
    pop edx
    pop ecx
    pop eax
    iret							; 中断返回

;--------------- 以下是数据部分 --------------------

idt_descr:
	dw 256*8-1	;idt界限
	dd idt		;idt起始地址
	
idt:
	times 256 dq 0	;暂未初始化
	
gdt_descr:
	dw 256*8-1	;gdt界限
	dd gdt		;gdt起始地址
	
gdt:
    dq 0x0000000000000000	;无
	;非保护模式下的描述符：00000000_11000000_10011010_00000000_00000000_00000000_00001111_11111111
	;在保护模式下的描述符：00000000_11000000_10011010_00000000_00000000_00000000_00000111_11111111
    dq 0x00c09a0000000fff	;段界限变为16M
    dq 0x00c0920000000fff	;段界限变为16M
    dq 0x0000000000000000	;暂时不用
    times 252 dq 0			;留给 ldt 和 tss










