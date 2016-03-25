#
# TaC Kernel Source Code
#    Tokuyama kousen Educational Computer 16 bit Version
#
# Copyright (C) 2008-2010 by
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
# Makefile : サンプルプログラム 8Queen の makefile
#
# 2010.07.20         : Subversion の管理に入る
# 2010.06.18         : cpp に std=c99 オプション追加
# 2008.08            : 初期バージョン
#
# $Id$
#

kernel.bin : crt0.o kernel.o util.o
	ld-- kernel crt0.o kernel.o util.o > kernel.sym
	objbin-- 0x0000 kernel.bin kernel

crt0.o : crt0.s
	as-- crt0.s

kernel.o : kernel.cmm util.h
	cpp -std=c99 kernel.cmm | c-- > kernel.s
	as-- kernel.s

util.o : util.cmm util.h
	cpp -std=c99 util.cmm | c-- > util.s
	as-- util.s

clean :
	rm -f kernel.bin kernel *.o kernel.s util.s *.lst *.sym *~

