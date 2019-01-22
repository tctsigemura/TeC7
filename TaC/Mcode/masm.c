/*
 * TaC Micro Code Assenbler Program
 *    Tokuyama kousen Educational Computer 16bit Ver.
 *
 * Copyright (C) 2002-2017 by
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
 * masm.c : マイクロコードアセンブラ本体
 *
 * 2017.01.10           :  Jcc(NIOPR) を追加
 * 2013.12.16           : コメントのネストを解消
 * 2012.09.26           : リスト出力の空白数の調節
 * 2012.07.14           : REG(FP), STP, CLP, ALU(INC2,DEC2),Jcc(NPRV,ZERO),
 *                        BUS(HALT,MEMRB,MEMWB,IORB,IOWB) を追加・変更
 * 2011.09.06           : Jcc の条件に PCR を追加
 * 2011.07.18           : TMP レジスタを追加
 * 2011.07.18           : Trap 命令を削除
 * 2011.07.05           : Trap 命令を追加
 * 2010.07.23           : ALU 命令と LD 命令で FLAG を使用できるように改良
 * 2010.07.22           : エラー発生を終了コードとメッセージで知らせる
 * 2010.07.20           : Subversion による管理を開始
 *
 * $Id: masm.c 12 2010-08-06 10:03:08Z sigemura $
 *
 */

#include "edu.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>
#include <ctype.h>

/* 定数 */
#define FMAX     100       /* ファイル名の最大長 */
#define LINEMAX	 200       /* リストに出力できるソースの長さ */
#define LINEDEF  80        /* リストの横幅（デフォルト）*/
#define PAGEDEF  66        /* リストの1ページの長さ（デフォルト）*/
#define MAXSYM   128       /* ラベルの最大数 */
#define STRMAX   8         /* ラベルの最大長*/

/* トークンの抽出に関係する定数と変数 */
#define ERRTOK   (-2)
#define LABEL    1000

/* 命令 */
#define STI      1007      /* Set   Interrupt */
#define CLI      1008      /* Clear Interrupt */
#define STP      1009      /* Set   Privilege */
#define CLP      1010      /* Clear Privilege */
#define ALU      1011
#define LD       1012
#define BUS      1013
#define JOP      1014
#define J        1015
#define JCC      1016
#define NO       1017

/* ALU 命令の機能 */
#define REG      1020
#define ADD      1021
#define SUB      1022
#define INC2     1023
#define DEC2     1024
#define AND      1025
#define OR       1026
#define XOR      1027
#define XADD	 1028
#define XSUB	 1029
#define RROT	 1030
#define LROT	 1031
#define SFT      1032
#define SUBC     1033
#define ZERO     1034      /* ZERO が最後であること */
#define FNUM(f)  ((f)-REG)

/* JCC 命令の条件 */
#define INT      1040
#define NJP      1041
#define CT16     1042
#define STOP     1043
#define CTDR     1044
#define DI       1045
#define SPR      1046
#define PCR      1047
#define IM       1048
#define NIOPR    1049
#define NPRV     1050

/* バス命令の機能 */
#define MEMR     1051      /* Read Word from Memory  */
#define MEMW     1052      /* Write Word to Memory   */
#define IOR      1053      /* Read Word from I/O     */
#define IOW      1054      /* Write Word to I/O      */
#define FETCH    1055      /* Read Instruction       */
#define VECT     1056      /* Read Vector            */
#define LDRX     1057      /* Move Rx register to DR */
#define IOF      1058      /* Read Panel Instruction */
#define HALT     1059      /* Halt                   */
#define MEMRB    1060      /* Read Byte from Memory  */
#define MEMWB    1061      /* Write Byte to Memory   */
#define IORB     1062      /* Read Byte from I/O     */
#define IOWB     1063      /* Write Byte to I/O      */

