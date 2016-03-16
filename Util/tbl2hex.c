/*
 * TeC7 tbl2hex program Source Code
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
 * tbl2hex.c : tbl ファイルから hex ファイルに変換するプログラム
 *
 * 2013.12.16           : ctype.h のインクルードを追加
 * 2012.07.14           : DECODE ROM のサイズをコマンド行で指定可能に変更
 * 2011.03.05           : VHDL 出力プログラムから TEXT 出力に改造
 * 2010.07.23           : stdlib.h のインクルードを追加
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define FMAX    100    /* max fine name       */
#define LINEMAX 200    /* max line            */
#define NSYM    256    /* size of symbol tbl  */
#define DSIZ    512    /* max decode rom size */

int dsiz;              /* decode rom size     */

struct tbl_t {
  long addr;
  char sym[LINEMAX+1];
} tbl[NSYM];
int tbl_cnt;

char sym[DSIZ][LINEMAX+1];  /* decode tbl */
int mbuf[DSIZ];             /* drom       */

FILE *xfopen(char *fname, char *ext, char *mod) {
  FILE *fp;
  char buf[FMAX+1];

  if (strlen(fname)+strlen(ext)+1>FMAX) {
    fprintf(stderr,"ファイル名[%s]が長すぎます。\n",fname);
    exit(1);
  }

  sprintf(buf, "%s.%s", fname, ext);

  if ((fp=fopen(buf, mod))==NULL) {
    perror(buf);
    exit(1);
  }
  return fp;
}

void readsym(char *fname) {
  FILE *fp;
  int  i;

  fp = xfopen(fname, "sym", "r");

  for (i=0; fscanf(fp,"%08lx %s",&tbl[i].addr,tbl[i].sym)==2; i++)
    if (i>NSYM) {
      fprintf(stderr,"sym ファイルが長すぎる。\n");
      exit(1);
    }
  tbl_cnt=i;
  fclose(fp);
}

void ferr(char *buf, char *p) {
  int k;
  fprintf(stderr,"%s\n",buf);
  for (k=0; k<(p-buf); k++)
    fprintf(stderr," ");
  fprintf(stderr,"^ フォーマットエラー\n");
  exit(1);
}

void readtbl(char *fname) {
  FILE *fp;
  int  i, j;
  char buf[LINEMAX+1];
  char *p;

  fp = xfopen(fname, "tbl", "r");

  i = 0;
  while(fgets(buf,LINEMAX+1,fp)!=NULL) {
    if (strlen(buf)>=LINEMAX) {
      fprintf(stderr,"行が長すぎる。\n");
      exit(1);
    }
    p = buf;
    while(*p!='\0') {
      while(isspace(*p)) {
	p++;
      }
      if (*p=='\0' || *p==';') break;
      j=0;
      if (!isalpha(*p))
	ferr(buf,p);
      else {
	if (i>=dsiz) {
	  fprintf(stderr,"tbl が大きすぎる。\n");
	  exit(1);
	}
	while (isalpha(*p) || isdigit(*p)) {
	  sym[i][j]=toupper(*p);
	  p++;
	  j++;
	}
	sym[i][j]='\0';
	i++;
      }
      if (*p!='\0' && !isspace(*p)) {
	ferr(buf, p);
      }
    }
  }

  if (i!=dsiz) {
    fprintf(stderr,"tbl が小さすぎる。\n");
    exit(1);
  }

  fclose(fp);
}

void tbl2mbuf(void) {
  int i,j;

  for (i=0; i<dsiz; i++) {
    for (j=0; j<tbl_cnt; j++) {
      if (strcmp(sym[i],tbl[j].sym)==0) {
	mbuf[i]=tbl[j].addr;
	break;
      }
    }
    if (j>=tbl_cnt) {
      fprintf(stderr, "%s が見付からない。\n",sym[i]);
      exit(1);
    }
  }
}

void mbuf2hex(char *fname) {
  int i;
  FILE *fout;

  fout=xfopen(fname,"hex", "w");

  for (i=0; i<dsiz; i++) {
    fprintf(fout, "%02x %02x\n", i, mbuf[i]);
  }
  fclose(fout);
}

int main(int argc, char **argv) {
  int i;
  if (argc!=4) {
    fprintf(stderr,"使用方法: %s ROMSIZ <symfile> <filename>\n", argv[0]);
    exit(1);
  }

  dsiz = atoi(argv[1]);

  if (dsiz<256 || DSIZ<dsiz) {
    fprintf(stderr,"ROMサイズ(%d)が不適切,ROMサイズは256〜512\n",dsiz);
    exit(1);
  }
  readsym(argv[2]);          /* input "mrom.sym", make tbl[] */
  readtbl(argv[3]);          /* input "drom.tbl", make sym[] */
  tbl2mbuf();                /* make mbuf[](content of drom) */
  mbuf2hex(argv[3]);         /* output mbuf[] to "drom.hex"  */

  return 0;
}
