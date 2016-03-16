UTILDIR=../../Util
all : tec_mrom.txt tec_drom.txt

tec_drom.txt : drom.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 8 8 < drom.hex > tec_drom.txt

tec_mrom.txt : mrom.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 7 32 < mrom.hex > tec_mrom.txt

drom.hex : ${UTILDIR}/tbl2hex mrom.sym drom.tbl
	${UTILDIR}/tbl2hex 256 mrom drom

mrom.hex : mrom.bin
	 awk '{printf("%02X %s\n", NR-1, $$0);}' mrom.bin > mrom.hex

mrom.sym mrom.bin : masm mrom.asm
	./masm mrom > mrom.lst

masm   : masm.c edu.h
	cc -o masm masm.c

masm.o : edu.h

${UTILDIR}/tbl2hex : ${UTILDIR}/tbl2hex.c
	(cd ${UTILDIR}; make tbl2hex)

${UTILDIR}/hex2txt : ${UTILDIR}/hex2txt.c
	(cd ${UTILDIR}; make hex2txt)

clean :
	rm -f *.o *~
	rm -f *.hex *.txt *.sym *.bin *.lst
	rm -f masm