/* レジスタ */
#define FP       1999
#define SP       2000
#define PC       2001
#define FLAG     2002
#define RD       2003
#define RDP      2004
#define RX       2005
#define TMP      2006
#define DR       2007
#define IR       2008
#define AR       2009
#define OPR      2010
#define FL       2011      /* FLAG へロード*/
#define RNUM(r)  ((r)-FP)

/* トークンの一覧表 */
struct word_tok_t 
{
  char *str;
  int   num;
} word_tok[] =
{ /* 命令 */
  { "NO",    NO   }, { "STI",   STI  }, { "CLI",   CLI  },
  { "STP",   STP  }, { "CLP",   CLP  }, { "ALU",   ALU  },
  { "LD",    LD   }, { "BUS",   BUS  }, { "JOP",   JOP  },
  { "J",     J    }, { "JCC",   JCC  },

  /* ALU 命令 */
  { "REG",   REG  }, { "ADD",   ADD  }, { "SUB",   SUB  },
  { "INC2",  INC2 }, { "DEC2",  DEC2 }, { "AND",   AND  },
  { "OR",    OR   }, { "XOR",   XOR  }, { "XADD",  XADD },
  { "XSUB",  XSUB }, { "RROT",  RROT }, { "LROT",  LROT },
  { "SFT",   SFT  }, { "SUBC",  SUBC }, { "ZERO",  ZERO },

  /* JCC 命令 */
  { "INT",   INT  }, { "NJP",   NJP  }, { "CT16",  CT16 },  { "STOP",  STOP },
  { "CTDR",  CTDR }, { "DI",    DI   }, { "SPR",   SPR   }, { "PCR",   PCR  },
  { "IM",    IM   }, { "NPRV",  NPRV }, { "NIOPR", NIOPR },

  /* BUS 命令 */
  { "MEMR",  MEMR }, { "MEMW",   MEMW }, { "IOR",   IOR  }, { "IOW",   IOW  },
  { "FETCH", FETCH}, { "VECT",   VECT }, { "LDRX",  LDRX }, { "IOF",   IOF  },
  { "MEMRB", MEMRB}, { "MEMWB",  MEMWB}, { "IORB",  IORB }, { "IOWB",  IOWB },
  { "HALT",  HALT },

  /* レジスタ */
  { "SP",    SP   }, { "PC",    PC   }, { "FLAG",  FLAG },
  { "RD",    RD   }, { "RDP",   RDP  }, { "RX",    RX   },
  { "TMP",   TMP  }, { "DR",    DR   }, { "IR",    IR   },
  { "AR",    AR   }, { "OPR",   OPR  }, { "FL",    FL   },
  { "FP",    FP   }
};

#define  NRW   (sizeof(word_tok)/sizeof(struct word_tok_t))

/* シンボルテーブル */
struct sym_tbl_t
{
  char sym[STRMAX+1];
  int  val;
} sym_tbl[MAXSYM];

int sym_cnt = 0;

/* 一行にマイクロ命令の同じフィールドを使用する命令が
   ２つ以上書かれていないかチェックするためのフラグ  */
int aluuse, bususe, jumpuse, lduse, fluse;

/* そのほか */
FILE *fp;                     /* ソースファイル */
int nextch, nexttok;          /* 現在の文字／トークン */
int lc;                       /* ロケーションカウンタ */
int vc;                       /* ベクタ用のカウンタ */
char lbuf[LINEMAX+1];         /* 読み込んだソースをためて置くバッファ */
int lbuf_cnt;                 /* バッファ内のカウンタ */
unsigned long mcode;          /* マイクロコードを組み立てるためのバッファ */
unsigned long mbuf[256];      /* VHDL 出力関係 2002.6.24*/
char label[STRMAX+1];         /* ラベル用のバッファ */
char *errmes;                 /* エラー発生時にエラーメッセージを記憶 */
int err_cnt = 0;              /* エラーの発生回数 */
//int width = LINEDEF;*_      /* リストの１行の長さ */
int page  = PAGEDEF;          /* リストの１ページの長さ */
int l_form;                   /* リストをロング形式で出力するかどうか */


