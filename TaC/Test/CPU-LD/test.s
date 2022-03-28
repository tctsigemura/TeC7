;;; 
;;; CPU の機械語命令とアセンブラ(as--)のテスト
;;; (アドレッシングモード，レジスタへのロード)
;;; 
start	halt			; 読みこまれたあと一旦停止
	ld	g0,d		; G0=1234 ダイレクト
	ld	g1,#2		; G1=0002 ショートイミディエイト
	ld	g2,#7           ; G2=0007 ショートイミディエイト
	ld	g3,#8           ; G3=0008 イミディエイト
	ld	g4,#-1		; G4=FFFF ショートイミディエイト
	ld	g5,#-8		; G5=FFF8 ショートイミディエイト
	ld	g6,#-9          ; G6=FFF7 イミディエイト
	ld	g7,#d		; G7=0036 イミディエイト
	ld	g8,d,g1		; G8=2345 インデクスド
	ld	g9,%g7		; G9=1234 インダイレクト
	ld	g10,@g7		; G10=0012 インダイレクト
	add	g7,#1		; G7=0037
	ld	g11,@g7		; G11=0034 インダイレクト
	add	g7,#1		; G7=0038
	ld	fp,g7		; fp=0038 レジスタレジスタ
	ld	sp,2,fp		; sp=3456 fp相対
	ld	usp,-2,fp	; usp=1234 fp相対
	ld	flag,#0		; flag=0,sp=1234
	no			; NO命令
	halt

a	bs	4		; 4バイトの領域
b	ws	4		; 8バイトの領域
c	db	100		;
d	dw	0x1234		;
	dw	0x2345		;
	dw	0x3456		;
	
