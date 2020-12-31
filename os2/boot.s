;BIOS把启动区加载到内存的该位置
;所以需设置地址偏移量
section mbr vstart=0x7c00

;卷屏（详见说明/BIOS）
mov ax,0x0600
mov bx,0x0700
mov cx,0
mov dx,0x184f
int 0x10

;直接往显存中写数据
mov ax,0xb800 ;这条就是第一条指令
mov gs,ax
mov byte [gs:0x00],'h'
mov byte [gs:0x02],'e'
mov byte [gs:0x04],'l'
mov byte [gs:0x06],'l'
mov byte [gs:0x08],'o'
mov byte [gs:0x0a],' '
mov byte [gs:0x0c],'w'
mov byte [gs:0x0e],'o'
mov byte [gs:0x10],'r'
mov byte [gs:0x12],'l'
mov byte [gs:0x14],'d'

jmp $

;512字节的最后两字节是启动区标识
times 510-($-$$) db 0
db 0x55,0xaa