;;;
;;; USPとRETIを組み合わせたテスト
;;;
start	halt
	ld	sp,#0x0100	; ssp=0100
	ld	usp,#0x0300	; usp=0300
	ld	fp,#.L1		; fp=.L1のアドレス
	push	fp		; ssp=00fe,[00fe]=.L1のアドレス
	ld	fp,#0x0080	; fp=0080(EI|USERモード)
	push	fp		; ssp=00fc,[00fc]=0080
	reti			; flag=0080,pc=.L1のアドレス
.L1
	jmp	.L1

