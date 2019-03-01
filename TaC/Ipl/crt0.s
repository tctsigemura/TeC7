;
; TaC IPL Source Code
;    Tokuyama kousen Educational Computer 16 bit Version
;
; Copyright (C) 2009-2019 by
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
; crt0.s : IPL(ROM版)のアセンブラ部分
;
; 2019.02.28         : wait1m を追加
; 2012.09.28         : '%' の使用を止める。(インデクスドを自動的にas--が変換)
; 2012.09.27         : as-- のバグ修正に伴い '%', '@' の使用間違えを訂正
; 2012.09.13         : TaC-CPU V2 用に書き換える
; 2010.07.20         : Subversion の管理に入る
;
; $Id$
;

;;; ここからプログラムの実行が始まる
ipl
	ld	sp,#0xf000	; 主記憶 60kB
	call	_main
	halt			; リスタート
	jmp	ipl

;; ワードを I/O ポートから入力する
_in
	ld	g1,2,sp		; val=in(port)
	in	g0,g1		; I/O ポートから入力する
	ret

;; ワードを I/O ポートへ出力する
_out
	ld	g0,2,sp         ; port
	ld	g1,4,sp         ; val
	out	g1,g0
	ret

;; アドレスと整数の型変換
__AtoI				; アドレスから整数へ変換
__ItoA				; 整数からアドレスへ変換
	ld	g0,2,sp         ; i = AtoI(p);
	ret                     ; p = ItoA(i);

;; 任意のアドレスにジャンプする
_jump
	ld	g0,2,sp		; jump(addr)
	ld	sp,#0xE000      ; RAM の最後
	jmp	0,g0		; 任意のアドレスにジャンプする

;; CPU を停止する
_halt
	halt                    ; halt()
	ret

;; 割り込み発生アドレスを調べる
__reta
	ld	g0,2,fp		; reta()を呼び出した関数にとっての帰りアドレス
	ret

;; 符号なし比較(小さい==-1、等しい==0、大きい==1)
__uCmp 				; 符号無し比較
        ld      g0,2,sp
        cmp     g0,4,sp
        ld      g0,#1
        jhi     .L1
        ld      g0,#0
        jz      .L1
        ld      g0,#-1
.L1
        ret
	
;; 32ビット加算ルーチン
_add32				; int[] add32(int[] dst, int[] src)
        ld      g0,2,sp		; ディスティネーション(アドレス)
        ld      g1,4,sp         ; ソース(アドレス)
        ld      g2,2,g0         ; ディスティネーション下位ワード
        add     g2,2,g1         ; ソース下位ワード
        st      g2,2,g0         ; ディスティネーション下位ワード
        ld      g2,0,g0         ; ディスティネーション上位ワード
        jnc     .L2
        add     g2,#1           ; キャリーがあった場合は +1 する
.L2
        add     g2,0,g1          ; ソース上位ワード
        st      g2,0,g0          ; ディスティネーション上位ワード
        ret

;; 32ビット減算ルーチン
;_sub32                          ; int[] _sub32(int[] dst, int[] src)
;        ld      g0,2,sp         ; ディスティネーション(アドレス)
;        ld      g1,4,sp         ; ソース(アドレス)
;        ld      g2,2,g0         ; ディスティネーション下位ワード
;        sub     g2,2,g1         ; ソース下位ワード
;        st      g2,2,g0         ; ディスティネーション下位ワード
;        ld      g2,0,g0         ; ディスティネーション上位ワード
;        jnc     .L3
;        sub     g2,#1           ; ボローがあった場合は -1 する
;.L3
;        sub     g2,0,g1         ; ソース上位ワード
;        st      g2,0,g0         ; ディスティネーション上位ワード
;        ret

;; 32ビットかけ算ルーチン
_mul32                          ; int[] _mul32(int[] dst, int src)
        ld      g2,2,sp         ; ディスティネーション(アドレス)
        ld      g0,2,g2         ; ディスティネーション下位ワード
        mull    g0,4,sp         ; ソース
        st      g1,0,g2         ; ディスティネーション上位ワード
        st      g0,2,g2         ; ディスティネーション下位ワード
        ld      g0,g2           ; ディスティネーションを返す
        ret

;; 32ビット割算ルーチン
_div32                          ; int[] _div32(int[] dst, int src)
        ld      g2,2,sp         ; ディスティネーション(アドレス)
        ld      g0,2,g2         ; ディスティネーション下位ワード
        ld      g1,0,g2         ; ディスティネーション上位ワード
        divl    g0,4,sp         ; ソース
        st      g1,2,g2         ; ディスティネーション下位ワード(余)
        st      g0,0,g2         ; ディスティネーション上位ワード(商)
        ld      g0,g2           ; ディスティネーションを返す
        ret

;;  1us 待つ
;;  9.8304MHz * 5 = 49.152MHz(周期=20.34505ns)
;;  
;;  1us  = 20.34505ns * 49.152 = 49ステート
;;  call = 6ステート、残り = 43 ステート
.wait1u ld      g0,g0	; 4ステート、残り = 39ステート
        ld      g0,g0	; 4ステート、残り = 35ステート
        ld      g0,g0	; 4ステート、残り = 31ステート
        ld      g0,g0	; 4ステート、残り = 27ステート
        ld      g0,g0	; 4ステート、残り = 23ステート
        ld      g0,g0	; 4ステート、残り = 19ステート
        ld      g0,g0	; 4ステート、残り = 15ステート
        no		; 3ステート、残り = 12ステート
        no		; 3ステート、残り =  9ステート
        no		; 3ステート、残り =  6ステート
        ret		; 6ステート、残り =  0ステート

;;  10us 待つ
.wait10u
        call    .wait1u
        call    .wait1u
        call    .wait1u
        call    .wait1u
        call    .wait1u
        call    .wait1u
        call    .wait1u
        call    .wait1u
        call    .wait1u	; 9us（残り= 49 - 6 = 43ステート)
        ld      g0,g0	; 4ステート、残り = 39ステート
        ld      g0,g0	; 4ステート、残り = 35ステート
        ld      g0,g0	; 4ステート、残り = 31ステート
        ld      g0,g0	; 4ステート、残り = 27ステート
        ld      g0,g0	; 4ステート、残り = 23ステート
        ld      g0,g0	; 4ステート、残り = 19ステート
        ld      g0,g0	; 4ステート、残り = 15ステート
        no		; 3ステート、残り = 12ステート
        no		; 3ステート、残り =  9ステート
        no		; 3ステート、残り =  6ステート
        ret		; 6ステート、残り =  0ステート

;;  100us 待つ
.wait100u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        call    .wait10u
        ret

;;  1ms 待つ
_wait1m
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        call    .wait100u
        ret