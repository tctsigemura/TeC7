;
; TaC Test Source Code
;    Tokuyama kousen Educational Computer 16 bit Version
;
; Copyright (C) 2009-2013 by
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
; crt0.s : テストプログラムのアセンブラ部分
;
; 2013.01.07         : TeC-CPU V2 対応
; 2012.01.11         : 初期バージョン
;
; $Id$
;

start	ld	sp,#0xe000	; 主記憶 58kb
	call	_main
	halt			; リスタート

; 1us 待つ
; 1us  = 20ns * 50 = 50ステート
; call = 6ステート、残り = 44 ステート
_wait1u	ld	g0,g0		; 4ステート、残り = 40ステート
	ld	g0,g0		; 4ステート、残り = 36ステート
	ld	g0,g0		; 4ステート、残り = 32ステート
	ld	g0,g0		; 4ステート、残り = 28ステート
	ld	g0,g0		; 4ステート、残り = 24ステート
	ld	g0,g0		; 4ステート、残り = 20ステート
	ld	g0,g0		; 4ステート、残り = 16ステート
	ld	g0,g0		; 4ステート、残り = 12ステート
	no			; 3ステート、残り =  9ステート
	no			; 3ステート、残り =  6ステート
	ret			; 6ステート、残り =  0ステート
	
; 10us 待つ
_wait10u
	call	_wait1u
	call	_wait1u
	call	_wait1u
	call	_wait1u
	call	_wait1u
	call	_wait1u
	call	_wait1u
	call	_wait1u
	call	_wait1u		; 9us
	ld	g0,g0		; 4ステート、残り = 46ステート
	ld	g0,g0		; 4ステート、残り = 42ステート
	ld	g0,g0		; 4ステート、残り = 38ステート
	ld	g0,g0		; 4ステート、残り = 34ステート
	ld	g0,g0		; 4ステート、残り = 30ステート
	ld	g0,g0		; 4ステート、残り = 26ステート
	ld	g0,g0		; 4ステート、残り = 22ステート
	ld	g0,g0		; 4ステート、残り = 18ステート
	no			; 3ステート、残り = 15ステート
	no			; 3ステート、残り = 12ステート
	no			; 3ステート、残り =  9ステート
	no			; 3ステート、残り =  6ステート
	ret			; 6ステート、残り =  0ステート

; 100us 待つ
_wait100u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	call	_wait10u
	ret

; 1ms 待つ
; (88ステート(1.8us)超過)
_wait1m
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	call	_wait100u
	ret

;; ワードを I/O ポートから入力する
_in                             ; int in(int p);
        ld      g1,2,sp         ; ポートアドレス
        in      g0,g1           ; I/O ポートから入力する
        ret

;; ワードを I/O ポートへ出力する
_out                            ; void out(int p, int v);
        ld      g0,2,sp         ; ポートアドレス
        ld      g1,4,sp         ; 出力データ
        out     g1,g0           ; I/O ポートへ出力する
        ret

__AtoI				; アドレスから整数へ変換
__ItoA				; 整数からアドレスへ変換
	ld	g0,2,sp
	ret

_jump	ld	g1,2,sp		; jump(addr)
	ld	sp,#0xe000      ; RAM の最後
	jmp	0,g1		; 任意のアドレスにジャンプする

_halt	halt			; halt()
	jmp	_halt

_setPri                         ; プロセッサの割り込みレベルを変更
        ld      g0,2,sp         ; 引数の値を G0 に取り出す
        push    g0              ; 新しい状態をスタックに積み
        ld      g0,flag         ; 古いフラグの値を返す準備をする
        reti                    ; reti は flag と PC を同時に pop する

_svc				; SVC命令を実行する
	svc			; svc命令
	ret

_setJmp				; ユーザモードで実行する
	ld	g0,2,sp		; 実行開始アドレス
	push	g0
	ld	g0,6,sp		; 実行時のフラグ
	push	g0
	reti			; PCとフラグを切り替える

