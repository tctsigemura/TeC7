;;;
;;; フラグのテスト(計算による変化についてはALUやシフト命令のテストに任せる）
;;;
start	halt
	ld	sp,#0x0100		; EPIR VCSZ
	add	sp,#0x0000		; flag=0040, ssp=0100
	ld	fp,#L1			; flag=0040, fp=001a
	ld	g11,#-1			; flag=0040, g11=ffff
	push	g11			; flag=0040, ssp=00fe
	push	fp			; flag=0040, ssp=00fc
	ld	flag,#0x0040		; flag=0040
	reti				; flag=00ff, ssp=0100
	no				; ここは実行しないはず
L1	ld	flag,#0			; flag=0000(User mode)
	ld	sp,#0x0200		; flag=0000, usp=0200
	ld	fp,#L2			; flag=0000, fp=002e
	ld	g11,#-1			; flag=0000, g11=ffff
	push	g11			; flag=0000, usp=01fe
	push	fp			; flag=0000, usp=01fc
	reti				; flag=001f, usp=0200
	no				; ここは実行しないはず
L2	ld	flag,#0x00e0		; flag=0000
	ld	flag,#-1		; flag=001f
	halt				; flag=005f, 特権命令違反

