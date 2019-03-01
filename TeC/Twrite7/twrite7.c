/*
 * TeC7 Tsend7 Program
 *    Tokuyama kousen Educational Computer Ver.7
 *
 * Copyright (C) 2002-2019 by
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
 */

/*
 * バイナリファイルを RS-232C に送り出すプログラム(FreeBSD-6〜, MacOSX 用)
 */

#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>

#define  COM "/dev/cuaU0"

void errexit(char *s) {
  perror(s);
  exit(1);
}

int main(int argc, char **argv) {
  struct termios st, stb;
  char   buf;
  int    fd,c;
  char   *com;
  FILE   *fp;

  if (argc==2) {
    com = COM;
  } else if (argc==3) {
    com = argv[2];
  } else {
    fprintf(stderr, "使用方法 : %s file [com_port]\n", argv[0]);
    exit(1);
  }

  if ((fp=fopen(argv[1], "r"))==NULL)
    errexit(argv[1]);

  if ((fd=open(com, O_RDWR))<0)
    errexit(com);

  //if (tcsetpgrp(fd, getpgrp())<0)
  //  errexit(com);

  /* RS232C ポートのモード変更 */
  if (tcgetattr(fd, &st)<0)
    errexit(com);

  stb = st;
  cfsetspeed(&st, B9600);
  cfmakeraw(&st);

  st.c_cflag &= ~CSIZE;
  st.c_cflag |= CS8;      /* 8bit */
  st.c_cflag &= ~CSTOPB;  /* 1 stop bit */
  st.c_cflag &= ~PARENB;  /* non parity */
  st.c_cflag |= CLOCAL;   /* ignore modem status lines */

  if(tcsetattr(fd, TCSANOW, &st ) < 0)
    errexit(com);

  /* 送信開始 */
  write(fd,"\033TWRITE\r\n", 9);

  /* binファイルを送信 */
  while ((c=getc(fp))!=EOF) {
    printf("[%02x]",c);
    fflush(stdout);
    buf = c;
    if (write(fd,&buf,1)!=1) {
      perror("write");
      exit(1);
    }
    usleep(1050);            // 2018.7.17 書き込みがオーバーランする現象が
  }                          // 何かの条件で起こることがあった．
  printf("\n");

  /* もとに戻す。 */
  if(tcsetattr(fd, TCSANOW, &stb ) < 0)
    errexit(com);

  close(fd);
  return 0;
}