/* 一文字入力する
*/
int getchr()
{
  static int ch;

  if ( ch=='\n' )
    {
      lbuf[ lbuf_cnt ]='\0';
      lbuf_cnt = 0;
    }
  else if ( lbuf_cnt < LINEMAX )
    {
      if ( ch == '\t' ) {
        lbuf_cnt=(lbuf_cnt+8) & ~7;
	if (lbuf_cnt > LINEMAX) lbuf_cnt = LINEMAX;
      } else
        lbuf[ lbuf_cnt++ ] = ch;
    }
    
  ch     = getc(fp);
  nextch = toupper(ch);
  return nextch;
}

/*  文字列を入力する
*/
void getstr( buf )
char *buf;
{
  int i;

  for ( i=0; isalnum(nextch); getchr() )
    if ( i < STRMAX )
      buf[ i++ ] = nextch;

  buf[ i ] = '\0';
}

/*  数値を入力する
*/
int getnum()
{
  int n = 0;
  
  while ( isdigit(nextch) )
    {
      n = n * 10 + nextch - '0';
      getchr();
    }
  return n;
}

/*  次の行に進む（トークンはLFを返す）
*/
int nextline()
{
  while ( nextch!='\n' && nextch!=EOF )
    getchr();

  nexttok = nextch;
  getchr();
  return nexttok;
}

/*  次のトークンを取り出す（行末ではLFを返す。次の行には進まない）
*/
int gettok()
{
  while ( isspace( nextch ) && nextch!='\n' )
    getchr();

  if ( nextch=='\n' )
    {
      nexttok = '\n';
      return nexttok;
    }
  else if ( nextch==';' || nextch==',' || nextch=='('
          || nextch=='#' || nextch==')' || nextch==EOF )
    {
      nexttok = nextch;
      getchr();
      return nexttok;
    }
  else if ( isalpha( nextch ) )
    {
      int i;
      char buf[STRMAX+1];

      getstr( buf );
      for ( i=0; i<NRW; i++ )
	if ( strcmp( buf, word_tok[i].str)==0 )
	  {
	    nexttok = word_tok[i].num;
	    return nexttok;
	  }
    }

  nexttok = ERRTOK;
  return nexttok;
}

/*  ラベル欄を読み込む
*/
int getlab()
{
  if ( isspace( nextch ) && nextch!='\n' )
    {
      nexttok = ' ';
      getchr();
      return nexttok;
    }
  else if ( isalpha( nextch ) )
    {
      nexttok = LABEL;
      getstr( label );
      return nexttok;
    }
  
  return gettok();
}

#define getexp(exp,mes) {if(gettok()!=(exp)){errmes=mes;return;}}

/*  リストを出力する
*/
void list(x)
int x;
{
  static int line_cnt = 0;
  static int page_cnt = 0;

  if (lc < 256) mbuf[lc] = mcode;             /* VHDL 出力関係 2002.6.24*/

  if ( l_form==0 )
    {
      if ( line_cnt == 0 )
        {
          printf( "ADR CODE    Label   Command %42s Page(%d)\n\n",
                  "", ++page_cnt );
          line_cnt += 2;
        }
        
      /* lbuf[width - 13] = '\0'; */
      if ( x )
	printf( "%02X %08lX %s\n", lc, mcode, lbuf );
      else
        printf( "%02X %8s %s\n", lc, "", lbuf );
    }
  else
    {
      if ( line_cnt == 0 )
        {
          printf( "A  A R W F L L N B J J\n" );
          printf( "D  L R R L A O C U P A %50s Page(%d)\n","", ++page_cnt );
          printf( "R  U     G       S\n" );
          line_cnt += 3;
        }
               
      /* lbuf[width - 25] = '\0'; */
      
      if ( x )
        printf(
        "%02X %X %X %X %X %x %x %x %X %X %02X %s\n",
	lc,RM_ALU(mcode),RM_RR(mcode),RM_WR(mcode),RM_FLG(mcode),RM_LA(mcode),
	RM_LO(mcode),RM_NC(mcode),
	RM_BUS(mcode),RM_JP(mcode),RM_JA(mcode),lbuf
	       );
      else
        printf( "%02X %21s %s\n", lc, "", lbuf );
    }
    
  if ( errmes )
    {
      printf( "*** %s\n", errmes );
      ++line_cnt;
      ++err_cnt;
    }
  
  if ( ++line_cnt >= page-1 )
    {
      for ( ; line_cnt!=page; line_cnt++ )
        printf( "\n" );
      line_cnt = 0;
    }
}

