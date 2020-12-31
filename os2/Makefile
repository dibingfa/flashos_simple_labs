os.raw: boot.bin
	bximage -mode=create -hd=60 -q os.raw
	dd if=boot.bin of=os.raw bs=512 count=1
	
boot.bin: boot.s
	nasm -o boot.bin boot.s
	
run: os.raw
	bochs -f bochs.properties -q
	
clean:
	del *.raw
	del *.bin