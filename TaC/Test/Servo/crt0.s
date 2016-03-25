;
; TaC Test Source Code
;    Tokuyama kousen Educational Computer 16 bit Version
;
; Copyright (C) 2009-2011 by
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
; crt0.s : PIO テストプログラムのアセンブラ部分
;
; 2012.01.11         : 初期バージョン
;
; $Id$
;

start	ld	sp,#0x7000	; 主記憶 28kW
	call	_main
	halt			; リスタート

; 1us 待つ
; 1us  = 20ns * 50 = 50ステート
; call = 9ステート、残り = 41 ステート
_wait1u ld	g0,g0		; 5ステート、残り = 36ステート
	ld	g0,g0		; 5ステート、残り = 31ステート
	ld	g0,g0		; 5ステート、残り = 26ステート
	ld	g0,g0		; 5ステート、残り = 21ステート
	ld	g0,g0		; 5ステート、残り = 16ステート
	no			; 4ステート、残り = 12ステート
	no			; 4ステート、残り =  8ステート
	ret			; 8ステート、残り =  0ステート
	
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
	ld	g0,g0		; 5ステート、残り = 45ステート
	ld	g0,g0		; 5ステート、残り = 40ステート
	ld	g0,g0		; 5ステート、残り = 35ステート
	ld	g0,g0		; 5ステート、残り = 30ステート
	ld	g0,g0		; 5ステート、残り = 25ステート
	ld	g0,g0		; 5ステート、残り = 20ステート
	no			; 4ステート、残り = 16ステート
	no			; 4ステート、残り = 12ステート
	no			; 4ステート、残り =  8ステート
	ret			; 8ステート、残り =  0ステート

; 100us 待つ
; (8ステート超過)
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

_in	push	g1		; val=in(port)
	ld	g1,2,sp		; I/O ポートから入力する
	in	g0,g1
	pop	g1
	ret

_out	push	g0		; out(port,val)
	push	g1		; I/O ポートへ出力する
	ld	g0,3,sp
	ld	g1,4,sp
	out	g1,g0
	pop	g1
	pop	g0
	ret

___AtoI				; アドレスから整数へ変換
___ItoA				; 整数からアドレスへ変換
	ld	g0,1,sp
	ret

_jump	ld	g1,1,sp		; jump(addr)
	ld	sp,#0x7000      ; RAM の最後
	jmp	0,g1		; 任意のアドレスにジャンプする

_halt	halt			; halt()