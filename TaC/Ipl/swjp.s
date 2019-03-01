;; void swjp(bankNo, jumpAddr);
_swjp	ld	g0,4,fp    	; arg1 (bank no)
	out	g0,0xf0		; ipl bank register
	ld	g0,6,fp		; arg2 (jmp addr)
	jmp	0,g0
	