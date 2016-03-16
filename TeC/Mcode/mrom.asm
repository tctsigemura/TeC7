; 
; TeC7 Micro Program Source Code
;    Tokuyama kousen Educational Computer Ver.7
;
; Copyright (C) 2002-2011 by
;                      Dept. of Computer Science and Electronic Engineering,
;                      Tokuyama College of Technology, JAPAN
;
;   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
; 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
; コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
; 布することを無償で許諾する．
;
;   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
; 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
; も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
; る損害に関しても，その責任を負わない．
;
;
;  注意!!　メモリ書き込みの BUS 命令は、ld(OPR) と同時実行してはいけない。
;
####NO####
fetch	alu(reg,PC),ld(AR),jcc(INT,intr)	; PC=>AR, if INT intr
	alu(inc,PC),ld(PC,AR),bus(MREQ,LDIR)	; ++PC=>AR,M=>IR
	jop(0)					; Jump on OP
intr	alu(reg,PC),ld(OPR),jcc(STP,fetch)	; PC=>OPR, if STP fetch
	alu(zero),ld(AR),jcc(INT,intr0)         ; 0=>AR,STPが変化した可能性あり
	j(fetch)
intr0	alu(dec,SP),ld(AR,SP),bus(IOREQ,LDIR,LDDR); --SP=>AR,VECT=>DR
	bus(MREQ,OE)				; OPR=>Mem
	cli,alu(reg,DR),ld(AR)			; clr int,DR=>AR
	bus(MREQ,LDDR)				; M=>DR
	alu(reg,DR),ld(PC),j(fetch)		; DR=>PC, jump fetch
; 
err	halt,err,j(fetch)			; opecode error
####LD####
ldi	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(ld2); ++PC,M=>DR
ld	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,ld0); ++PC,M=>DR,if direct ld0
	alu(add,Rx),ld(AR),j(ld1)		; DR+Rx=>AR
ld0	alu(reg,DR),ld(AR)			; DR=>AR,if drct ld0
ld1	bus(MREQ,LDDR)				; M=>DR
ld2	alu(reg,DR),ld(Rd),j(fetch)		; DR=>Rd,jump fetch
####ST####
st	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,st0); ++PC,M=>DR,if drct st0
	alu(add,Rx),ld(AR),j(st1)		; DR+Rx=>AR
st0	alu(reg,DR),ld(AR)			; DR=>AR
st1	alu(reg,Rd),ld(OPR)			; Rd=>OPR
	bus(MREQ,OE),j(fetch)			; OPR=>M,jump fetch
####ADD####
addi	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(add2); ++PC,M=>DR
add	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,add0);++PC,M=>DR,ifdirect add0
	alu(add,Rx),ld(AR),j(add1)		; DR+Rx=>AR
add0	alu(reg,DR),ld(AR)			; DR=>AR,if drct add0
add1	bus(MREQ,LDDR)				; M=>DR
add2	alu(add,Rd,FL),ld(Rd),j(fetch)		; DR+Rd=>Rd,jump fetch
####SUB####
subi	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(sub2); ++PC,M=>DR
sub	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,sub0);++PC,M=>DR,ifdirect sub0
	alu(add,Rx),ld(AR),j(sub1)		; DR+Rx=>AR
sub0	alu(reg,DR),ld(AR)			; DR=>AR,if drct sub0
sub1	bus(MREQ,LDDR)				; M=>DR
sub2	alu(sub,Rd,FL),ld(Rd),j(fetch)		; DR-Rd=>Rd,jump fetch
####CMP####
cmpi	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(cmp2); ++PC,M=>DR
cmp	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,cmp0);++PC,M=>DR,ifdirect cmp0
	alu(add,Rx),ld(AR),j(cmp1)		; DR+Rx=>AR
cmp0	alu(reg,DR),ld(AR)			; DR=>AR,if drct cmp0
cmp1	bus(MREQ,LDDR)				; M=>DR
cmp2	alu(sub,Rd,FL),j(fetch)			; DR-Rd,jump fetch
####AND####
andi	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(and2); ++PC,M=>DR
and	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,and0);++PC,M=>DR,ifdirect and0
	alu(add,Rx),ld(AR),j(and1)		; DR+Rx=>AR
and0	alu(reg,DR),ld(AR)			; DR=>AR,if drct and0
and1	bus(MREQ,LDDR)				; M=>DR
and2	alu(and,Rd,FL),ld(Rd),j(fetch)		; DR&Rd=>Rd,jump fetch
####OR####
ori	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(or2); ++PC,M=>DR
or	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,or0); ++PC,M=>DR,if direct or0
	alu(add,Rx),ld(AR),j(or1)		; DR+Rx=>AR
