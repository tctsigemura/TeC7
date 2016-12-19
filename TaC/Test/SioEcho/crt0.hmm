/*
 * TacOS Source Code
 *    Tokuyama kousen Advanced educational Computer
 *
 * Copyright (C) 2008-2016 by
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
 * util/crt0.h :crt0.s の外部インターフェイス
 *
 * 2016.01.20 : _fp() を追加
 * 2016.01.19 : Ld32 と St32 を ld32 と st32 に変更
 * 2015.12.30 : St32 追加(重村)
 * 2015.09.02 : __AtoA 追加(重村)
 * 2014.05.07 : 村田開発開始
 * 2013.01.08 : ENINT, PRVLG 追加
 * 2012.12.26 : halt() 追加
 * 2012.09.20 : TaC-CPU V2 対応
 * 2012.03.02 : util.h から分離、新規作成
 *
 * $Id$
 */

// 特殊な命令を使用する関数
#define EI   0x0080                                 // 割込み許可
#define DI   0x0000                                 // 割込み不許可
#define KERN 0x0040                                 // カーネルモード
#define USER 0x0000                                 // ユーザモード
public int setPri(int l);                           // フラグ値の変更
public int in(int p);                               // ポートから入力
public void out(int p, int v);                      // ポートへ出力
public void halt();                                 // CPU を停止
public int _fp();                                   // FP を返す

// C-- をサポートする関数
public int    _AtoI(void[] a);                      // 型変換ルーチン
public void[] _AtoA(void[] a);                      // 型変換ルーチン
public void[] _ItoA(int a);                         // 型変換ルーチン
public void[] _addrAdd(void[] a, int i);            // アドレス計算
public int    _uCmp(int a, int b);                  // 符号無しの大小比較
public int    _aCmp(void[] a, void[] b);            // アドレスの大小比較
public void[] _args();                              // 関数の引数配列を返す
public int[]  _add32(int[] dst, int[] src);         // 32bit の加算ルーチン
public int[]  _sub32(int[] dst, int[] src);         // 32bit の減算ルーチン
public int[]  _mul32(int[] dst, int src);           // 32bit の乗算ルーチン
public int[]  _div32(int[] dst, int src);           // 32bit の除算ルーチン
#define ld32(dst,h,l) ((dst)[0]=(h),(dst)[1]=(l))   // 32bit のデータのロード
#define st32(h,l,src) ((h)=(src)[0],(l)=(src)[1])   // 32bit のデータのストア
