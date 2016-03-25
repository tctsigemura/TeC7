;;; 
;;; CPU の機械語命令とアセンブラ(as--)のテスト
;;; 
start	halt			; 読みこまれたあと一旦停止
	ld	g0,#1		; ショートイミディエイト
	ld	g1,#-8		; 負のショートイミディエイト
	ld	g2,#a
	st	g0,@g2		; バイトインダイレクト
	add	g2,#1
	st	g1,@g2
	add	g2,#1
	ld	g3,%g2
	ld	g3,0,g2
	in	g4,%g5
	in	g4,g5
	in	g4,@g5
	halt

a	bs	4		; 4バイトの領域
b	ws	4		; 8バイトの領域
c	db	100		;
d	dw	100		;
	
	