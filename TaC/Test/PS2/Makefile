#
# TaC Test Source Code
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
# Makefile : MAIN テストプログラムの makefile
#
# 2019.01.06         : cm2e を使用するように変更
# 2012.01.11         : 初期バージョン
#
# $Id$
#

TEXT=0x0000

kernel.bin: main
	objbin-- ${TEXT} kernel.bin main | sort > kernel.map

main: crt0.o main.o
	ld-- main crt0.o main.o > main.sym

main.o: main.cmm util.h
	cm2e -K -c main.cmm

crt0.o: crt0.s
	as-- crt0.s

clean:
	rm -f main main.s *.lst *.bin *.o *.hex *.sym *.map *~

