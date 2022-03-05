;;;
;;; JMP, CALLのテスト
;;;
start	halt
	ld	sp,#0x0100	; sp=0100
	call	L1		; sp=00fe, [00fe]=000a
	no			; sp=0100
	jmp	L2		; 
	no
	no
L2	
	halt

L1
	no
	RET			; sp=0100