/*  ラベルの参照を処理する
*/
int getsym()
{
  char buf[STRMAX+1];
  int i;

  if ( nextch=='.' )
    {
      getchar();
      return lc;
    }
  else if ( isalpha( nextch ) )
    {
      getstr( buf );
      for ( i=0; i<sym_cnt; i++ )
	if ( strcmp( sym_tbl[i].sym, buf ) == 0 )
	  return sym_tbl[i].val;
      errmes = "未定義ラベルが参照された";
      return 0;
    }
  else if ( isdigit( nextch ) )
      return getnum();
      
  errmes = "ラベル参照の文法に誤りがある";
  return 0;
}

/*
 *  ALU 命令の機能とレジスタの組合せにより、alu,rrフィールドの値を決める
 */
struct alu_tbl_t
{
  int alu;
  int rr;
} alu_tbl[][9] =
  {
    /*func               FP                SP                PC
      func               FL(Flag)          Rd                RdP
      func               Rx                TMP               DR      */

    /*REG*/ {{ AL_A,    RS_FP  }, { AL_A,    RS_SP  }, { AL_A,    RS_PC  },
	     { AL_A,    RS_FL  }, { AL_A,    RS_Rd  }, { AL_A,    RS_RdP },
	     { AL_A,    RS_Rx  }, { AL_A,    RS_TMP }, { AL_B,    RS_NO  }},

    /*ADD*/ {{ AL_ADD,  RS_FP  }, { AL_ADD,  RS_SP  }, { AL_ADD,  RS_PC  },
	     { AL_A,    RS_FL  }, { AL_ADD,  RS_Rd  }, { AL_ADD,  RS_RdP },
	     { AL_ADD,  RS_Rx  }, { AL_ADD,  RS_TMP }, { ERROR,   ERROR  }},

    /*SUB*/ {{ AL_SUB,  RS_FP  }, { AL_SUB,  RS_SP  }, { AL_SUB,  RS_PC  },
	     { AL_SUB,  RS_FL  }, { AL_SUB,  RS_Rd  }, { AL_SUB,  RS_RdP },
	     { AL_SUB,  RS_Rx  }, { AL_SUB,  RS_TMP }, { ERROR,   ERROR  }},

    /*INC2*/{{ AL_INC2, RS_FP  }, { AL_INC2, RS_SP  }, { AL_INC2, RS_PC  },
	     { AL_INC2, RS_FL  }, { AL_INC2, RS_Rd  }, { AL_INC2, RS_RdP },
	     { AL_INC2, RS_Rx  }, { AL_INC2, RS_TMP }, { ERROR,   ERROR  }},

    /*DEC2*/{{ AL_DEC2, RS_FP  }, { AL_DEC2, RS_SP  }, { AL_DEC2, RS_PC  },
	     { AL_DEC2, RS_FL  }, { AL_DEC2, RS_Rd  }, { AL_DEC2, RS_RdP },
	     { AL_DEC2, RS_Rx  }, { AL_DEC2, RS_TMP }, { ERROR,   ERROR  }},
    
    /*AND*/ {{ AL_AND,  RS_FP  }, { AL_AND,  RS_SP  }, { AL_AND,  RS_PC  },
	     { AL_AND,  RS_FL  }, { AL_AND,  RS_Rd  }, { AL_AND,  RS_RdP },
	     { AL_AND,  RS_Rx  }, { AL_AND,  RS_TMP }, { ERROR,   ERROR  }},

    /*OR */ {{ AL_OR,   RS_FP  }, { AL_OR,   RS_SP  }, { AL_OR,   RS_PC  },
	     { AL_OR,   RS_FL  }, { AL_OR,   RS_Rd  }, { AL_OR,   RS_RdP },
	     { AL_OR,   RS_Rx  }, { AL_OR,   RS_TMP }, { ERROR,   ERROR  }},

    /*XOR*/ {{ AL_XOR,  RS_FP  }, { AL_XOR,  RS_SP  }, { AL_XOR,  RS_PC  },
	     { AL_XOR,  RS_FL  }, { AL_XOR,  RS_Rd  }, { AL_XOR,  RS_RdP },
	     { AL_XOR,  RS_Rx  }, { AL_XOR,  RS_TMP }, { ERROR,   ERROR  }},

    /*XADD*/{{ AL_XADD, RS_FP  }, { AL_XADD, RS_SP  }, { AL_XADD, RS_PC  },
	     { AL_XADD, RS_FL  }, { AL_XADD, RS_Rd  }, { AL_XADD, RS_RdP },
	     { AL_XADD, RS_Rx  }, { AL_XADD, RS_TMP }, { ERROR,   ERROR  }},

    /*XSUB*/{{ AL_XSUB, RS_FP  }, { AL_XSUB, RS_SP  }, { AL_XSUB, RS_PC  },
	     { AL_XSUB, RS_FL  }, { AL_XSUB, RS_Rd  }, { AL_XSUB, RS_RdP },
	     { AL_XSUB, RS_Rx  }, { AL_XSUB, RS_TMP }, { ERROR,   ERROR  }},

    /*RROT*/{{ AL_RROT, RS_FP  }, { AL_RROT, RS_SP  }, { AL_RROT, RS_PC  },
	     { AL_RROT, RS_FL  }, { AL_RROT, RS_Rd  }, { AL_RROT, RS_RdP },
	     { AL_RROT, RS_Rx  }, { AL_RROT, RS_TMP }, { ERROR,   ERROR  }},

    /*LROT*/{{ AL_LROT, RS_FP  }, { AL_LROT, RS_SP  }, { AL_LROT, RS_PC  },
	     { AL_LROT, RS_FL  }, { AL_LROT, RS_Rd  }, { AL_LROT, RS_RdP },
	     { AL_LROT, RS_Rx  }, { AL_LROT, RS_TMP }, { ERROR,   ERROR  }},

    /*SFT*/ {{ AL_SFT,  RS_FP  }, { AL_SFT,  RS_SP  }, { AL_SFT,  RS_PC  },
	     { AL_SFT,  RS_FL  }, { AL_SFT,  RS_Rd  }, { AL_SFT,  RS_RdP },
	     { AL_SFT,  RS_Rx  }, { AL_SFT,  RS_TMP }, { ERROR,   ERROR  }},

    /*SUBC*/{{ AL_SUBC, RS_FP  }, { AL_SUBC, RS_SP  }, { AL_SUBC, RS_PC  },
	     { AL_SUBC, RS_FL  }, { AL_SUBC, RS_Rd  }, { AL_SUBC, RS_RdP },
	     { AL_SUBC, RS_Rx  }, { AL_SUBC, RS_TMP }, { ERROR,   ERROR  }},

    /*ZERO*/{{ AL_ZERO, RS_NO  }, { ERROR,   ERROR  }, { ERROR,   ERROR  },
	     { ERROR,   ERROR  }, { ERROR,   ERROR  }, { ERROR,   ERROR  },
	     { ERROR,   ERROR  }, { ERROR,   ERROR  }, { ERROR,   ERROR  }}
};

