/*
 * TeC7 bin2hex program Source Code
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
 * bin2hex16.c : TaC の bin ファイルから hex ファイルに変換するプログラム
 *
 */

#include <stdio.h>
#include <stdlib.h>

int get16(FILE *fp) {
  int ch1;
  int ch2;
  ch1 = fgetc(fp);
  ch2 = fgetc(fp);
  if (ch1==EOF || ch2==EOF) return EOF;
  return ((ch1 & 0xff) << 8) | (ch2 & 0xff);
}

// bin ファイルから配列に読み込む
void copyFile(char *fname, int size) {
  FILE *fp;
  int ch;
  int addr;
  int len;

  fp = fopen(fname, "rb");
  if (fp==NULL) {
    perror(fname);
    exit(1);
  }

  addr = get16(fp);                // ロードアドレス
  len  = get16(fp);                // バイナリの長さ

  if ((len & 1)!=0) {
    fprintf(stderr, "bin ファイルのサイズ(%04x)が奇数\n", len);
    exit(1);
  }

  len  = len  / 2;                 // ワード単位に変換
  size = size / 2;                 // ワード単位に変換
  size = size - len;

  if (size < 0) {
    fprintf(stderr, "メモリサイズより bin ファイルが大きい\n");
    exit(1);
  }

  while (len > 0 && (ch=get16(fp))!=EOF) {
    printf("%04x %04x\n", addr, ch);
    addr+=2;
    len--;
  }

  if (len != 0) {
    fprintf(stderr, "bin ファイルのフォーマットに異常\n");
    exit(1);
  }

  while (size-- > 0) {
    printf("%04x %04x\n", addr, 0);
    addr+=2;
  }
    
  fclose(fp);
}

void usage(char *name) {
  fprintf(stderr, "TaC bin 形式を VHDL の readline 用の16進表示に変換\n");
  fprintf(stderr, "使い方 : %s <binファイル> <メモリサイズ>\n", name);
}

int main(int argc, char *argv[]) {
  int i;

  if (argc!=3) {
    usage(argv[0]);
    exit(1);
  }

  int size = strtol(argv[2],NULL,0);
  if (size<=0) {
    usage(argv[0]);
    exit(1);
  }

  if ((size & 1)!=0) {
    fprintf(stderr, "メモリサイズ(%04x)が奇数\n", size);
    exit(1);
  }

  copyFile(argv[1], size);
  return 0;
}
