;;;
;;; USPのテスト
;;;
start	halt
	ld	sp,#0x0100	; ssp=0100
	ld	usp,#0x0300	; usp=0300
	ld	fp,#0x1234	; fp=1234
	ld	flag,#0		; flag=0000(ユーザモード)
	ld	sp,#0x0200	; usp=0200
	push	fp		; usp=01fe
	pop	fp		; usp=0200
	halt			; 特権違反！！