void alu()
{
  int f, r, t;

  if ( aluuse++ )
    {
      errmes = "ALU 命令が複数存在する";
      return;
    }

  getexp( '(', "ALU 命令の次に '(' がない" );
  f = FNUM( gettok() );

  if ( f<0 || FNUM(ZERO)<f )
    {
      errmes = "ALU 命令の機能が不正";
      return;
    }

  if ( f==FNUM(ZERO) )
    {
      WM_ALU(mcode,alu_tbl[f][0].alu);
      WM_RR (mcode,alu_tbl[f][0].rr );
    }
  else
    {
      getexp( ',', "ALU の機能の次に ',' がない" );
      r = RNUM( gettok() );
      if ( r<0 || RNUM(DR)<r )
	{
	  errmes = "ALU のレジスタが不正";
	  return;
	}
      t = alu_tbl[f][r].alu;
      if ( t == ERROR )
	{
	  errmes = "ALU の機能とレジスタの組合せが不正";
	  return;
	}
      WM_ALU(mcode, t);
      WM_RR (mcode, alu_tbl[f][r].rr);
    }

  if ( gettok() == ',' )
    {
      if (fluse++)
	{
	  errmes = "フラグ操作が重複";
	  return;
	}
      getexp( FL, "ALU 命令の FL 指定部に FL 以外が書かれた" );
      WM_FLG(mcode, F_LD);
      gettok();
    }

  if ( nexttok != ')' )
    errmes = "ALU のパラメータの最後に ')' がない";
}

