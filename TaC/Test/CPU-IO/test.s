;;;
;;; IN, OUTのテスト
;;;
start	halt
	in	sp,0xf8		; sp<=DSW
	in	fp,0xfa		; fp<=AdrReg
	ld	g11,#0x00fc	; g11<=00fc
	in	g10,%g11	; g10<=RSW
;;	in	g9,@g11		; g9<=0000
	add	g11,#1		; g11<=00fd
;;	in	g8,@g11		; g8<=RSW
	halt			;

	ld	g7,#0x1234	; g7<=1234
	out	g7,0xf8		; DatReg<=1234
L1	in	g6,0xf8		; g6<=DSW
	and	g6,#0x0001	; g6[0]==0 ?
	jnz	L1

	ld	g5,#0x00f8	; g5<=00f8
	ld	g4,#0xf0f0	; g4<=0xf0f0
	out	g4,%g5		; DatReg<=f0f0
L2	in	g3,0xf8		; g3<=DSW
	and	g3,#0x0002	; g3[1]==0 ?
	jz	L2

	ld	g2,#'A'		; g2<=0041
	ld	g1,#0x0009	; g1<=0009
;;	out	g2,@g1		; SIO-DATA<='A'
	halt

