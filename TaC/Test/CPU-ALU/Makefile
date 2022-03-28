kernel.bin: test.o
	objbin-- 0x0000 kernel.bin test.o | sort --key=1

test.o : test.s
	as-- test.s

clean :
	rm -f *.lst *.o *.bin *~
