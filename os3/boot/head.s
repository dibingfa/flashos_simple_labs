%define stack_start	0x0200

extern _kernel_start

[bits 32]

global startup_32

;ҳĿ¼�� 0x0000
_pg_dir:

startup_32:
	;ת������μĴ���Ϊ����ģʽ�£�ָ��ڶ����������������Ǵ��������������ַΪ0x0000��
	mov eax,0x10
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	;����ϵͳ��ջ
	mov esp,stack_start
	
	;�����жϺ�ȫ����������
	call setup_idt
    call setup_gdt
	
	;��Ϊ�޸���gdt�����������еĶ��޳�8MB�ĳ���16MB�������¼��ضμĴ���
	mov eax,0x10
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov gs,ax
	mov esp,stack_start
	
	;��ʾ�ַ��������˵��/BIOS��
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

; ����Щ��ĵ�ַ��Ϣ��������
; �ڴ��ַ	 ; �ֽ� ; ����			;
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
	
;��1��ҳ��
times 0x1000-($-$$) db 0	
pg0:
;��2��ҳ��
times 0x2000-($-$$) db 0	
pg1:
;��3��ҳ��
times 0x3000-($-$$) db 0	
pg2:
;��4��ҳ��
times 0x4000-($-$$) db 0	
pg3:

times 0x5000-($-$$) db 0	
	
after_page_tables:
	push 0		;main��������envp
	push 0		;main��������argv
	push 0		;main��������argc
	push L6		;���ص�ַ
	push _kernel_start	;main������ڵ�ַ
	jmp setup_paging
L6:
	jmp L6		;main������ʵ���᷵�صģ�Ϊ���Է���һ����������


;���÷�ҳ���ƣ���ʼ��ҳĿ¼��ǰ4���4��ҳ��
setup_paging:
	mov ecx,1024*5
	xor eax,eax
	xor edi,edi
	cld
	
	;��4��ҳĿ¼����д��
	mov dword [_pg_dir],	pg0+7	;��һ��ҳĿ¼��0x00001007�������ʾ��ҳ���ַ0x1000��ҳ�����ҿɶ�д0x07
	mov dword [_pg_dir+4],	pg1+7
	mov dword [_pg_dir+8],	pg2+7
	mov dword [_pg_dir+12],	pg3+7
	
	;����4��ҳ��������������ݣ�4096������һ��ҳ������һ���д
;	mov edi, pg3_mem+4092	;��ʱediֵ��ʾ���һ��ҳ������һ��
;	mov eax, 0xfff007		;16Mb - 4096 + 7(r/w user,p)
;	std	;edi�ݼ���4�ֽڣ�
;cp:	mov dword [edi],eax
;	sub eax,0x1000	;�����ֵַ�ݼ�0x1000
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

	;����ҳĿ¼���ַ�Ĵ���cr3
	xor eax,eax
	mov cr3,eax
	;���÷�ҳ����(cr0��PG��־����31λ)
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
    
    mov eax, 0x10			; ���ö�ѡ���(ʹds��es��fsָ��gdt���е����ݶ�)
    mov ds,ax
    mov es,ax
    mov fs,ax
    ;push int_msg
    ;call printk						# �ú�����kernel/printk.c��
    pop eax
    
    pop fs
    pop es
    pop ds
    pop edx
    pop ecx
    pop eax
    iret							; �жϷ���

;--------------- ���������ݲ��� --------------------

idt_descr:
	dw 256*8-1	;idt����
	dd idt		;idt��ʼ��ַ
	
idt:
	times 256 dq 0	;��δ��ʼ��
	
gdt_descr:
	dw 256*8-1	;gdt����
	dd gdt		;gdt��ʼ��ַ
	
gdt:
    dq 0x0000000000000000	;��
	;�Ǳ���ģʽ�µ���������00000000_11000000_10011010_00000000_00000000_00000000_00001111_11111111
	;�ڱ���ģʽ�µ���������00000000_11000000_10011010_00000000_00000000_00000000_00000111_11111111
    dq 0x00c09a0000000fff	;�ν��ޱ�Ϊ16M
    dq 0x00c0920000000fff	;�ν��ޱ�Ϊ16M
    dq 0x0000000000000000	;��ʱ����
    times 252 dq 0			;���� ldt �� tss










