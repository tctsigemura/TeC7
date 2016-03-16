#
# TaC Micro Program Source Code
#    Tokuyama kousen Educational Computer 16 bit Version
#
# Copyright (C) 2002-2010 by
#                      Dept. of Computer Science and Electronic Engineering,
#                      Tokuyama College of Technology, JAPAN
#
#   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
# 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
# コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
# 布することを無償で許諾する．
#
#   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
# 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
# も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
# る損害に関しても，その責任を負わない．
#
#
# Makefile
#
# 2012.07.14        : DROMサイズを 512バイトに変更
# 2011.06.28        : TeC7 用に変更
#

UTILDIR=../../Util

all : tac_mrom.txt tac_drom.txt

tac_drom.txt : drom.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 8 8 < drom.hex > tac_drom.txt

tac_mrom.txt : mrom.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 8 32 < mrom.hex > tac_mrom.txt

drom.hex : ${UTILDIR}/tbl2hex mrom.sym drom.tbl
	${UTILDIR}/tbl2hex 512 mrom drom

mrom.hex : mrom.bin
	 awk '{printf("%02X %s\n", NR-1, $$0);}' mrom.bin > mrom.hex

mrom.sym mrom.bin : masm mrom.asm
	./masm mrom > mrom.lst

masm   : masm.c edu.h
	cc -o masm masm.c

${UTILDIR}/tbl2hex : ${UTILDIR}/tbl2hex.c
	(cd ${UTILDIR}; make tbl2hex)

${UTILDIR}/hex2txt : ${UTILDIR}/hex2txt.c
	(cd ${UTILDIR}; make hex2txt)

clean :
	rm -f *.o *~
	rm -f *.hex *.txt *.sym *.bin *.lst
	rm -f masm
