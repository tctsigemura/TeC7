#
# TaC IPL Source Code
#    Tokuyama kousen Educational Computer 16 bit Version
#
# Copyright (C) 2009-2019 by
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
# Makefile : IPL の makefile
#
# 2019.02.28           : IPLをIPL0とIPL1に分離
# 2019.02.26           : HEAPを追加
# 2019.02.03 v4.2.0    : TeCモードでSETAとRESETの同時押しでTacOSを起動する
# 2018.10.26 v4.1.1    : DEMO1モードでTaCは単純なRN<=>FT中継機能
#                        DEMO2とリセットモードTaCはポート操作もできる中継機能
# 2018.07.17 Ver.4.1.0 : BSSを広くする, RN4020のリセットモード追加
# 2017.05.09 Ver.4.0.0 : TeC7b に対応, cm2e を使用するように変更
# 2016.01.07 Ver.3.0.0 : 川部版と統合
# 2016.01.07           : c-- に -K オプション追加
# 2012.09.25           : objbin-- がメモリマップを出力するように変更
# 2012.09.12 Ver.2.0.0 : TeC-CPU V2 対応
# 2012.02.29           : VER,DATE変数を追加, console.cmm, mmcspi.cmm 追加
# 2010.07.20           : Subversion の管理に入る
# 2009.04.12           : 初期バージョン
#
# $Id$
#

VER=\"`cat VERSION`\"
DATE="\"`date`\""

HEAP=0xd000           # 0xd000 - ...    : heap
BSS=0xe000            # 0xe000 - ...    : bss
STK=0xf000            # ...    - 0xefff : stack
TEXT=0xf000           # 0xf000 - 0xffdf : ipl rom

CMFLAGS=-K -c -DDATE=${DATE} -DVER=${VER} -DTEXT=${TEXT} -DHEAP=${HEAP}

OBJS0=crt0.o ipl0.o util.o
OBJS1=crt0.o ipl1.o loader.o mmcspi.o util.o
UTILDIR=../../Util

.SUFFIXES: .o .cmm .s

.s.o:
	as-- $*.s

.cmm.o:
	cm2e ${CMFLAGS} $*.cmm

all : tac_ram0.txt tac_ram1.txt

tac_ram0.txt : ipl0.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 16 16 < ipl0.hex > tac_ram0.txt

ipl0.hex : ${UTILDIR}/bin2hex16 ipl0.bin
	${UTILDIR}/bin2hex16 ipl0.bin 0x1000 > ipl0.hex  # 4kB

ipl0.bin: ipl0
	objbin-- ${TEXT} ipl0.bin ipl0 ${BSS} | sort --key=1 > ipl0.map

ipl0: ${OBJS0} crt0.h
	ld-- ipl0 ${OBJS0} > ipl0.sym
	size-- ipl0

tac_ram1.txt : ipl1.hex ${UTILDIR}/hex2txt
	${UTILDIR}/hex2txt 16 16 < ipl1.hex > tac_ram1.txt

ipl1.hex : ${UTILDIR}/bin2hex16 ipl1.bin
	${UTILDIR}/bin2hex16 ipl1.bin 0x1000 > ipl1.hex  # 4kB

ipl1.bin: ipl1
	objbin-- ${TEXT} ipl1.bin ipl1 ${BSS} | sort --key=1 > ipl1.map

ipl1: ${OBJS1} crt0.h
	ld-- ipl1 ${OBJS1} > ipl1.sym
	size-- ipl1

hex2txt : ${UTILDIR}/hex2txt.c
	(cd ${UTILDIR}; make hex2txt)

bin2hex16 : ${UTILDIR}/bin2hex16.c
	(cd ${UTILDIR}; make bin2hex16)

clean:
	rm -f tac_ram?.txt ipl0 ipl0.s ipl1 ipl1.s *.lst *.bin *.o *.hex *.sym *.map *~

