;;;
;;; ALUのテスト(右シフト命令)
;;;
start	halt
	ld	sp,#0x8cef		; EPIR VCSZ
	and	sp,#0xffff		; sp=8cef, flag=0042
	shra	sp,#1			; sp=c677, flag=0046
	shrl	sp,#1			; sp=633b, flag=0044
	shra	sp,#1			; sp=319d, flag=0044
	shrl	sp,#1			; sp=18ce, flag=0044
	shra	sp,#1			; sp=0c67, flag=0040
	ld	sp,#0x8000		; sp=8000, flag=0040
	shra	sp,#2			; sp=e000, flag=0042
	shra	sp,#3			; sp=fc00, flag=0042
	shra	sp,#4			; sp=ffc0, flag=0042
	shra	sp,#5			; sp=fffe, flag=0042
	shrl	sp,#1			; sp=7fff, flag=0040
	shrl	sp,#2			; sp=1fff, flag=0044
	shrl	sp,#4			; sp=01ff, flag=0044
	shrl	sp,#8			; sp=0001, flag=0044
	shrl	sp,#1			; sp=0000, flag=0045
	ld	sp,#1			; sp=0001, flag=0045
	shll	sp,#8			; sp=0100, flag=0040
	shra	sp,#8			; sp=0001, flag=0040
	shla	sp,#15			; sp=8000, flag=0042
	shra	sp,#15			; sp=ffff, flag=0042
	shrl	sp,#15			; sp=0001, flag=0044
	shll	sp,#14			; sp=4000, flag=0040
	shra	sp,#14			; sp=0001, flag=0040
	halt

