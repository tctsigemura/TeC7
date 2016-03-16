/*
 * TeC7 hex2txt program Source Code
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
 * hex2txt.c : hex ファイルから txt ファイルに変換するプログラム
 */

#include <stdio.h>
#include <stdlib.h>

void printBin(unsigned long d, int w) {
  while (w>0) {
    putchar((d & (1<<(w-1)))!=0 ? '1' : '0');
    w--;
  }
}

int main(int argc, char *argv[]) {
  unsigned long a, d;
  int aw, dw;

  if (argc!=3) {
    fprintf(stderr, "Usage : %s addr_width data_width\n", argv[0]);
    fprintf(stderr, "        addr_width > 0\n");
    fprintf(stderr, "        data_width > 0\n");
    exit(1);
  }

  if ((aw = atoi(argv[1]))<1) {
    fprintf(stderr, "%s : need integer", argv[1]);
    exit(1);
  }

  if ((dw = atoi(argv[2]))<1) {
    fprintf(stderr, "%s : need integer", argv[2]);
    exit(1);
  }

  while (scanf("%lx %lx\n", &a, &d)==2) {
    // printBin(a, aw);
    // putchar(' ');
    printBin(d, dw);
    putchar('\n');
  }

  return 0;
}
