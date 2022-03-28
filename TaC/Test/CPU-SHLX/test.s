;;;
;;; ALUのテスト(左シフト命令)
;;;
start	halt
	ld	sp,#0x3c81		; EPIR VCSZ
	and	sp,#0xffff		; sp=3c81, flag=0040
	shll	sp,#1			; sp=7902, flag=0040
	shla	sp,#1			; sp=f204, flag=0042
	shll	sp,#2			; sp=c810, flag=0046
	shla	sp,#3			; sp=4080, flag=0044
	shll	sp,#4			; sp=0800, flag=0040
	or	sp,#1			; sp=0801, flag=0040
	shla	sp,#5			; sp=0020, flag=0040
	shll	sp,#6			; sp=0800, flag=0040
	or	sp,#1			; sp=0801, flag=0040
	shla	sp,#7			; sp=0080, flag=0040
	shll	sp,#8			; sp=8000, flag=0042
	or	sp,#1			; sp=8001, flag=0042
	shla	sp,#15			; sp=8000, flag=0046
	shll	sp,#16			; sp=8000, flag=0046
	halt

