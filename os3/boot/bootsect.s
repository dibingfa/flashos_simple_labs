%define BOOTSEG 	0x07c0		;BIOS�������������ڴ�Ķε�ַ
%define	INITSEG		0x9000		;������������������ڴ�Ķε�ַ
%define	SETUPSEG	0x9020		;setup�������Ķ�λ��
%define	SETUPLEN 	4			;setup������ص�������
%define SYSSEG		0x1000		;ϵͳģ�鱻���ص��ڴ�Ķ�λ��
%define SYSSIZE		0x3000		;�ں�ϵͳģ���Ĭ��������(1��=16bit)
%define ENDSEG		SYSSEG+SYSSIZE

start:				;�ο�ʼ�ĵط�
	;������(bootsect)��0x7c00�ƶ���0x90000������512�ֽ�
	mov	ax,BOOTSEG
	mov	ds,ax
	sub	si,si       ; Դ��ַ ds:si = 0x07c0:0x0000
	mov	ax,INITSEG
	mov	es,ax
	sub	di,di       ; Ŀ���ַ es:di = 0x9000:0x0000
	mov	cx,512		; 512�ֽ�
	rep movsb
	;��ת��0x90000��ƫ��go��λ���ϼ���ִ��
	jmp INITSEG:(go-start)


go:					;�����Ѿ�ת�Ƶ�0x90000������Ȼͬʱ�Ѿ�ƫ�Ƶ�go���ˣ�
	;ͳһ������
	mov ax,cs	;����μĴ����ó���
	mov ds,ax	;���ݶμĴ���
	mov es,ax	;���ӶμĴ���
	mov ss,ax	;��ջ�μĴ���
	mov dx,0xfef4
	mov sp,dx	;��ջָ��ҪԶ����512�ֽ�ƫ�ƣ�0x200��������setup���򣨴�Լ4������0x800�������϶�ջ����Ĵ�С
				;�˴�����Ϊ0x9ff00-12(��������)����sp = 0xfef4
	

.print_loading:		;��������ӡ�ַ�����Loading bootsect success��
	;�����λ�ã����˵��/BIOS��
	mov	ah,0x03
	xor	bh,bh
	int	0x10
	;���������˵��/BIOS��
	mov ax,0x0600
	mov bx,0x0700
	mov cx,0
	mov dx,0x184f
	int 0x10
	;�ù��λ��Ϊ�����棨���˵��/BIOS��
	mov ah,0x02
	mov bh,0
	mov dx,0
	int 0x10
	;��ʾ�ַ��������˵��/BIOS��
	mov	ah,0x13
	mov al,0x01
	mov	cx,26
	mov	bx,0x0007
	mov	bp,msg1
	int	0x10


load_setup:			;����setupģ�鵽0x90200��ʼ��������ȡ4������
					;����setup��ϣ�ԭlinux���뻹���ж������ȡʧ�ܵĴ������̣������ֱ�Ӱ��ɹ�����
	mov eax,0x01	;��ʼ����lba��ַ��LBA=(�����*��ͷ��+��ͷ��)*������+�������-1
	mov bx,0x200	;д����ڴ��ַ��֮����
	mov cx,SETUPLEN	;�������������
	call read_disk
	
load_system:		

	mov	ax,SYSSEG
	mov	ds,ax
	mov eax,0x05	;��ʼ����lba��ַ��LBA=(�����*��ͷ��+��ͷ��)*������+�������-1
	mov bx,0x000	;д����ڴ��ַ��֮����
	mov cx,384	;�������������
	call read_disk

	jmp SETUPSEG:0
	

;----��Ӳ�̷�����eaxΪlba�����ţ�bxΪ��д���ڴ��ַ��cxΪ�����������
read_disk:
	mov esi,eax	;����
	mov di,cx	;����

;��һ��������Ҫ��ȡ��������
	mov dx,0x1f2
	mov al,cl
	out dx,al
	mov eax,esi	;�ָ�
	
;�ڶ���������LBA��ַ
	mov cl,8
	;0-7λд��0x1f3
	mov dx,0x1f3
	out dx,al
	;8-15λд��0x1f4
	mov dx,0x1f4
	shr eax,cl
	out dx,al
	;16-23λд��0x1f5
	mov dx,0x1f5
	shr eax,cl
	out dx,al
	;24-27λд��0x1f6
	mov dx,0x1f6
	shr eax,cl
	and al,0x0f	;lba��24-27λ
	or al,0xe0	;����4λΪ1110����ʾlbaģʽ
	out dx,al
	
;��������д�������
	mov dx,0x1f7
	mov al,0x20
	out dx,al

;���Ĳ������Ӳ��״̬
.not_ready:
	nop
	in al,dx
	and al,0x88	;��4λΪ1��ʾ׼���ã���7λΪ1��ʾæ
	cmp al,0x08
	jnz .not_ready
	
;���岽��������
	mov ax,di
	mov dx,256
	mul dx
	mov cx,ax ;�ָ�
	
	mov dx,0x1f0
	.go_on_read:
		in ax,dx
		mov [bx],ax
		add bx,2
		loop .go_on_read
		ret
	
msg1:
    db 13,10 ;13��ASCIIΪCR��λ 10��ASCIIΪLF����
    dd "Loading bootsect success"

;----512�ֽڵ�������ֽ�����������ʶ
times 510-($-$$) db 0

boot_flag:
	dw 0xaa55
