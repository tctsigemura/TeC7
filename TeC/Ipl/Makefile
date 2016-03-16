UTILDIR=../../Util

all: tec_ram.txt

tec_ram.txt : ram.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 10 8 < ram.hex > tec_ram.txt

ram.hex : ${UTILDIR}/bin2hex ipl.bin tac.bin demo1.bin demo2.bin
	${UTILDIR}/bin2hex ipl.bin tac.bin demo1.bin demo2.bin > ram.hex

ipl.bin : ipl.t7
	tasm7 ipl.t7

tac.bin : tac.t7
	tasm7 tac.t7

demo1.bin : demo1.t7
	tasm7 demo1.t7

demo2.bin : demo2.t7
	tasm7 demo2.t7

${UTILDIR}/hex2txt : ${UTILDIR}/hex2txt.c
	(cd ${UTILDIR}/; make)

${UTILDIR}/bin2hex : ${UTILDIR}/bin2hex.c
	(cd ${UTILDIR}/; make)

clean :
	rm -f ram.hex tec_ram.txt *.bin *.lst *~
