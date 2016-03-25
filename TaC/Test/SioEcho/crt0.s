;
; TaC Kernel Source Code
;    Tokuyama kousen Educational Computer 16 bit Version
;
; Copyright (C) 2009-2010 by
;                      Dept. of Computer Science and Electronic Engineering,
;                      Tokuyama College of Technology, JAPAN
;
;   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
; 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
; コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
; 布することを無償で許諾する．
;
;   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
; 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
; も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
; る損害に関しても，その責任を負わない．
;
;
; crt0.s : ブートプログラム、カーネル兼用の C-- スタートアップ
; 
; 2010.07.20         : Subversion の管理に入る
; 2009.11.05         : Boot 用と Kernel 用をマージしなおす
; 2009.05.13  v0.1.1 : v0.1.0 から ei(), di() をバックポート
;
; $Id$
;
;
start				; IPL からここにジャンプしてくる
	st	sp,.sp		; SP の値を保存しておく
	call	___cstart
	call	_main
	jmp	_ipl

.sp	ws	1		; SP の保存領域

_ei				; 割込み許可
	ei
	ret

_di				; 割込み禁止
	di
	ret

__exit
_ipl	jmp	0xf800		; ROMモニタに戻る

_cls	jmp	0xf802		; 画面クリア

_putch
	jmp	0xf804		; １文字表示

_putstr	jmp	0xf806		; 文字列表示

__puthex
	jmp	0xf808		; １６進数表示(cmm 版を優先)

_readSct
	jmp	0xf80a		; １セクタ読み込み

__jump  ld      g1,1,sp         ; _jump(int addr)
	ld	sp,.sp		; 最初に保存した値に戻す
        jmp     0,g1            ; 任意のアドレスにジャンプする

_in				; 指定ポートから入力
	push    g1		; int in(int port)
        ld      g1,2,sp
        in      g0,g1
        pop     g1
        ret

_out				; 指定ポートに出力
	push    g0		; void out(int port, int val)
        push    g1
        ld      g0,3,sp
        ld      g1,4,sp
        out     g1,g0
        pop     g1
        pop     g0
        ret

___AtoI				; アドレスから整数へ変換
___ItoA				; 整数からアドレスへ変換
	ld	g0,1,sp
	ret

___end  ld      g0,#__end       ; BSSセグメントの最後のアドレス
        ret

___memsize
	ld	g0,sp	        ; スタックに 2KW を割り当てて
        sub     g0,#2048        ; 残りをヒープとして使用する
        sub     g0,#__end       ; ヒープのサイズを求める
        ret

___AddrAdd                      ; アドレス演算
        ld      g0,1,sp
        add     g0,2,sp
        ret

___ucmp                         ; 符号無し比較
___acmp                         ; アドレス比較
        ld      g0,1,sp
        cmp     g0,2,sp
        ld      g0,#1
        jhi     .L1
        ld      g0,#0
        jz      .L1
        ld      g0,#-1
.L1
        ret

___args                         ; 呼び出したC--関数の第2引数のアドレスを返す
        ld      g0,fp
        add     g0,#3
        ret

__add32				; 32ビット加算ルーチン
	push	g1		; int[] _add32(int[] dst, int[] src)
	push	g2
	ld      g1,3,sp		; ディスティネーション(アドレス)
	ld      g2,4,sp		; ソース(アドレス)
	ld	g0,1,g1		; ディスティネーション下位ワード
        add     g0,1,g2		; ソース下位ワード
	st	g0,1,g1		; ディスティネーション下位ワード
	ld	g0,0,g1		; ディスティネーション上位ワード
	jnc	.L2
	add	g0,#1		; キャリーがあった場合は +1 する
.L2
	add	g0,0,g2		; ソース上位ワード
	st	g0,0,g1		; ディスティネーション上位ワード
	ld	g0,g1		; ディスティネーションを返す
	pop	g2
	pop	g1
	ret

__sub32				; 32ビット減算ルーチン
	push	g1		; int[] _sub32(int[] dst, int[] src)
	push	g2
	ld      g1,3,sp		; ディスティネーション(アドレス)
	ld      g2,4,sp		; ソース(アドレス)
	ld	g0,1,g1		; ディスティネーション下位ワード
        sub     g0,1,g2		; ソース下位ワード
	st	g0,1,g1		; ディスティネーション下位ワード
	ld	g0,0,g1		; ディスティネーション上位ワード
	jnc	.L3
	sub	g0,#1		; ボローがあった場合は -1 する
.L3
	sub	g0,0,g2		; ソース上位ワード
	st	g0,0,g1		; ディスティネーション上位ワード
	ld	g0,g1		; ディスティネーションを返す
	pop	g2
	pop	g1
	ret

__mul32				; 32ビットかけ算ルーチン
	push	g1		; int[] _mul32(int[] dst, int src)
	push	g2		; (dst[0],dst[1]) <- dst[1] * src
	push	g3
	ld      g1,4,sp		; ディスティネーション(アドレス)
	ld	g2,1,g1		; ディスティネーション下位ワード
	mul	g2,5,sp		; ソース
	st	g3,0,g1		; ディスティネーション上位ワード
	st	g2,1,g1		; ディスティネーション下位ワード
	ld	g0,g1		; ディスティネーションを返す
	pop	g3
	pop	g2
	pop	g1
	ret

__div32				; 32ビット割算ルーチン
	push	g1		; int[] _div32(int[] dst, int src)
	push	g2		; dst[0] <- dst / src
	push	g3		; dst[1] <- dst % src
	ld      g1,4,sp		; ディスティネーション(アドレス)
	ld	g2,1,g1		; ディスティネーション下位ワード
	ld	g3,0,g1		; ディスティネーション上位ワード
	div	g2,5,sp		; ソース
	st	g3,1,g1		; ディスティネーション下位ワード(余)
	st	g2,0,g1		; ディスティネーション上位ワード(商)
	ld	g0,g1		; ディスティネーションを返す
	pop	g3
	pop	g2
	pop	g1
	ret
