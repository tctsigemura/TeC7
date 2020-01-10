;;;
;;; TaC Micro Program Source Code
;;;    Tokuyama kousen Educational Computer 16bit Ver.
;;;
;;; Copyright (C) 2002-2020 by
;;;                      Dept. of Computer Science and Electronic Engineering,
;;;                      Tokuyama College of Technology, JAPAN
;;;
;;;   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
;;; 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
;;; コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
;;; 布することを無償で許諾する．
;;;
;;;   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
;;; 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
;;; も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
;;; る損害に関しても，その責任を負わない．
;;;
;;;

;;;
;;; mrom.asm : TaC
;;;
;;; 2020.01.10        : RETI を非特権命令に変更
;;; 2017.01.10        : in,outの割込み判定を NPRV -> NIOPR に変更
;;; 2013.04.04        : DIV,MOD で TMP のクリア忘れ訂正
;;; 2012.09.29 v2.0.0 : コメント追加、無駄な命令削除、完成
;;; 2012.09.19        : LD Rd,FLAG 命令を追加
;;; 2012.09.17        : TaC-CPU V2 のコンソール対応
;;; 2012.07.27        : 4bitのFP相対をワード単位に変更
;;; 2012.07.03        : TaC-CPU V2 対応
;;; 2011.09.07        : Console Panel のマイクロコードを追加
;;; 2011.06.28        : TeC7 用に書き換える
;;; 2011.05.16        : PC と flag の退避順序を逆にする
;;; 2010.07.22        : 割り込み時に flag を自動退避、RETI が flag を復旧
;;; 2010.07.20        : Subversion による管理を開始
;;;
;;; $Id: mrom.asm 12 2010-08-06 10:03:08Z sigemura $
;;;
####NO####
fetch	alu(reg,PC),ld(AR),jcc(INT,intr)	; AR<=PC, if interrupt intr
	alu(inc2,PC),ld(PC,AR),bus(FETCH)	; IR,DR<=MEM[AR], AR<=(PC+=2)
	alu(reg,Rd),ld(OPR),jop(0)		; OPR<=Rd, Instruction Decode 1
####INTERRUPT####
intr	jcc(STOP,cons)				; if stop cons
	alu(reg,PC),ld(OPR),jcc(INT,intr0)	; OPR<=PC, if interrupt intr0
	j(fetch)				; stop has changed
intr0	alu(reg,FLAG),ld(TMP),stp		; TMP<=FLAG, privilege mode
	alu(dec2,SP),ld(AR,SP),bus(VECT),cli 	; AR<=(SP-=2), DR<=(vct adr)
	alu(reg,TMP),ld(OPR),bus(MEMW)		; OPR<=TMP(FLAG),MEM[AR]<=PC
	alu(dec2,SP),ld(AR,SP)			; AR<=(SP-=2)
	alu(reg,DR),ld(AR),bus(MEMW)		; MEM[AR]<=OPR(FLAG),AR<=DR
	bus(MEMR)				; DR<=MEM[AR](read vector)
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR(jump to int routine)
####ADDRESSING####
;;; Direct Mode
Drt	alu(inc2,PC),ld(PC),bus(MEMR) 		; fetch 2'nd word
	alu(reg,DR),ld(AR)			; AR<=2'nd word
	bus(MEMR),jop(1)			; DR<=MEM[AR],Inst Decode 2
