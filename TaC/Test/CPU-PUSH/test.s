;;;
;;; PUSH, POPのテスト
;;;
start	halt
	ld	sp,#0x0100	; ssp=0100
	ld	usp,#0x0200	; usp=0200
	ld	fp,#-1		; fp=ffff
	push	fp		; ssp=00fe, [00fe]=ffff
	pop	flag		; ssp=0100, flag=00ff
	push	flag		; ssp=00fe, [00fe]=00ff
	pop	g11		; ssp=0010, g11=00ff
	ld	flag,#0x000f	; flag=000f, sp=usp
	push	fp		; usp=01fe, [01fe]=ffff
	pop	g11		; usp=0200, g11=ffff
	halt			; 特権違反！！

