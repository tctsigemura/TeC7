/*
 * TaC IPL Source Code
 *    Tokuyama kousen Educational Computer 16 bit Version
 *
 * Copyright (C) 2009-2012 by
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
 * crt0.h : crt0.s で定義された関数を C-- から使えるようにするヘッダファイル
 *
 * 2012.09.14           : reta, ucmp, add32 〜 div32, Ld32 を追加
 * 2012.02.29           : TeC7 IPL 用に変更
 * 2010.07.20           : Subversion による管理を開始
 *
 * $Id$
 *
 */

public int in(int p);                // ワードを I/O ポートから入力する
public void out(int p, int v);       // ワードを I/O ポートへ出力する

public void[]_ItoA(int a);           // 型変換ルーチン
public int _AtoI(void[] a);          // 型変換ルーチン

public void jump(int a);             // 指定番地にジャンプ
public void halt();                  // CPU を停止する
public int  _reta();                 // reta() を呼出した関数の帰りアドレス

public int _uCmp(int a, int b);                    // 符号無しの大小比較

public int[] add32(int[] dst, int[] src);          // 32ビット加算ルーチン
public int[] sub32(int[] dst, int[] src);          // 32ビット減算ルーチン
public int[] mul32(int[] dst, int src);            // 32ビット乗算ルーチン
public int[] div32(int[] dst, int src);            // 32ビット除算ルーチン
#define Ld32(dst,h,l) ((dst)[0]=(h),(dst)[1]=(l))  // 32ビットデータの代入
