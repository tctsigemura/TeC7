;;;
;;; JMP, CALLのテスト
;;;
start	halt
	ld	sp,#0x0100	; sp=0100
	call	L1		; sp=00fe, [00fe]=000a, pc=0024
	no			;
	ld	fp,#2		; fp=0002
	call	L1,fp		; sp=00fe, [00fe]=0012, pc=0026
	no			;
	jmp	L2		; pc=001a
	no			; ここは実行されない
L2	
	jmp	L3,fp		; pc=0020
L3
	no			; ここは実行されない
	no			;
	halt			; ここで停止

L1
	no			;
	RET			; sp=0100