/*  LD 命令を処理する
*/
/* wr field とレジスタの対応    SP     PC  FLAG      Rd     RdP    Rx     TMP */
static int wr_tbl[] =      { RS_SP, RS_PC, RS_FL, RS_Rd, RS_RdP,RS_Rx, RS_TMP };

void ld()
{
  int r;
  
  if ( lduse++ )
    {
      errmes = "LD 命令が複数ある";
      return;
    }

  getexp( '(', "LD 命令の次に '(' がない" );

  do {
    r = gettok();
    if ( r == AR )
      WM_LA(mcode,1);
    else if ( r == OPR )
      WM_LO(mcode,1);
    else if ( RNUM(SP)<=RNUM(r) && RNUM(r)<=RNUM(TMP) ) {
      WM_WR(mcode,wr_tbl[RNUM(r)-RNUM(SP)]);       // SP,PC,FLAG,Rd,RdP,Rx,TMP
      if (r == FLAG) fluse++;
    } else{
      errmes = "LD 命令のレジスタが不正";
      return;
    }
  } while ( gettok()==',' );

  if ( nexttok != ')' )
    errmes = "LD 命令の最後に ')' がない";
}
 
/*  BUS 命令を処理する
*/
void bus()
{
  int t;

  if ( bususe++ )
    {
      errmes = "BUS 命令が複数ある";
      return;
    }
  getexp( '(', "BUS 命令の次に '(' がない" );

  switch (gettok()) {
  case MEMR:  WM_BUS(mcode,B_MEMR);  break;
  case MEMW:  WM_BUS(mcode,B_MEMW);  break;
  case IOR:   WM_BUS(mcode,B_IOR);   break;
  case IOW:   WM_BUS(mcode,B_IOW);   break;
  case FETCH: WM_BUS(mcode,B_FETCH); break;
  case VECT:  WM_BUS(mcode,B_VECT);  break;
  case IOF:   WM_BUS(mcode,B_IOF);   break;
  case LDRX:  WM_BUS(mcode,B_LDRX);  break;
  case HALT:  WM_BUS(mcode,B_HALT);  break;
  case MEMRB: WM_BUS(mcode,B_MEMRB); break;
  case MEMWB: WM_BUS(mcode,B_MEMWB);  break;
  case IORB:  WM_BUS(mcode,B_IORB);  break;
  case IOWB:  WM_BUS(mcode,B_IOWB);  break;
  default : errmes = "BUS 命令のオペランドが不正";
    return;
  }

  getexp( ')', "BUS 命令の次に ')' がない" );
}

