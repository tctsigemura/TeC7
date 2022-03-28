;;;
;;; SVCのテスト
;;;
start	halt
	ld	sp,#0x0100	; ssp=0100
	ld	usp,#0x0200	; usp=0200
	ld	fp,#L2		; fp=L2
	st	fp,0xfffe	; [fffe]=L2(SVC)
	ld	fp,#L3		; sp=L3
	st	fp,0xfffa	; [fffa]=L3(特権違反)
	ld	flag,#0x001f	; flag=001f, sp=usp
	svc			; flag=005f, ssp=00fc
				; [00fe]=L2 , [00fc]=001f
				; pc=L1
L1	no			;
	halt			; 特権違反例外を発生
				; [00fe]=haltのアドレス, [00fc]=001f

L2	no			; SVCハンドラ
	reti			; ssp=0100, flag=1f, pc=L1

L3	no			; 特権違反例外ハンドラ
	halt
