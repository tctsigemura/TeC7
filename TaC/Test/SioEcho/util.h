/*
 * TaC Kernel Source Code
 *    Tokuyama kousen Educational Computer 16bit Ver.
 *
 * Copyright (C) 2008-2010 by
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
 * util.h : C-- が動くために必要な関数群のプロトタイプ宣言
 *
 * 2010.07.20           : Subversion による管理を開始
 * 2010.03.12 v0.0.3    : public 修飾子を追加
 * 2009.11.05 v0.0.2    : バイト配列関係の関数を追加
 * 2009.11.05           : Kernel 用と Boot 用をマージしなおす
 * 2009.04.16 v0.0.1    : Boot 用に書き換え
 * 2008.08              : Kernel 用の初期バージョン
 *
 * $Id$
 *
 */

// 以下はアセンブラルーチン
// IPL ROM の呼び出し
public void ipl();                                  // IPLに戻る
public void cls();                                  // 画面クリア
public void putch(char c);                          // １文字表示
public void putstr(char[] str);                     // 文字列表示
public void _puthex(int v);                         // １６進数表示
public void readSct(int lbaH, int lbaL, char[] buf);// １セクタリード
public void _exit(int x);                           // IPLに戻る

// crt0.s に記述されているルーチン
public void ei();                                   // 割込み許可
public void di();                                   // 割込み禁止
public int in(int p);                               // ポートから入力
public void out(int p, int v);                      // ポートへ出力
public void _jump(int addr);                        // 指定番地にジャンプする

public void[] __end();                              // bss直後のアドレスを返す
public int __memsize();                             // プログラムが使用可能な
                                                    // ヒープのサイズを返す

public void[] __ItoA(int a);                        // 型変換ルーチン
public int __AtoI(void[] a);                        // 型変換ルーチン
public void[] __AddrAdd(void[] a, int i);           // アドレス計算

public int __ucmp(int a, int b);                    // 符号無しの大小比較
public int __acmp(void[] a, void[] b);              // アドレスの大小比較

public void[] __args();                             // 関数の引数配列を返す

public int[] _add32(int[] dst, int[] src);          // 32ビット加算ルーチン
public int[] _sub32(int[] dst, int[] src);          // 32ビット減算ルーチン
public int[] _mul32(int[] dst, int src);            // 32ビット乗算ルーチン
public int[] _div32(int[] dst, int src);            // 32ビット除算ルーチン
#define Ld32(dst,h,l) ((dst)[0]=(h),(dst)[1]=(l))   // 32ビットデータの代入

// 以下は、util.cmm に定義
public void puthex(int x, int w, char p);
public void putdec(int x, int w, char p);

public void[] malloc(int s);
public void free(void[] p);

public int printf(char[] fmt, ...);

 
// 16bit int 配列をバイト配列とみなして 1 バイト読み出す
public int byte(int[] b, int x); 

// 16bit int 配列をバイト配列とみなして 1 ワード読み出す
#define Word(buf, idx) ((byte((buf),(idx)+1)<<8) | byte((buf),(idx)))