/*  STI 命令を処理する
*/
void sti()
{
  if ( fluse++ )
    {
      errmes = "フラグ操作が複数ある";
      return;
    }
  WM_FLG(mcode,F_STI);
}

/*  CLI 命令を処理する
*/
void cli()
{
  if ( fluse++ )
    {
      errmes = "フラグ操作が複数ある";
      return;
    }
  WM_FLG(mcode,F_CLI);
}

/*  STP 命令を処理する
*/
void stp()
{
  if ( fluse++ )
    {
      errmes = "フラグ操作が複数ある";
      return;
    }
  WM_FLG(mcode,F_STP);
}

/*  CLP 命令を処理する
*/
void clp()
{
  if ( fluse++ )
    {
      errmes = "フラグ操作が複数ある";
      return;
    }
  WM_FLG(mcode,F_CLP);
}

/*  JOP 命令を処理する
*/
void jop()
{
  if ( jumpuse++ )
    {
      errmes = "Jump 命令が複数ある";
      return;
    }
  getexp( '(', "JOP 命令の次に '(' がない" );
  WM_JP(mcode,J_OP);
  WM_JA(mcode,getsym());
  
  if ( errmes == NULL )
    getexp( ')', "JOP 命令の最後の ')' がない" );
}

/*  J 命令を処理する
*/
void j()
{
  if ( jumpuse++ )
    {
      errmes = "Jump 命令が複数ある";
      return;
    }
  getexp( '(', "J 命令の次に '(' がない" );
  WM_JP(mcode,J_AL);
  WM_JA(mcode,getsym());

  if ( errmes == NULL )
    getexp( ')', "J 命令の最後の ')' がない" );
}

/*  JCC 命令を処理する
*/
void jcc()
{
  if ( jumpuse++ )
    {
      errmes = "Jump 命令が複数ある";
      return;
    }
  getexp( '(', "JCC 命令の次に '(' がない" );

  switch ( gettok() )
    {
    case INT  : WM_JP(mcode,J_INT);  break;
    case NJP  : WM_JP(mcode,J_NJ);   break;
    case CT16 : WM_JP(mcode,J_CT16); break;
    case STOP : WM_JP(mcode,J_STP);  break;
    case CTDR : WM_JP(mcode,J_CTDR); break;
    case DI   : WM_JP(mcode,J_DI);   break;
    case SPR  : WM_JP(mcode,J_SPR);  break;
    case PCR  : WM_JP(mcode,J_PCR);  break;
    case IM   : WM_JP(mcode,J_IM);   break;
    case NPRV : WM_JP(mcode,J_NPRV); break;
    case NIOPR: WM_JP(mcode,J_NIOPR);break;
    case ZERO : WM_JP(mcode,J_ZERO); break;
    default : errmes = "JCC 命令の条件が不正";
              return;
    }

  getexp( ',', "JCC 命令中に ',' がない" );
  WM_JA(mcode,getsym());

  if ( errmes == NULL )
    getexp( ')', "JCC 命令中の最後に ')' がない" );
}