;;; Indexed Mode
Idx	alu(inc2,PC),ld(PC),bus(MEMR)		; fetch 2'nd word
	alu(add,Rx),ld(AR)			; AR<=(2'nd word)+Rx
	bus(MEMR),jop(1)			; DR<=MEM[AR],Inst Decode 2
;;; Immidiate Mode
Imm	alu(inc2,PC),ld(PC),bus(MEMR),jop(1)	; fetch 2'nd word,Inst Decode 2
;;; FP Relative Mode
Fpr	alu(add,FP),ld(TMP)			; DR(Short Displacement)
	alu(add,TMP),ld(AR)			; AR<=FP+DR*2
	bus(MEMR),jop(1)			; DR<=MEM[AR],Inst Decode 2
;;; Register Mode
Reg	bus(LDRX),jop(1)			; DR<=Rx,Inst Decode 2
;;; Word Register Indirect Mode
Ind	alu(reg,Rx),ld(AR)			; AR<=Rx
	bus(MEMR),jop(1)			; DR<=MEM[AR]
;;; Byte Register Indirect Mode
BInd	alu(reg,Rx),ld(AR)			; AR<=Rx
	bus(MEMRB),jop(1)			; DR<=MEM[AR](Byte Read)
####LD####
ld	alu(reg,DR),ld(Rd),j(fetch) 		; Rd<=DR
ldr	alu(reg,Rx),ld(Rd),j(fetch)		; Rd<=Rx
ldf	alu(reg,FLAG),ld(Rd),j(fetch)		; Rd<=FLAG
####ST####
stDrt	bus(MEMR)				; fetch 2'nd word
	alu(reg,DR),ld(AR)			; AR<=(2'nd word)
	alu(inc2,PC),ld(PC),bus(MEMW),j(fetch)	; PC+=2, MEM[AR]<=OPR
stIdx	bus(MEMR)				; fetch 2'nd word
	alu(add,Rx),ld(AR)			; AR<=(2'nd word)+Rx
	alu(inc2,PC),ld(PC),bus(MEMW),j(fetch)	; PC+=2, MEM[AR]<=OPR
stFpr	alu(add,FP),ld(TMP)			; DR(Short Displacement)
	alu(add,TMP),ld(AR)			; AR<=FP+DR*2
	bus(MEMW),j(fetch)			; MEM[AR]<=OPR
stInd	alu(reg,Rx),ld(AR)			; AR<=Rx
	bus(MEMW),j(fetch)			; MEM[AR]<=OPR
stBInd	alu(reg,Rx),ld(AR)			; AR<=Rx
	bus(MEMWB),j(fetch)			; MEM[AR]<=OPR(Byte Write)
####ADD####
add	alu(add,Rd,FL),ld(Rd),j(fetch) 		; Rd<=Rd+DR,change flags
####SUB####
sub	alu(sub,Rd,FL),ld(Rd),j(fetch)		; Rd<=Rd-DR,change flags
####CMP####
cmp	alu(sub,Rd,FL),j(fetch)			; Rd-DR,change flags
####AND####
and	alu(and,Rd,FL),ld(Rd),j(fetch) 		; Rd<=Rd&DR,change flag
####OR####
or	alu(or,Rd,FL),ld(Rd),j(fetch) 		; Rd<=Rd|DR,change flag
####XOR####
xor	alu(xor,Rd,FL),ld(Rd),j(fetch)		; Rd<=Rd^DR,change flag
####ADDS####
adds	alu(add,Rd),ld(Rd)
	alu(add,Rd,FL),ld(Rd),j(fetch)		; Rd<=Rd+DR*2,change flag
####MUL####
mul	alu(ZERO,FL),ld(TMP)			; TMP<=0,c<=0
mul1	alu(rrot,TMP,FL),ld(TMP)		; (TMP,c)<=(c,TMP)>>1
	alu(rrot,Rd,FL),ld(Rd)			; (Rd,c)<=(c,Rd)>>1
	alu(xadd,TMP,FL),ld(TMP),jcc(CT16,mul1)	; if c then (c,TMP)<=TMP+DR
	alu(rrot,TMP,FL),ld(TMP)		; (TMP,c)<=(c,TMP)>>1
	alu(rrot,Rd,FL),ld(Rd),j(fetch)		; (Rd,c)<=(c,Rd)>>1
####DIV####
div	alu(reg,DR,FL)				; if DR=0 then z<=1
	alu(ZERO,FL),ld(TMP),jcc(ZERO,zderr)	; c<=0, if z=1 then error
div1	alu(lrot,Rd,FL),ld(Rd)			; (c,Rd)<=(Rd,c)<<1
	alu(lrot,TMP,FL),ld(TMP)		; (c,TMP)<=(TMP,c)<<1
	alu(subc,TMP,FL)			; c<=(c,TMP)-DR
	alu(xsub,TMP,FL),ld(TMP),jcc(CT16,div1)	; if c=0 then TMP<=TMP-DR,c<=1
	alu(lrot,Rd,FL),ld(Rd),j(fetch)		; Rd<=(Rd,c)<<1
####MOD####
mod	alu(reg,DR,FL)		     		; if DR=0 then z<=1
	alu(ZERO,FL),ld(TMP),jcc(ZERO,zderr)	; c<=0, if z=1 then error
mod1	alu(lrot,Rd,FL),ld(Rd)			; (c,Rd)<=(Rd,c)<<1
	alu(lrot,TMP,FL),ld(TMP)		; (c,TMP)<=(TMP,c)<<1
	alu(subc,TMP,FL)			; c<=(c,TMP)-DR
	alu(xsub,TMP,FL),ld(TMP),jcc(CT16,mod1) ; if c=0 then TMP<=TMP-DR,c<=1
	alu(reg,TMP,FL),ld(Rd),j(fetch)		; Rd<=TMP
####MULL####
mull	alu(ZERO,FL),ld(RdP)			; RdP<=0, c<=0
mll1	alu(rrot,RdP,FL),ld(RdP)		; (RdP,c)<=(c,RdP)>>1
	alu(rrot,Rd,FL),ld(Rd)			; (Rd,c)<=(c,Rd)>>1
	alu(xadd,RdP,FL),ld(RdP),jcc(CT16,mll1)	; if c then (c,RdP)<=RdP+DR
	alu(rrot,RdP,FL),ld(RdP)		; (RdP,c)<=(c,RdP)>>1
	alu(rrot,Rd,FL),ld(Rd),j(fetch)		; (Rd,c)<=(c,Rd) >>1
####DIVL####
divl	alu(reg,DR,FL)				; if DR=0 then z<=1
	alu(ZERO,FL),jcc(ZERO,zderr)		; c<=0, if z=1 then error
dvl1	alu(lrot,Rd,FL),ld(Rd)			; (c,Rd)<=(Rd,c)<<1
	alu(lrot,RdP,FL),ld(RdP)		; (c,RdP)<=(RdP,c)<<1
	alu(subc,RdP,FL)			; c<=(c,RdP)-DR
	alu(xsub,RdP,FL),ld(RdP),jcc(CT16,dvl1)	; if c=0 then RdP<=RdP-DR,c<=1
	alu(lrot,Rd,FL),ld(Rd),j(fetch)		; Rd<=(Rd,c)<<1
####SHR/SHL####
sft	jcc(CTDR,sft1)				; CT++,if DR!=0 then sft1
	alu(reg,Rd,FL),j(fetch)                 ; shift 0 changes only flag
sft1	alu(sft,Rd,FL),ld(Rd),jcc(CTDR,sft1)	; Rd<=(Rd sft 1),until CT++=DR
	j(fetch)
####JMP/JZ/JC/JM/JNZ/JNC/JNM####
jmpDrt	alu(inc2,PC),ld(PC),bus(MEMR),jcc(NJP,fetch)	; fetch 2'nd word
	alu(reg,DR),ld(PC),j(fetch)			; PC<=DR
jmpIdx	alu(inc2,PC),ld(PC),bus(MEMR),jcc(NJP,fetch)	; fetch 2'nd word
	alu(add,Rx),ld(PC),j(fetch)			; PC<=Rx+DR
jmpInd	jcc(NJP,fetch)
	alu(reg,Rx),ld(PC),j(fetch) 			; PC<=Rx
####CALL###
callDrt	alu(inc2,PC),ld(OPR,PC),bus(MEMR)	; fetch 2'nd word, OPR<=PC
	alu(dec2,SP),ld(SP,AR)			; AR<=(SP-=2)
	alu(reg,DR),ld(PC),bus(MEMW),j(fetch)	; PC<=DR,MEM[AR]<=OPR
callIdx	alu(inc2,PC),ld(OPR,PC),bus(MEMR)	; fetch 2'nd word, OPR<=PC
	alu(dec2,SP),ld(SP,AR)			; AR<=(SP-=2)
	alu(add,Rx),ld(PC),bus(MEMW),j(fetch)	; PC<=Rx+DR,MEM[AR]<=OPR
callInd	alu(reg,PC),ld(OPR,PC)			; OPR<=PC
	alu(dec2,SP),ld(SP,AR)			; AR<=(SP-=2)
	alu(reg,Rx),ld(PC),bus(MEMW),j(fetch)	; PC<=Rx,MEM[AR]<=OPR
####IN####
inDrt	bus(MEMR),jcc(NIOPR,pverr)		; fetch 2'nd word
	alu(reg,DR),ld(AR)			; AR<=DR
	alu(inc2,PC),ld(PC),bus(IOR),j(in1)	; PC+=2,DR<=IO[AR]
inInd	alu(reg,Rx),ld(AR),jcc(NIOPR,pverr)	; AR<=Rx
	bus(IOR),j(in1)				; DR<=IO[AR]
inBInd	alu(reg,Rx),ld(AR),jcc(NIOPR,pverr)	; AR<=Rx
	bus(IORB),j(in1)			; DR<=IO[AR](byte read)
in1	alu(reg,DR),ld(Rd),j(fetch)		; Rd<=DR
####OUT####
outDrt	bus(MEMR),jcc(NIOPR,pverr)		; fetch 2'nd word
	alu(reg,DR),ld(AR)			; AR<=DR
	alu(inc2,PC),ld(PC),bus(IOW),j(fetch)	; PC+=2,IO[AR]<=OPR
outInd	alu(reg,Rx),ld(AR),jcc(NIOPR,pverr)	; AR<=Rx
	bus(IOW),j(fetch)			; IO[AR]<=OPR
outBInd	alu(reg,Rx),ld(AR),jcc(NIOPR,pverr)	; AR<=Rx
	bus(IOWB),j(fetch)			; IO[AR]<=OPR(byte write)
####PUSH###
psh	alu(dec2,SP),ld(SP,AR)			; AR<=(SP-=2)
	bus(MEMW),j(fetch)			; MEM[AR]<=OPR
####POP####
pop	alu(reg,SP),ld(AR)			; AR<=SP
	alu(inc2,SP),ld(SP),bus(MEMR)		; SP+=2,DR<=MEM[AR]
	alu(reg,DR),ld(Rd),j(fetch)		; Rd<=DR
####RET####
ret	alu(reg,SP),ld(AR)			; AR<=SP
	alu(inc2,SP),ld(SP),bus(MEMR)		; SP+=2,DR<=MEM[AR]
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR
####RETI####
reti	alu(reg,SP),ld(AR) 			; AR<=SP
	alu(inc2,SP),ld(SP,AR),bus(MEMR)	; AR<=(SP+=2),DR<=MEM[AR](flag)
	alu(reg,DR),ld(TMP),bus(MEMR)		; TMP<=DR(flag),DR=MEM[AR](pc)
	alu(inc2,SP),ld(SP)			; SP+2
	alu(reg,TMP),ld(FLAG)			; FLAG<=TMP(change privilege)
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR
####EI####
ei	jcc(NPRV,pverr)
	sti,j(fetch)				; Set Interrupt
####DI####
di	jcc(NPRV,pverr)
	cli,j(fetch)				; Clear Interrup
####HALT####
halt	jcc(NPRV,pverr)
	bus(halt),j(fetch)			; Halt
####EXCEPTION####
svc	;; Supervisor Call
	alu(reg,FLAG),ld(TMP),stp	 	; TMP<=FLAG,Privilege Mode
	alu(dec2,SP),ld(AR,SP),cli		; AR<=(SP-=2),Clear Interrupt
	alu(reg,PC),ld(OPR)			; OPR<=PC
	alu(dec2,SP),ld(AR,SP),bus(MEMW)	; AR<=(SP-=2),MEM[AR]<=OPR(pc)
	alu(reg,TMP),ld(OPR)			; OPR<=TMP(flag)
	alu(zero),ld(TMP),bus(MEMW)		; TMP<=0000H,MEM[AR]<=OPR(flag)
	alu(dec2,TMP),ld(AR)			; AR<=FFFEH
	bus(MEMR)				; DR<=MEM[AR](SVC Vector)
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR
operr	;;  Illegal Instruction
	alu(reg,FLAG),ld(TMP),stp	 	; TMP<= FLAG,Privilege Mode
	alu(dec2,SP),ld(AR,SP),cli		; AR<=(SP-=2),Clear Interrupt
	alu(reg,PC),ld(OPR)			; OPR<=PC
	alu(dec2,SP),ld(AR,SP),bus(MEMW)	; AR<=(SP-=2),MEM[AR]<=OPR(pc)
	alu(reg,TMP),ld(OPR)			; OPR<=TMP(flag)
	alu(zero),ld(TMP),bus(MEMW)		; TMP<=0000H,MEM[AR]<=OPR(flag)
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFEH
	alu(dec2,TMP),ld(AR)			; AR<=FFFCH
	bus(MEMR)				; DR<=MEM[AR](Vector)
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR
pverr	;; Privilege Error
	alu(reg,FLAG),ld(TMP),stp	 	; TMP<=FLAG,Privilege Mode
	alu(dec2,SP),ld(AR,SP),cli		; AR<=(SP-=2),Clear Interrupt
	alu(reg,PC),ld(OPR)			; OPR<=PC
	alu(dec2,SP),ld(AR,SP),bus(MEMW)	; AR<=(SP-=2),MEM[AR]<=OPR(p)
	alu(reg,TMP),ld(OPR)			; OPR<=TMP(flag)
	alu(zero),ld(TMP),bus(MEMW)		; TMP<=0000H,MEM[AR]<=OPR(flag)
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFEH
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFCH
	alu(dec2,TMP),ld(AR)			; AR<=FFFAH
	bus(MEMR)				; DR<=MEM[AR](Vector)
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR
zderr	;; Zero Divide Error
	alu(reg,FLAG),ld(TMP),stp	 	; TMP<=FLAG,Privilege Mode
	alu(dec2,SP),ld(AR,SP),cli		; AR<=(SP-=2),Clear Interrupt
	alu(reg,PC),ld(OPR)			; OPR<=PC
	alu(dec2,SP),ld(AR,SP),bus(MEMW)	; AR<=(SP-=2),MEM[AR]<=OPR(pc)
	alu(reg,TMP),ld(OPR)			; OPR<=TMP(flag)
	alu(zero),ld(TMP),bus(MEMW)		; TMP<=0000H,MEM[AR]<=OPR(flag)
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFEH
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFCH
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFAH
	alu(dec2,TMP),ld(AR)			; AR<=FFF8H
	bus(MEMR)				; DR<=MEM[AR](Vector)
	alu(reg,DR),ld(PC),j(fetch)		; PC<=DR

####CONSOLE####
cons	;; Console Panel
	alu(zero),ld(TMP)			; TMP<=0000H
	alu(dec2,TMP),ld(AR)			; AR<=FFFEH
	bus(IOF)				; IR<=Fn(FEH) -- Clear Fn
cons0	alu(zero),ld(TMP),jcc(STOP,cons5)	; TMP<=0000H, if stop cons5
	j(fetch)				;
cons5	alu(dec2,TMP),ld(TMP,AR)		; TMP,AR<=FFFEH
	alu(dec2,TMP),ld(TMP,AR),bus(IOF)	; TMP,AR<=FFFCH,IR<=Fn(FEH)
	jcc(DI,cons1)				; if DI(RegRead) cons1
	jcc(SPR,cons2)				; if SPR(MemRead) cons2
	jcc(PCR,cons3)				; if PCR(MemWrite) cons3
	jcc(IM,cons4)				; if IM(AddrRead) cons4

cons6	;; Console RegWrie
	alu(dec2,TMP),ld(TMP,AR),bus(IOF)	; TMP,AR<=FFFAH,IR=Rx(FCH)
	alu(dec2,TMP),ld(AR)			; AR<=FFF8H
	alu(sft,PC),ld(TMP),jcc(PCR,cons9)	; TMP<=PC<<1,if Rx=Eh cons9
	alu(sft,FLAG),ld(TMP),jcc(IM,cons9)	; TMP<=FLAG<<1,if Rx=Fh cons9
	alu(sft,Rx),ld(TMP)			; TMP<=[Rx]<<1
cons9	alu(sft,TMP),ld(TMP),bus(IOR)		; TMP<=TMP<<1,DR<=DSW(F8H)
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP),jcc(PCR,cons10) 	; TMP<=TMP<<1,if Rx=Eh cons10
	jcc(IM,cons11)		       		; if Rx=Fh cons11
	alu(OR,TMP),ld(Rx),j(cons0)		; [Rx] <= TMP | DR
cons10	alu(OR,TMP),ld(PC),j(cons0)		; PC <= TMP | DR
cons11	alu(OR,TMP),ld(flag),j(cons0)		; FLAG <= TMP | DR

cons1	;; Console RegRead
	alu(dec2,TMP),ld(TMP),bus(IOF)		; TMP<=FFFAH,IR=Rx(FCH)
	alu(dec2,TMP),ld(AR)			; AR<=FFF8H
	alu(reg,PC),ld(OPR),jcc(PCR,cons7)	; OPR<=PC, if Rx=Eh cons7
	alu(reg,FLAG),ld(OPR),jcc(IM,cons7)	; OPR<=FLAG, if Rx=Fh cons7
	alu(reg,Rx),ld(OPR)			; OPR<=[Rx]
cons7	bus(IOW),j(cons0)			; DataLED(F8h)<=OPR

cons2	;; Console MemRead
	alu(dec2,TMP),ld(TMP,AR)		; TMP,AR<=FFFAH
	bus(IOR)				; DR<=AddrReg(FAh)
	alu(reg,DR),ld(AR)			; AR<=DR
	alu(dec2,TMP),ld(AR),bus(MEMR)		; AR<=FFF8H, DR<=MEM[AR]
	alu(reg,DR),ld(OPR)			; OPR<=DR
	bus(IOW),j(cons0)			; DataLED(F8h)<=OPR

cons3	;; Console MemWrite
	alu(dec2,TMP),ld(TMP,AR)		; TMP,AR<=FFFAH
	bus(IOR)				; DR<=AddrReg(FAh)
	alu(reg,DR),ld(AR)			; AR<=DR
	alu(dec2,TMP),ld(AR),bus(MEMR)		; AR<=FFF8H,DR<=MEM[AR]
	alu(reg,DR),ld(TMP),bus(IOR)		; TMP<=DR,DR<=DataSw(F8h)
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(sft,TMP),ld(TMP)			; TMP<=TMP<<1
	alu(OR,TMP),ld(OPR)			; OPR<=TMP|DR
	alu(zero),ld(TMP)			; TMP<=0000H
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFEH
	alu(dec2,TMP),ld(TMP)			; TMP<=FFFCH
	alu(dec2,TMP),ld(AR)			; AR<=FFFAH
	bus(IOR)				; DR<=AddrReg(FAh)
	alu(reg,DR),ld(AR)			; AR<=DR
	bus(MEMW),j(cons0)			; MEM[AR]<=OPR

cons4	;; Console AddrRead
	alu(dec2,TMP),ld(TMP,AR)		; TMP,AR<=FFFAH
	alu(dec2,TMP),ld(AR),bus(IOR)		; AR<=FFF8H,DR<=AddrReg(FAh)
	alu(reg,DR),ld(OPR)			; OPR<=DR
	bus(IOW),j(cons0)			; DataLED(F8h)<=OPR
