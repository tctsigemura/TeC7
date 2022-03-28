;;;
;;; ALUのテスト
;;;
start	halt
	ld	sp,#0x0000		; EPIR VCSZ
	add	sp,#0x0000		; sp=0000, flag=0041
	cmp	sp,#0x0001		; sp=0000, flag=0046
	sub	sp,#0x0001		; sp=ffff, flag=0046
	add	sp,#0x7fff		; sp=7ffe, flag=0044
	add	sp,#0x0002		; sp=8000, flag=004a
	cmp	sp,#0x0001		; sp=8000, flag=0048
	sub	sp,#0x0001		; sp=7fff, flag=0048
	and	sp,#0xff00		; sp=7f00, flag=0040
	or	sp,#0xf0f0		; sp=fff0, flag=0042
	xor	sp,#0x0f0f		; sp=f0ff, flag=0042
	adds	sp,#0x0f00		; sp=0eff, flag=0044
	adds	sp,#0x7800		; sp=feff, flag=0042
	mul	sp,#0			; sp=0000, flag=0041
	ld	sp,#10			; sp=000a, flag=0041
	mul	sp,#10			; sp=0064, flag=0040
	mul	sp,#10			; sp=03e8, flag=0040
	mul	sp,#10			; sp=2710, flag=0040
	mul	sp,#10			; sp=86a0, flag=0042
	div	sp,#10			; sp=0d76, flag=0040
	div	sp,#10			; sp=0158, flag=0040
	mod	sp,#100			; sp=002c, flag=0040
	mod	sp,#10			; sp=0004, flag=0040
	div	sp,#10			; sp=0000, flag=0041
	halt

