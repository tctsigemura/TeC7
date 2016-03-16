/*
 * TaC  Micro Code Assembler Program
 *    Tokuyama kousen Educational Computer 16bit Ver.
 *
 * Copyright (C) 2002-2010 by
 *                      Dept. of Computer Science and Electronic Engineering,
 *                      Tokuyama College of Technology, JAPAN
 *
 *   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
 * 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
 * コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
 * 布することを無償で許諾する．
 *
 *   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
 * 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
 * も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
 * る損害に関しても，その責任を負わない．
 *
 *
 */

/*
 * edu.h : マイクロコードアセンブラで使用する定数等
 *
 * 2012.07.14           : REG(FP), STP, CLP, ALU(INC2,DEC2),Jcc(NPRV,ZERO),
 *                        BUS(HALT,MEMRB,MEMWB,IORB,IOWB) を追加・変更
 * 2011.09.06           : PCR を追加, BUS 命令を変更(エンコード)
 * 2011.07.18           : TMP レジスタを追加
 * 2011.07.18           : TRAP 命令を削除
 * 2011.07.05           : TRAP 命令を追加
 * 2010.07.23           : RS_FLAG => RS_FL に変更(名前が長すぎ)
 * 2010.07.20           : Subversion による管理を開始
 *
 * $Id: edu.h 12 2010-08-06 10:03:08Z sigemura $
 *
 */

#define ERROR	(-1)
#define UNDEF	(-2)

/* レジスタ指定 */
#define RS_NO   0
#define RS_FP   0
#define RS_SP	1
#define RS_PC	2
#define RS_FL	3    /* FLAG */
#define RS_Rd	4
#define RS_RdP	5
#define RS_Rx	6
#define RS_TMP	7

/* ALU の機能 */
#define AL_ZERO	0x0
#define AL_A	0x1
#define AL_B	0x2
#define AL_ADD	0x3
#define AL_SUB	0x4
#define AL_AND	0x5
#define AL_OR	0x6
#define AL_XOR	0x7
#define AL_INC2	0x8
#define AL_DEC2	0x9
#define AL_XADD	0xa
#define AL_XSUB	0xb
#define AL_RROT	0xc
#define AL_LROT	0xd
#define AL_SFT	0xe
#define AL_SUBC	0xf

/* Jump 命令 */
#define J_NO	0
#define J_AL	1
#define J_OP	2
#define J_INT	3
#define J_CTDR  4
#define J_NJ	5
#define J_CT16	6
#define J_STP	7
#define J_DI	8
#define J_SPR	9
#define J_PCR	10
#define J_IM	11
#define J_NPRV  12
#define J_ZERO  13

/* Bus 命令 */
#define B_NO    0
#define B_MEMR  1
#define B_MEMW  2
#define B_IOR   3
#define B_IOW   4
#define B_FETCH 5
#define B_VECT  6
#define B_IOF   7
#define B_LDRX  8
#define B_HALT  9
#define B_MEMRB 10
#define B_MEMWB 11
#define B_IORB  12
#define B_IOWB  13

/* Flag 命令 */
#define F_NO    0
#define F_FP    0
#define F_LD    1
#define F_STI   2
#define F_CLI   3
#define F_STP   4
#define F_CLP   5

/* マイクロ命令のフォーマット */
#define RM_ALU(x) ((int)((x)>>28)&0x0f)
#define RM_RR(x)  ((int)((x)>>25)&0x07)
#define RM_WR(x)  ((int)((x)>>22)&0x07)
#define RM_FLG(x) ((int)((x)>>19)&0x07)
#define RM_LA(x)  ((int)((x)>>18)&0x01)
#define RM_LO(x)  ((int)((x)>>17)&0x01)
#define RM_NC(x)  ((int)((x)>>16)&0x01)   /* 未使用 */
#define RM_BUS(x) ((int)((x)>>12)&0x0f)
#define RM_JP(x)  ((int)((x)>> 8)&0x0f)
#define RM_JA(x)  ((int) (x)     &0xff)

#define WM_ALU(y,x) ((y)|=((((long)x)&0x0f)<<28))
#define WM_RR(y,x)  ((y)|=((((long)x)&0x07)<<25))
#define WM_WR(y,x)  ((y)|=((((long)x)&0x07)<<22))
#define WM_FLG(y,x) ((y)|=((((long)x)&0x07)<<19))
#define WM_LA(y,x)  ((y)|=((((long)x)&0x01)<<18))
#define WM_LO(y,x)  ((y)|=((((long)x)&0x01)<<17))
#define WM_NC(y,x)  ((y)|=((((long)x)&0x01)<<16))   /* 未使用 */
#define WM_BUS(y,x) ((y)|=((((long)x)&0x0f)<<12))
#define WM_JP(y,x)  ((y)|=((((long)x)&0x0f)<< 8))
#define WM_JA(y,x)  ((y)|=( ((long)x)&0xff)     )
