/*
 * TeC6 Micro Code Assenbler Program
 *    Tokuyama kousen Educational Computer Ver.7
 *
 * Copyright (C) 2002-2011 by
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
 * masm.c : マイクロコードアセンブラ
 *
 * 2011.10.19           : マイクロコード ROM を256ワードに変更
 * 2010.07.23           : エラー発生を終了コードとメッセージで知らせる,
 *                        default の綴り間違え修正,
 *                        stdlib.h のインクルードを追加,
 *                        MS-DOSを意識した ifdef 廃止
 * 2006.11.15           : リストの先頭に空白が入るバグをとる
 *
 */

#include "edu.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>
#include <ctype.h>

/* 定数 */
#define MSIZ     128       /* マイクロコード ROM のワード数 */
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
#define ERR      1007      /* Error */
#define STI      1008      /* Set   Interrupt */
#define CLI      1009      /* Clear Interrupt */
#define ALU      1010
#define LD       1011
#define BUS      1012
#define HALT     1013
#define JOP      1014
#define J        1015
#define JCC      1016
#define NO       1017

/* ALU 命令の機能 */
#define REG      1020
#define ADD      1021
#define SUB      1022
#define INC      1023
#define DEC      1024
#define AND      1025
#define OR       1026
#define XOR      1027
#define SFT	 1028
#define OUTF     1029
#define INF      1030
#define ZERO     1031      /* ZERO が最後であること */
#define FNUM(f)  ((f)-REG)

/* JCC 命令の条件 */
#define INT      1040
#define JP       1041
#define NJP      1042
#define DI       1043
#define STP      1044

/* バス命令の機能 */
#define IOREQ    1050      /* IO Request            */
#define MREQ     1051      /* Memory Request        */
#define OE       1052      /* Bus Output Enable     */
#define LDDR     1053      /* Load Instruction Reg  */
#define LDIR     1054      /* Load Data Reg         */

/* レジスタ */
#define SP       2000
#define PC       2001
#define RD       2002
#define RX       2003
#define DR       2004
#define IR       2005
#define AR       2006
#define OPR      2007
#define FL       2008
#define RNUM(r)  ((r)-SP)

