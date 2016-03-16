/*
 * TaC IPL Source Code
 *    Tokuyama kousen Educational Computer 16bit Ver.
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
 * console.h : TaC IPL の画面制御部分
 *
 * 2012.02.29           : cls を追加
 * 2012.01.08 v1.0.0    : console.cmm の外部インタフェース
 *
 * $Id$
 *
 */

public void cls();                          // 画面クリア
public void putch(char c);                  // 1文字表示
public void putstr(char[] str);             // 文字列表示
public void _puthex(int x);                 // 16進数4桁で表示
public void consInit();                     // 画面出力の初期化
