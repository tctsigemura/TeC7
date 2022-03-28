/*
 * TaC IPL Source Code
 *    Tokuyama kousen Educational Computer 16 bit Version
 *
 * Copyright (C) 2009-2013 by
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
 * util.h : crt0.s で定義された関数を C-- から使えるようにするヘッダファイル
 *
 * 2013.01.07           : TaC-CPU V2 に対応
 * 2010.07.20           : Subversion による管理を開始
 *
 * $Id$
 *
 */

public void wait1u();                           // 1 マイクロ秒待つ
public void wait10u();                          // 10マイクロ秒待つ
public void wait100u();                         // 100マイクロ秒待つ
public void wait1m();                           // 1ミリ秒待つ

public int in(int p);                           // I/O ポートから入力する
public void out(int p, int v);                  // I/O ポートへ出力する

public void[] _ItoA(int a);                     // 型変換ルーチン
public int _AtoI(void[] a);                     // 型変換ルーチン

public void jump(int a);                       // 指定番地にジャンプ
public void halt();                            // CPU を停止する
public void setPri(int flg);                   // CPU フラグに値をセットする
public void svc();                             // SVC 命令を実行する
public void setJmp(int pc, int flag);          // モードを切替えてジャンプする