/* トークンの一覧表 */
struct word_tok_t 
{
  char *str;
  int   num;
} word_tok[] =
{ /* 命令 */
  { "NO",    NO   },  { "ERR",   ERR  },
  { "STI",   STI  },  { "CLI",   CLI  },
  { "ALU",   ALU  },  { "LD",    LD   },
  { "BUS",   BUS  },  { "HALT",  HALT },
  { "JOP",   JOP  },  { "J",     J    }, 
  { "JCC",   JCC  },

  /* ALU 命令 */
  { "REG",   REG  },  { "ADD",   ADD  },
  { "SUB",   SUB  },  { "INC",   INC  },
  { "DEC",   DEC  },  { "AND",   AND  },
  { "OR",    OR   },  { "XOR",   XOR  },
  { "OUTF",  OUTF },  { "INF",   INF  },
  { "SFT",   SFT  },  { "ZERO",  ZERO },

  /* JCC 命令 */
  { "INT",   INT  },  { "JP",    JP   },
  { "NJP",   NJP  },  { "DI",    DI   },
  { "STP",   STP  },

  /* BUS 命令 */
  { "IOREQ", IOREQ},  { "MREQ",  MREQ },
  { "LDDR",  LDDR },  { "LDIR",  LDIR },
  { "OE",    OE   },

  /* レジスタ */
  { "SP",    SP   },  { "PC",    PC   },
  { "RD",    RD   },  { "RX",    RX   },
  { "DR",    DR   },  { "IR",    IR   },
  { "AR",    AR   },  { "OPR",   OPR  },
  { "FL",    FL   },
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
int aluuse, bususe, jumpuse, lduse, haltuse, erruse, stiuse, cliuse;

/* そのほか */
FILE *fp;                     /* ソースファイル */
int nextch, nexttok;          /* 現在の文字／トークン */
int lc;                       /* ロケーションカウンタ */
int vc;                       /* ベクタ用のカウンタ */
char lbuf[LINEMAX+1];         /* 読み込んだソースをためて置くバッファ */
int lbuf_cnt;                 /* バッファ内のカウンタ */
unsigned long mcode;          /* マイクロコードを組み立てるためのバッファ */
unsigned long mbuf[MSIZ];     /* VHDL 出力関係 2002.6.24*/
char label[STRMAX+1];         /* ラベル用のバッファ */
char *errmes;                 /* エラー発生時にエラーメッセージを記憶 */
int err_cnt = 0;              /* エラーの発生回数 */
int width = LINEDEF;          /* リストの１行の長さ */
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

  if (lc < MSIZ) mbuf[lc] = mcode;             /* VHDL 出力関係 2002.6.24*/

  if ( l_form==0 )
    {
      if ( line_cnt == 0 )
        {
          printf( "ADR CODE    Label   Command %42s Page(%d)\n\n",
                  "", ++page_cnt );
          line_cnt += 2;
        }
        
      lbuf[width - 14] = '\0';
      if ( x )
	printf( "%02X %08lX %s\n", lc, mcode, lbuf );
      else
        printf( "%02X %8s %s\n", lc, "", lbuf );
    }
  else
    {
      if ( line_cnt == 0 )
        {
          printf( "A  A R W L L L L L L H E S C R M I J J\n" );
          printf( "D  L R R R F A O D I L R T L W R R P A %32s Page(%d)\n",
                  "", ++page_cnt );
          printf( "R  U                     I I\n" );
          line_cnt += 3;
        }
               
      lbuf[width - 41] = '\0';
      
      if ( x )
        printf(
        "%02X %X %X %X %x %x %x %x %x %x %x %x %x %x %x %x %x %X %02X %s\n",
            lc,RM_ALU(mcode),RM_RR(mcode),RM_WR(mcode),RM_LR(mcode),
            RM_LF(mcode),RM_LA(mcode),RM_LO(mcode),RM_LD(mcode),RM_LI(mcode),
            RM_HL(mcode),RM_ER(mcode),RM_STI(mcode),RM_CLI(mcode),RM_RW(mcode),
            RM_MR(mcode),RM_IR(mcode),RM_JP(mcode),RM_JA(mcode), lbuf
               );
      else
        printf( "%02X %36s %s\n", lc, "", lbuf );
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

  if ( isalpha( nextch ) )
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

/*  ALU 命令を処理する
*/
struct alu_tbl_t
{
  int alu;
  int rr;
} alu_tbl[][5] =
{/*f\r             SP                PC                Rd
                                     Rx                DR    */
 /*REG*/{{AL_A,    RS_SP}, {AL_A,    RS_PC}, {AL_A,    RS_Rd},
	                   {AL_A,    RS_Rx}, {AL_B,    RS_NO}    },
 /*ADD*/{{AL_ADD,  RS_SP}, {AL_ADD,  RS_PC}, {AL_ADD,  RS_Rd},
	                   {AL_ADD,  RS_Rx}, {ERROR,   ERROR}    },
 /*SUB*/{{AL_SUB,  RS_SP}, {AL_SUB,  RS_PC}, {AL_SUB,  RS_Rd},
                           {AL_SUB,  RS_Rx}, {ERROR,   ERROR}    },
 /*INC*/{{AL_INC,  RS_SP}, {AL_INC,  RS_PC}, {AL_INC,  RS_Rd},
                           {AL_INC,  RS_Rx}, {ERROR,   ERROR}    },
 /*DEC*/{{AL_DEC,  RS_SP}, {AL_DEC,  RS_PC}, {AL_DEC,  RS_Rd},
                           {AL_DEC,  RS_Rx}, {ERROR,   ERROR}    },
 /*AND*/{{AL_AND,  RS_SP}, {AL_AND,  RS_PC}, {AL_AND,  RS_Rd},
                           {AL_AND,  RS_Rx}, {ERROR,   ERROR}    },
 /*OR */{{AL_OR,   RS_SP}, {AL_OR,   RS_PC}, {AL_OR,   RS_Rd},
                           {AL_OR,   RS_Rx}, {ERROR,   ERROR}    },
 /*XOR*/{{AL_XOR,  RS_SP}, {AL_XOR,  RS_PC}, {AL_XOR,  RS_Rd},
                           {AL_XOR,  RS_Rx}, {ERROR,   ERROR}    },
 /*SFT*/{{AL_SFT,  RS_SP}, {AL_SFT,  RS_PC}, {AL_SFT,  RS_Rd},
                           {AL_SFT,  RS_Rx}, {ERROR,   ERROR}    },
/*OUTF*/{{AL_OUTF, RS_NO}, {ERROR,   ERROR}, {ERROR,   ERROR},
                           {ERROR,   ERROR}, {ERROR,   ERROR}    },
 /*INF*/{{AL_INF,  RS_NO}, {ERROR,   ERROR}, {ERROR,   ERROR},
                           {ERROR,   ERROR}, {ERROR,   ERROR}    },
/*ZERO*/{{AL_ZERO, RS_NO}, {ERROR,   ERROR}, {ERROR,   ERROR},
                           {ERROR,   ERROR}, {ERROR,   ERROR}    }
};

void alu()
{
  int f,r,t;

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

  if ( f==FNUM(ZERO) || f==FNUM(OUTF) || f==FNUM(INF) )
    {
      WM_ALU(mcode,alu_tbl[f][0].alu);
      WM_RR (mcode,alu_tbl[f][0].rr );
      if ( f==FNUM(INF) ) WM_LF(mcode,1);
      gettok();
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
      
      if ( gettok() == ',' )
	{
	  getexp(FL,"ALU 命令の FL 指定部に FL 以外が書かれた");
	  WM_LF(mcode,1);
	  gettok();
	}
    }

  if ( nexttok != ')' )
    errmes = "ALU のパラメータの最後に ')' がない";
}

/*  LD 命令を処理する
*/
/* wrフィールドとレジスタの対応  SP     PC     Rd     Rx */
static int wr_tbl[] =          { RS_SP, RS_PC, RS_Rd, RS_Rx };

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
    else if ( 0<=RNUM(r) && RNUM(r)<=RNUM(RX) ) {
      WM_WR(mcode,wr_tbl[RNUM(r)]);
      WM_LR(mcode,1);
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

  do {
    switch (gettok()) {
    case IOREQ: WM_IR(mcode,1); break;
    case MREQ:  WM_MR(mcode,1); break;
    case LDDR:  WM_LD(mcode,1); break;
    case LDIR:  WM_LI(mcode,1); break;
    case OE:    WM_RW(mcode,1); break;
    default : errmes = "BUS 命令のオペランドが不正";
      return;
    }
  } while ( gettok()==',' );

  if ( nexttok != ')')
    errmes = "BUS 命令の最後に ')' がない";
}

/*  HALT 命令を処理する
*/
void halt()
{
  if ( haltuse++ )
    {
      errmes = "HALT 命令が複数ある";
      return;
    }
  WM_HL(mcode,1);
}

/*  ERR 命令を処理する
*/
void err()
{
  if ( erruse++ )
    {
      errmes = "ERR 命令が複数ある";
      return;
    }
  WM_ER(mcode,1);
}

/*  SI 命令を処理する
*/
void sti()
{
  if ( stiuse++ )
    {
      errmes = "STI 命令が複数ある";
      return;
    }
  WM_STI(mcode,1);
}

/*  CLI 命令を処理する
*/
void cli()
{
  if ( cliuse++ )
    {
      errmes = "CLI 命令が複数ある";
      return;
    }
  WM_CLI(mcode,1);
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
    case INT: WM_JP(mcode,J_INT); break;
    case JP : WM_JP(mcode,J_JP);  break;
    case NJP: WM_JP(mcode,J_NJP); break;
    case DI : WM_JP(mcode,J_DI);  break;
    case STP :WM_JP(mcode,J_STP); break;
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
  getchr();    /* lbuf_cnt が１文字進む */
  lbuf_cnt=0;
  lc = 0;

  while ( nextch != EOF )
    {
      int cnt;
      
      errmes = NULL;
      aluuse=bususe=jumpuse=lduse=haltuse=erruse=stiuse=cliuse=0;
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
	    case NO  :
	    case ',' : break;
	    case ALU : alu(); break;
	    case LD  : ld();  break;
	    case BUS : bus(); break;
	    case HALT: halt();break;
	    case ERR : err(); break;
	    case STI : sti(); break;
	    case CLI : cli(); break;
	    case JOP : jop(); break;
	    case J   : j();   break;
	    case JCC : jcc(); break;
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
  
  for(i=0; i<MSIZ; i++) {
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
       else if ( strcmp( "-w", argv[1] )==0 )
         {
           sscanf( argv[2], "%d", &width );
           if ( width <= LINEDEF || LINEMAX < width )
             width = LINEDEF;
           argc--;
           argv++;
         }
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
       fprintf( stderr, "使い方: %s [-l] [-w nn] [-p nn] <source_file>\n",
                name );
       fprintf( stderr, "   -l : リストを詳細な形式にする\n" );
       fprintf( stderr, "   -w : リストの横幅を nn 文字にする\n" );
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
