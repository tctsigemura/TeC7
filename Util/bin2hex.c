/*
 * TeC7 bin2hex program Source Code
 *    Tokuyama kousen Educational Computer Ver.7
 *
 * Copyright (C) 2002-2013 by
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
 * bin2hex.c : 複数の bin ファイルから hex ファイルに変換するプログラム
 *
 */



#include <stdio.h>
#include <stdlib.h>

unsigned char ram[256];

// 配列をクリアする
void clearRam(void) {
  int i;
  for (i=0; i<256; i++)
    ram[i] = 0;
}

// bin ファイルから配列に読み込む
void readFile(char *fname) {
  FILE *fp;
  int ch;
  int addr;
  int len;

  fp = fopen(fname, "rb");
  if (fp==NULL) {
    perror(fname);
    exit(1);
  }

  addr = fgetc(fp) & 0xff;          // ロードアドレス
  len  = fgetc(fp) & 0xff;          // バイナリの長さ

  while (len > 0 && (ch=fgetc(fp))!=EOF) {
    ram[addr++] = ch;
    len--;
  }

  if (len > 0) {
    fprintf(stderr, "bin ファイルのフォーマットに異常\n");
    exit(1);
  }

  fclose(fp);
}

// 配列から TEXT 形式で書き出す
void writeText(void) {
  static int addr = 0;
  int i;

  for (i=0; i<256; i++) {
    printf("%03x %02x\n", addr, ram[i]);
    addr++;
  }
}

int main(int argc, char *argv[]) {
  int i;

  if (argc<2) {
    fprintf(stderr, "TeC bin 形式を VHDL の readline 用の16進表示に変換\n");
    fprintf(stderr, "使い方 : %s <binファイル>...\n", argv[0]);
    exit(1);
  }

  for (i=1; i<argc; i++) {
    clearRam();
    readFile(argv[i]);
    writeText();
  }

  return 0;
}