or0	alu(reg,DR),ld(AR)			; DR=>AR,if drct or0
or1	bus(MREQ,LDDR)				; M=>DR
or2	alu(or,Rd,FL),ld(Rd),j(fetch)		; DR|Rd=>Rd,jump fetch
####XOR####
xori	alu(inc,PC),ld(PC),bus(MREQ,LDDR),j(xor2); ++PC,M=>DR
xor	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(DI,xor0);++PC,M=>DR,ifdirect xor0
	alu(add,Rx),ld(AR),j(xor1)		; DR+Rx=>AR
xor0	alu(reg,DR),ld(AR)			; DR=>AR,if drct xor0
xor1	bus(MREQ,LDDR)				; M=>DR
xor2	alu(xor,Rd,FL),ld(Rd),j(fetch)		; DR^Rd=>Rd,jump fetch
####SHR/SHL####
sft	alu(sft,Rd,FL),ld(Rd),j(fetch)          ; shift(Rd)=>Rd
; 
####JMP/JZ/JC/JM####
jmp	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(NJP,fetch);++PC,M=>DR
	alu(reg,DR),ld(PC),jcc(DI,fetch)	; DR=>PC,if direct fetch
	alu(add,Rx),ld(PC),j(fetch)		; DR+Rx=>PC,jump fetch
####CALL###
cal	alu(inc,PC),ld(OPR),bus(MREQ,LDDR)	; PC+1=>OPR,M=>DR
	alu(dec,SP),ld(SP,AR)			; --SP=>AR
	alu(reg,DR),ld(PC),bus(MREQ,OE),jcc(DI,fetch);DR=>PC,OPR=>M,ifdrt fetch
	alu(add,Rx),ld(PC),j(fetch)		; DR+Rx=>PC,jump fetch
####JNZ/JNC/JNM####
jnz	alu(inc,PC),ld(PC),bus(MREQ,LDDR),jcc(JP,fetch);++PC,M=>DR
	alu(reg,DR),ld(PC),jcc(DI,fetch)	; DR=>PC,if direct fetch
	alu(add,Rx),ld(PC),j(fetch)		; DR+Rx=>PC,jump fetch
####IN/OUT(C0)####
io	alu(inc,PC),ld(PC),bus(MREQ,LDDR)	; ++PC,M=>DR
	alu(reg,DR),ld(AR),jcc(DI,in)		; DR=>AR,if drct in
	alu(reg,Rd),ld(OPR),bus(OE)		; Rd=>OPR 
	bus(IOREQ,OE)				; OPR=>IO
	bus(OE),j(fetch)			; jump fetch
in	bus(IOREQ)				; IOW信号出力
	bus(LDDR)				; IO=>DR
	alu(reg,DR),ld(Rd),j(fetch)		; DR=>Rd,jump fetch
####PUSH###
psh	alu(reg,Rd),ld(OPR)			; Rd=>OPR
	alu(dec,SP),ld(SP,AR)			; --SP=>AR
	bus(MREQ,OE),j(fetch)			; OPR=>M,jump fetch
####PUSHF###
pshf	alu(outf),ld(OPR)			; flag=>OPR
	alu(dec,SP),ld(SP,AR)			; --SP=>AR
	bus(MREQ,OE),j(fetch)			; OPR=>M,jump fetch
####POP####
pop	alu(reg,SP),ld(AR)			; SP=>AR
	alu(inc,SP),ld(SP),bus(MREQ,LDDR)	; SP++,M=>DR
	alu(reg,DR),ld(Rd),j(fetch)		; DR=>Rd,jump fetch
####POPF####
popf	alu(reg,SP),ld(AR)			; SP=>AR
	alu(inc,SP),ld(SP),bus(MREQ,LDDR)	; SP++,M=>DR
	alu(inf),j(fetch)			; DR=>flag,jump fetch
####EI####
ei	sti,j(fetch)				; set int, jump fetch
####DI####
di	cli,j(fetch)				; clr int, jump fetch
####RET####
ret	alu(reg,SP),ld(AR)			; SP=>AR
	alu(inc,SP),ld(SP),bus(MREQ,LDDR)	; SP++,M=>DR
	alu(reg,DR),ld(PC),j(fetch)		; DR=>PC, jump fetch
####RETI####
reti	alu(reg,SP),ld(AR),sti			; SP=>AR, set int
	alu(inc,SP),ld(SP),bus(MREQ,LDDR)	; SP++,M=>DR
	alu(reg,DR),ld(PC),j(fetch)		; DR=>PC, jump fetch
####HALT####
halt	halt,j(fetch)
