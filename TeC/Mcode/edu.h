/*
 * TeC6  Micro Code Assembler/Simulator Program
 *    Tokuyama kousen Educational Computer Ver.6
 *
 * Copyright (C) 2002-2004 by
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
 *    アセンブラとシミュレータで共通の定数を定義
 */

/*#define	MSDOS*/

#define ERROR	(-1)
#define UNDEF	(-2)

/* レジスタ指定 */
#define RS_NO   0
#define RS_SP	0
#define RS_PC	1
#define RS_Rd	2
#define RS_Rx	3

/* ALU の機能 */
#define AL_ZERO	0x0
#define AL_A	0x1
#define AL_B	0x2
#define AL_ADD	0x3
#define AL_SUB	0x4
#define AL_AND	0x5
#define AL_OR	0x6
#define AL_XOR	0x7
#define AL_INC	0x8
#define AL_DEC	0x9
#define AL_ADC	0xa
#define AL_OUTF	0xb
#define AL_INF	0xc
#define AL_SFT	0xd

/* Jump 命令 */
#define J_AL	1
#define J_OP	2
#define J_INT	3
#define J_STP   4
#define J_JP	5
#define J_NJP	6
#define J_DI	7

/* BUS 命令 */
#define B_NO    0
#define B_MR    1
#define B_MW    2
#define B_IOR   3
#define B_IOW   4
#define B_VR    5

/* マイクロ命令のフォーマット */
#define RM_ALU(x) ((int)((x)>>28)&0x0f)
#define RM_RR(x)  ((int)((x)>>26)&0x03)
#define RM_WR(x)  ((int)((x)>>24)&0x03)
#define RM_LR(x)  ((int)((x)>>23)&0x01)
#define RM_LF(x)  ((int)((x)>>22)&0x01)
#define RM_LA(x)  ((int)((x)>>21)&0x01)
#define RM_LO(x)  ((int)((x)>>20)&0x01)
#define RM_LD(x)  ((int)((x)>>19)&0x01)
#define RM_LI(x)  ((int)((x)>>18)&0x01)
#define RM_HL(x)  ((int)((x)>>17)&0x01)
#define RM_ER(x)  ((int)((x)>>16)&0x01)
#define RM_STI(x) ((int)((x)>>15)&0x01)
#define RM_CLI(x) ((int)((x)>>14)&0x01)
#define RM_RW(x)  ((int)((x)>>13)&0x01)
#define RM_MR(x)  ((int)((x)>>12)&0x01)
#define RM_IR(x)  ((int)((x)>>11)&0x01)
#define RM_JP(x)  ((int)((x)>> 8)&0x07)
#define RM_JA(x)  ((int) (x)     &0xff)

#define WM_ALU(y,x) ((y)|=((((long)x)&0x0f)<<28))
#define WM_RR(y,x)  ((y)|=((((long)x)&0x03)<<26))
#define WM_WR(y,x)  ((y)|=((((long)x)&0x03)<<24))
#define WM_LR(y,x)  ((y)|=((((long)x)&0x01)<<23))
#define WM_LF(y,x)  ((y)|=((((long)x)&0x01)<<22))
#define WM_LA(y,x)  ((y)|=((((long)x)&0x01)<<21))
#define WM_LO(y,x)  ((y)|=((((long)x)&0x01)<<20))
#define WM_LD(y,x)  ((y)|=((((long)x)&0x01)<<19))
#define WM_LI(y,x)  ((y)|=((((long)x)&0x01)<<18))
#define WM_HL(y,x)  ((y)|=((((long)x)&0x01)<<17))
#define WM_ER(y,x)  ((y)|=((((long)x)&0x01)<<16))
#define WM_STI(y,x) ((y)|=((((long)x)&0x01)<<15))
#define WM_CLI(y,x) ((y)|=((((long)x)&0x01)<<14))
#define WM_RW(y,x)  ((y)|=((((long)x)&0x01)<<13))
#define WM_MR(y,x)  ((y)|=((((long)x)&0x01)<<12))
#define WM_IR(y,x)  ((y)|=((((long)x)&0x01)<<11))
#define WM_JP(y,x)  ((y)|=((((long)x)&0x07)<< 8))
#define WM_JA(y,x)  ((y)|=( ((long)x)&0xff)     )
