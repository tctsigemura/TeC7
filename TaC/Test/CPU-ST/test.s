;;;
;;; STのテスト
;;;   Rdの読み出しと一部のアドレッシング
;;;
start	halt
	ld	g0,#-8		; g0=fff8
	ld	g1,#-7		; g1=fff9
	ld	g2,#-6		; g2=fffa
	ld	g3,#-5		; g3=fffb
	ld	g4,#-4		; g4=fffc
	ld	g5,#-3		; g5=fffd
	ld	g6,#-2		; g6=fffe
	ld	g7,#-1		; g7=ffff
	ld	g8,#1		; g8=0001
	ld	g9,#2		; g9=0002
	ld	g10,#3		; g10=0003
	ld	g11,#4		; g11=0004
	ld	fp,#5		; fp=0005
	ld	sp,#6		; sp=0006
	ld	usp,#7		; usp=0007
	ld	flag,#0x47	; flag=0047
	st	g0,b		; [007a]=fff8
	st	g1,b		; [007a]=fff9
	st	g2,b		; [007a]=fffa
	st	g3,b		; [007a]=fffb
	st	g4,b		; [007a]=fffc
	st	g5,b		; [007a]=fffd
	st	g6,b		; [007a]=fffe
	st	g7,b		; [007a]=ffff
	st	g8,b		; [007a]=0001
	st	g9,b		; [007a]=0002
	st	g10,b		; [007a]=0003
	st	g11,b		; [007a]=0004
	st	fp,b		; [007a]=0005
	st	sp,b		; [007a]=0006
	st	usp,b		; [007a]=0007
	st	flag,b		; [007a]=0047
	ld	flag,#0		;
	st	sp,b		; [007a]=0007
	ld	fp,#b		; fp=007a
	st	g0,%fp		; [007a]=fff8
	st	g0,@fp		; [007a]=f8f8
	st	g1,-2,fp	; [0078]=fff9
	st	g2,2,fp		; [007c]=fffa
	halt

a	dw	0
b	dw	0
	dw	0