/*
*/
void pass(x)
int x;
{
  lbuf_cnt=0;
  getchr();
  lbuf_cnt=0;
  lc = 0;

  while ( nextch != EOF )
    {
      int cnt;
      
      errmes = NULL;
      aluuse=bususe=jumpuse=lduse=fluse=0;
      memset( &mcode, 0, sizeof( mcode ) );
      memset( lbuf, ' ', LINEMAX );

      switch ( getlab() )
        {
        case '\n' :
        case ' '  : break;
        
        case LABEL: if (x==1)
                      {
                        strcpy( sym_tbl[sym_cnt].sym, label );
                        sym_tbl[sym_cnt++].val = lc;
                      }
                    break;
        
        case '#'  : /* lc = (lc+7) & ~7 */;
	case ';'  : nextline();
	            if (x==2) list( 0 );
	            continue;
	            
        default   : errmes = "ラベル欄が不正";
                    break;
	}

      for ( cnt=0; errmes==NULL && gettok()!='\n'
                  && nexttok!=EOF && nexttok!=';'; cnt++ )
	{
	  switch ( nexttok )
	    {
	    case NO   :
	    case ','  : break;
	    case ALU  : alu();  break;
	    case LD   : ld();   break;
	    case BUS  : bus();  break;
	    case STI  : sti();  break;
	    case CLI  : cli();  break;
	    case STP  : stp();  break;
	    case CLP  : clp();  break;
	    case JOP  : jop();  break;
	    case J    : j();    break;
	    case JCC  : jcc();  break;
	    default: errmes = "不正な命令がある";
	    }
	}

      nextline();
      if (x==2) list( cnt );
      if ( cnt ) lc++;
    }
}


FILE *xfopen(char *fname, char *ext, char *mod) {
  FILE *fp;
  char buf[FMAX+1];

  if (strlen(fname)+strlen(ext)+1>FMAX) {
    fprintf(stderr,"ファイル名[%s]が長すぎます。\n",fname);
    exit(1);
  }

  sprintf(buf, "%s.%s", fname, ext);

  if ((fp = fopen(buf, mod))==NULL) {
    perror(buf);
    exit(1);
  }

  return fp;
}

void writebin(char *fname) {
  FILE *fp = xfopen(fname, "bin", "w");
  int i;
  
  for(i=0; i<256; i++) {
    fprintf(fp, "%08lX\n",mbuf[i]);
  }

  fclose(fp);
}
void writesym(char *fname) {
  FILE *fp = xfopen(fname, "sym", "w");
  int i;
  
  for(i=0; i<sym_cnt; i++) {
    fprintf(fp, "%08X %s\n",sym_tbl[i].val,sym_tbl[i].sym);
  }

  fclose(fp);
}

int main ( argc, argv )
int argc;
char **argv;
{
  char *name = argv[0];
  char buf[FMAX];
  
   for  ( ; argc > 2; argc--, argv++ )
     {
       if ( strcmp( "-l", argv[1] )==0 )
         l_form = 1;
       /*
       else if ( strcmp( "-w", argv[1] )==0 )
         {
           sscanf( argv[2], "%d", &width );
           if ( width <= LINEDEF || LINEMAX < width )
             width = LINEDEF;
           argc--;
           argv++;
         }
       */
       else if ( strcmp( "-p", argv[1] )==0 )
         {
           sscanf( argv[2], "%d", &page );
           if ( page < 10 )
             page = PAGEDEF;
           argc--;
           argv++;
         }
       else
         break;
     }
     
   if ( argc != 2 )
     {
       /*fprintf( stderr, "使い方: %s [-l] [-w nn] [-p nn] <source_file>\n",*/
       fprintf( stderr, "使い方: %s [-l] [-p nn] <source_file>\n",
                name );
       fprintf( stderr, "   -l : リストを詳細な形式にする\n" );
       /*fprintf( stderr, "   -w : リストの横幅を nn 文字にする\n" );*/
       fprintf( stderr, "   -p : リストの縦長を nn 行にする\n" );
       exit( 1 );
     }

   if ( (fp=xfopen( argv[1], "asm", "r")) == NULL )
     {
       fprintf( stderr, "ファイル'%s.asm'がオープンできません\n", argv[1] );
       exit( 1 );
     }

   pass(1);
   rewind(fp);
   pass(2);
   fclose(fp);

   if (err_cnt != 0) {
     fprintf( stderr, "%d 個のエラーが見つかりました。\n", err_cnt);
     exit(1);
   }

   writebin(argv[1]);    /* bin ファイルの書き出し */
   writesym(argv[1]);    /* sym ファイルの書き出し */

   return 0;
 }
