--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2022 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
-- 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
-- コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
-- 布することを無償で許諾する．
--
--   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
-- 関連機関・個人は本ソースコードに関して，その適用可能性も含めて，いかなる保証
-- も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
-- る損害に関しても，その責任を負わない．
--
--

--
-- TaC/tac_cpu_sequencer.vhd : TaC CPU Sequencer VHDL Source Code
--
-- 2022.08.24           : 条件の簡単化・効率化(I_UPDATE_PC, P_SELECT_D, P_MR)
-- 2022.08.23           : RETI命令でM(SP+2)アクセス時にTLB missが発生すると
--                        PCが破壊されるバグを訂正
-- 2022.02.27           : 一応の完成
-- 2021.04.12           : 新規作成
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_CPU_SEQUENCER is
  port (
  P_CLK         : in std_logic;
  P_RESET       : in std_logic;
  P_STOP        : in std_logic;
  P_INTR        : in std_logic;                      -- 割り込み
  P_OP1         : in std_logic_vector(4 downto 0);
  P_OP2         : in std_logic_vector(2 downto 0);
  P_RD          : in std_logic_vector(3 downto 0);   -- 命令の Rd
  P_ADDR0       : in std_logic;                      -- アドレスの最下位
  P_UPDATE_PC   : out std_logic_vector(2 downto 0);  -- PC の更新
  P_UPDATE_SP   : out std_logic_vector(1 downto 0);  -- SP の更新
  P_LOAD_IR     : out std_logic;                     -- IR のロード
  P_LOAD_DR     : out std_logic;                     -- DR のロード
  P_LOAD_FLAG   : out std_logic;                     -- FLAG のロード
  P_LOAD_TMP    : out std_logic;                     -- TMP のロード
  P_LOAD_GR     : out std_logic;                     -- 汎用レジスタのロード
  P_SELECT_A    : out std_logic_vector(2 downto 0);  -- アドレス出力の選択
  P_SELECT_D    : out std_logic_vector(2 downto 0);  -- データ出力の選択
  P_SELECT_W    : out std_logic_vector(1 downto 0);  -- DR への入力の選択
  P_ALU_START   : out std_logic;
  P_ALU_ZDIV    : in std_logic;
  P_WAIT        : in std_logic;                      -- ALU, MMUからの待ち要求
  P_FLAG_V      : in std_logic;
  P_FLAG_C      : in std_logic;
  P_FLAG_Z      : in std_logic;
  P_FLAG_S      : in std_logic;
  P_FLAG_I      : in std_logic;
  P_FLAG_P      : in std_logic;
  P_TLBMISS     : in std_logic;                      -- TLB miss
  P_MR          : out std_logic;                     -- Memory Request
  P_IR          : out std_logic;                     -- I/O Request
  P_RW          : out std_logic;                     -- Read/Write
  P_HL          : out std_logic;                     -- Halt Instruction
  P_SVC         : out std_logic;                     -- Super Visor Call
  P_PRIVIO      : out std_logic;                     -- Privilege Violation
  P_ZDIV        : out std_logic;                     -- Zero Division
  P_INVINST     : out std_logic;                     -- Invalid Instruction
  P_VR          : out std_logic;                     -- Vector Fetch
  P_CON         : out std_logic_vector(1 downto 0)   -- Console
  );
end TAC_CPU_SEQUENCER;

architecture RTL of TAC_CPU_SEQUENCER is

-- 現在のステート
signal S_FETCH : std_logic;
signal S_WAIT1 : std_logic;
signal S_WAIT2 : std_logic;
signal S_INTR1 : std_logic;
signal S_INTR2 : std_logic;
signal S_INTR3 : std_logic;
signal S_INTR4 : std_logic;
signal S_DEC1  : std_logic;
signal S_DEC2  : std_logic;
signal S_ALU1  : std_logic;
signal S_ALU2  : std_logic;
signal S_ST1   : std_logic;
signal S_ST2   : std_logic;
signal S_PUSH  : std_logic;
signal S_POP   : std_logic;
signal S_CALL  : std_logic;
signal S_RET   : std_logic;
signal S_RETI1 : std_logic;
signal S_RETI2 : std_logic;
signal S_RETI3 : std_logic;
signal S_IN1   : std_logic;
signal S_IN2   : std_logic;
signal S_SVC   : std_logic;
signal S_INVAL : std_logic;
signal S_ZDIV  : std_logic;
signal S_PRIVIO: std_logic;
signal S_CON1  : std_logic;
signal S_CON2  : std_logic;
signal S_CON3  : std_logic;

-- 次のステート
signal N_FETCH : std_logic;
signal N_WAIT1 : std_logic;
signal N_WAIT2 : std_logic;
signal N_INTR1 : std_logic;
signal N_INTR2 : std_logic;
signal N_INTR3 : std_logic;
signal N_INTR4 : std_logic;
signal N_DEC1  : std_logic;
signal N_DEC2  : std_logic;
signal N_ALU1  : std_logic;
signal N_ALU2  : std_logic;
signal N_ST1   : std_logic;
signal N_ST2   : std_logic;
signal N_PUSH  : std_logic;
signal N_POP   : std_logic;
signal N_CALL  : std_logic;
signal N_RET   : std_logic;
signal N_RETI1 : std_logic;
signal N_RETI2 : std_logic;
signal N_RETI3 : std_logic;
signal N_IN1   : std_logic;
signal N_IN2   : std_logic;
signal N_SVC   : std_logic;
signal N_INVAL : std_logic;
signal N_ZDIV  : std_logic;
signal N_PRIVIO: std_logic;
signal N_CON1  : std_logic;
signal N_CON2  : std_logic;
signal N_CON3  : std_logic;

signal   I_STATE     : std_logic_vector(28 downto 0);
signal   I_NEXT      : std_logic_vector(28 downto 0);

signal   I_UPDATE_PC : std_logic_vector(2 downto 0);
signal   I_UPDATE_SP : std_logic_vector(1 downto 0);
signal   I_ALU_START : std_logic;

signal   IS_NO     : std_logic;                    -- NO命令
signal   IS_ALU    : std_logic;                    -- LD~SHRL (ST以外)
signal   IS_ST     : std_logic;                    -- ST命令
signal   IS_JMP    : std_logic;                    -- JMP命令
signal   IS_CALL   : std_logic;                    -- CALL命令
signal   IS_IN     : std_logic;                    -- IN命令
signal   IS_OUT    : std_logic;                    -- OUT命令
signal   IS_INOUT  : std_logic;                    -- INまたはOUT命令
signal   IS_PUSH   : std_logic;                    -- PUSH命令
signal   IS_POP    : std_logic;                    -- POP命令
signal   IS_RET    : std_logic;                    -- RET命令
signal   IS_RETI   : std_logic;                    -- RETI命令
signal   IS_SVC    : std_logic;                    -- SVC命令
signal   IS_HALT   : std_logic;                    -- HALT命令

signal   IS_INDR   : std_logic;                    -- FPR, Indr(16,8)
signal   IS_IMM16  : std_logic;                    -- 2ワードImmd
signal   IS_IMM4   : std_logic;                    -- 4ビットImmd
signal   IS_DrcIdx : std_logic;                    -- Drc,Idx

signal   I_JMP_GO    : std_logic;                    -- JMP条件成立

begin
  --
  -- 命令の種類
  --
  IS_NO    <= '1' when P_OP1="00000" and P_OP2="000" else '0';
  IS_ALU   <= '1' when (P_OP1/="00000" and P_OP1/="00010" and   -- LD,
                        P_OP1<="01100") or                      -- ADD〜MOD
                       P_OP1(4 downto 2)="100" else '0';        -- SFT
  IS_ST    <= '1' when P_OP1="00010" and                        -- ST命令
                       (P_OP2(2 downto 1)="00" or                 --  Drc,Idx
                        P_OP2(2 downto 1)="11" or                 --  Indr
                        P_OP2="011") else '0';                    --  FPR
  IS_JMP   <= '1' when P_OP1="10100" and                        -- JMP命令
                       P_OP2(2 downto 1)="00" else '0';           --  Drc,Idx
  IS_CALL  <= '1' when P_OP1="10101" and                        -- CALL命令
                       P_OP2(2 downto 1)="00" else '0';           --  Drc,Idx
  IS_IN    <= '1' when P_OP1="10110" and                        -- IN命令
                       (P_OP2="000" or P_OP2="110") else '0';     --  Drc,Indr
  IS_OUT   <= '1' when P_OP1="10111" and                        -- OUT命令
                       (P_OP2="000" or P_OP2="110") else '0';     --  Drc,Indr
  IS_INOUT <= '1' when P_OP1(4 downto 1)="1011" and             -- IN/OUT命令
                       (P_OP2="000" or P_OP2="110") else '0';     --  Drc,Indr
  IS_PUSH  <= '1' when P_OP1="11000" and P_OP2="000" else '0';  -- PUSH命令
  IS_POP   <= '1' when P_OP1="11000" and P_OP2="100" else '0';  -- POP命令
  IS_RET   <= '1' when P_OP1="11010" and P_OP2="000" else '0';  -- RET命令
  IS_RETI  <= '1' when P_OP1="11010" and P_OP2="100" else '0';  -- RETI命令
  IS_SVC   <= '1' when P_OP1="11110" and P_OP2="000" else '0';  -- SVC命令
  IS_HALT  <= '1' when P_OP1="11111" and P_OP2="111" else '0';  -- HALT命令

  --
  -- アドレッシングモード
  --
  IS_INDR  <= '1' when P_OP2="011" or P_OP2(2 downto 1)="11"    -- FPR,Indr
                  else '0';
  IS_IMM16 <= '1' when P_OP2="010" else '0';                    -- 16bit Imm
  IS_IMM4  <= '1' when P_OP2="101" else '0';                    -- 4bit Imm
  IS_DrcIdx<= '1' when P_OP2(2 downto 1)="00" else '0';         -- Drct,Idx

  --
  -- JMP 命令のとき、 JMP するか
  --
  I_JMP_GO    <=
    '1' when (P_RD="0000" and P_FLAG_Z='1') or                         -- JZ
             (P_RD="0001" and P_FLAG_C='1') or                         -- JC
             (P_RD="0010" and P_FLAG_S='1') or                         -- JM
             (P_RD="0011" and P_FLAG_V='1') or                         -- JO
             (P_RD="0100" and P_FLAG_Z='0' and P_FLAG_S=P_FLAG_V) or   -- JGT
             (P_RD="0101" and P_FLAG_S=P_FLAG_V) or                    -- JGE
             (P_RD="0110" and (P_FLAG_Z='1' or P_FLAG_S/=P_FLAG_V)) or -- JLE
             (P_RD="0111" and P_FLAG_S/=P_FLAG_V) or                   -- JLT
             (P_RD="1000" and P_FLAG_Z='0') or                         -- JNZ
             (P_RD="1001" and P_FLAG_C='0') or                         -- JNC
             (P_RD="1010" and P_FLAG_S='0') or                         -- JNM
             (P_RD="1011" and P_FLAG_V='0') or                         -- JNO
             (P_RD="1100" and P_FLAG_Z='0' and P_FLAG_C='0') or        -- JHI
             (P_RD="1110" and (P_FLAG_Z='1' or P_FLAG_C='1')) or       -- JLS
             (P_RD="1111")                                             -- JMP
             else '0';

  --
  -- ステート遷移を決める組み合わせ回路
  --
  N_WAIT1 <= S_SVC or S_INVAL or S_ZDIV or S_PRIVIO or 
             ((S_FETCH or S_DEC1 or S_DEC2 or S_RETI1) and P_TLBMISS);
  N_WAIT2 <= S_WAIT1;
  N_INTR1 <= S_FETCH and P_INTR;
  N_INTR2 <= S_INTR1;
  N_INTR3 <= S_INTR2;
  N_INTR4 <= S_INTR3;
  N_PRIVIO<= S_DEC1 and
             ((IS_HALT and not P_FLAG_P) or                        -- HALT
              (IS_INOUT and not P_FLAG_P and not P_FLAG_I));       -- IN/OUT
  N_ZDIV  <= (S_ALU1 or S_ALU2) and P_ALU_ZDIV;
  N_DEC1  <= S_FETCH and not P_STOP and not P_INTR;
  N_DEC2  <= S_DEC1 and IS_DrcIdx and                              -- Drct,Idx
             (IS_ALU or IS_ST or IS_JMP or IS_CALL or IS_INOUT);
  N_ALU1  <= ((S_DEC1 and IS_IMM16) or S_DEC2) and IS_ALU;
  N_ALU2  <= S_DEC1 and IS_ALU and not IS_DrcIdx and not IS_IMM16; -- FP〜Indr
  N_ST1   <= S_DEC2 and IS_ST;
  N_ST2   <= S_DEC1 and IS_ST and IS_INDR;                         -- Fp,Indr
  N_CALL  <= S_DEC2 and IS_CALL;
  N_IN1   <= S_DEC2 and IS_IN;
  N_IN2   <= S_DEC1 and IS_IN and IS_INDR;
  N_PUSH  <= S_DEC1 and IS_PUSH;
  N_POP   <= S_DEC1 and IS_POP;
  N_RET   <= S_DEC1 and IS_RET;
  N_RETI1 <= S_DEC1 and IS_RETI;
  N_RETI2 <= S_RETI1;
  N_RETI3 <= S_RETI2;
  N_SVC   <= S_DEC1 and IS_SVC;
  N_INVAL <= (S_DEC1 or S_DEC2) and
             not (N_FETCH or N_DEC2 or N_ALU1 or N_ALU2 or N_ST1 or
                  N_ST2 or N_CALL or N_IN1 or N_IN2 or N_PUSH or
                  N_POP or N_RET or N_RETI1 or N_SVC or N_PRIVIO);
  N_CON1  <= (S_FETCH and P_STOP and not P_INTR) or S_CON3;
  N_CON2  <= S_CON1 and P_STOP;
  N_CON3  <= S_CON2;
  N_FETCH <= (S_DEC1 and (IS_NO or IS_HALT or (IS_OUT and IS_INDR))) or
             (S_DEC2 and (IS_JMP or IS_OUT)) or
             S_ALU1 or S_ST1 or S_CALL or
             S_IN1 or S_ALU2 or S_ST2 or S_IN2 or S_PUSH or
             S_POP or S_RET or S_RETI3 or
             (S_CON1 and not P_STOP) or S_INTR4 or S_WAIT2;

  --
  -- ステートの遷移
  --
  (S_FETCH , S_WAIT1 , S_WAIT2 , S_INTR1 , S_INTR2 ,
   S_INTR3 , S_INTR4 , S_DEC1  , S_DEC2  , S_ALU1  ,
   S_ALU2  , S_ST1   , S_ST2   , S_PUSH  , S_POP   ,
   S_CALL  , S_RET   , S_RETI1 , S_RETI2 , S_RETI3 ,  
   S_IN1   , S_IN2   , S_SVC   , S_INVAL , S_ZDIV  ,  
   S_PRIVIO, S_CON1  , S_CON2  , S_CON3              ) <= I_STATE;

  I_NEXT <= (N_FETCH , N_WAIT1 , N_WAIT2 , N_INTR1 , N_INTR2 ,
             N_INTR3 , N_INTR4 , N_DEC1  , N_DEC2  , N_ALU1  ,
             N_ALU2  , N_ST1   , N_ST2   , N_PUSH  , N_POP   ,
             N_CALL  , N_RET   , N_RETI1 , N_RETI2 , N_RETI3 ,  
             N_IN1   , N_IN2   , N_SVC   , N_INVAL , N_ZDIV  ,  
             N_PRIVIO, N_CON1  , N_CON2  , N_CON3  );

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      I_STATE <= "10000000000000000000000000000";      -- リセット(FETCHへ進む)
    elsif (P_CLK'event and P_CLK='1') then
      if P_WAIT='0' then
        if N_WAIT1='0' then
          I_STATE <= I_NEXT;
        else
          I_STATE <= "01000000000000000000000000000";  -- 例外発生(WAIT1へ進む)
        end if;
      end if;
    end if;
  end process;

  --
  -- 信号に出力する内容をステートによって決める
  --
  P_CON <= "01" when S_CON1='1' and P_STOP='1' else
           "10" when S_CON2='1' else
           "11" when S_CON3='1' else
           "00";

  P_UPDATE_PC <= "000" when P_WAIT='1' else I_UPDATE_PC;
  I_UPDATE_PC <= "100" when (S_DEC1='1' and N_FETCH='1') or          -- PC+=2
                            (S_DEC1='1' and N_IN2='1') or
                            S_ALU2='1' or S_ST2='1' or S_PUSH='1' or
                            S_POP='1' or S_SVC='1' else
                 "101" when (S_DEC2='1' and IS_INOUT='1') or         -- PC+=4
                            (S_DEC2='1' and IS_JMP='1' and I_JMP_GO='0') or
                            S_ALU1='1' or S_ST1='1' else
                 "110" when S_INTR3='1' or S_INTR4='1' or            -- PC<-Din
                            S_RETI3='1' or S_RET='1' or
                            (S_CON3='1' and P_OP2(1 downto 0)="11") else
                 "111" when (S_DEC2='1' and IS_JMP='1' and I_JMP_GO='1') or
                            S_CALL='1' else                          -- PC<-EA
                 "000";                                              -- 保持

  P_UPDATE_SP <= "00"  when P_WAIT='1' else I_UPDATE_SP;
  I_UPDATE_SP <= "01"  when S_POP='1' or S_RET='1' or              -- SP+=2
                            S_RETI2='1' or S_RETI3='1' else
                 "10"  when S_INTR1='1' or S_INTR2='1' or          -- SP-=2
                            S_CALL='1' or S_PUSH='1' else
                 "00";                                             -- 保持

  P_LOAD_IR <= N_DEC1 or N_CON2;

  P_LOAD_DR <= N_DEC1 or (S_DEC1 and not IS_IMM4) or
               (S_DEC2 and not IS_CALL) or S_RETI2 or S_CON2;

  -- ADD, SUB, ..., SHRL ではフラグが変化する
  P_LOAD_FLAG <= '1' when (S_ALU1='1' or S_ALU2='1') and
                          P_OP1/="00001" else '0';             -- LD 以外

  P_LOAD_TMP <= N_INTR1;

  P_LOAD_GR <= '1' when (S_ALU1='1' and P_OP1 /= "00101") or   -- CMP 以外
                        (S_ALU2='1' and P_OP1 /= "00101") or
                        S_IN1='1' or S_IN2='1' or
                        S_POP='1' or S_RETI3='1' or
                        (S_CON3='1' and P_OP2(1 downto 0)="10") else '0';

  -- AOUT
  P_SELECT_A <= "000" when N_DEC1='1' or S_INTR4='1' else           -- PC
                "001" when S_DEC1='1' and                           -- PC+2
                           (N_DEC2='1' or N_ALU1='1') else
                "100" when N_POP='1' or N_RET='1' or N_RETI1='1' or -- SP
                           S_RET='1' or S_RETI2='1' or S_RETI3='1' else
                "101" when S_RETI1='1' else                         -- SP+2
                "110" when S_INTR1='1' or S_INTR2='1' or            -- SP-2
                           N_PUSH='1' or N_CALL='1' else
                "010";                                              -- EA

  -- DOUT
  P_SELECT_D <= "000" when S_INTR1='1' or S_CON3='1' else         -- PC
                "111" when S_INTR2='1' else                       -- TMP
                "010" when N_CALL='1' else                        -- PC+4
                "101" when P_OP2="111" and P_ADDR0='0' else       -- GR[Rd]<<8
                "100";                                            -- GR[Rd]

  -- DIN から DR
  P_SELECT_W <= "01" when S_FETCH='1' else                        -- S4
                "10" when P_OP2="111" and P_ADDR0='1' else        -- L8
                "11" when P_OP2="111" and P_ADDR0='0' else        -- H8
                "00";                                             -- 16

  P_ALU_START <= '0' when P_WAIT='1' else I_ALU_START;
  I_ALU_START <= N_ALU1 or N_ALU2;

  -- Memory Request
  P_MR <= N_DEC1 or N_DEC2 or N_ALU1 or (N_ALU2 and IS_INDR) or
          N_ST1 or N_ST2 or N_PUSH or N_POP or N_CALL or
          N_RET or S_RET or N_RETI1 or S_RETI1 or S_RETI2 or
          S_RETI3 or S_INTR1 or S_INTR2 or S_INTR4;

  -- I/O Request
  P_IR <= N_IN1 or N_IN2 or
          ((S_DEC1 or S_DEC2) and N_FETCH and IS_OUT);

  -- Read/Write
  P_RW <= S_INTR1 or S_INTR2 or N_ST1 or N_ST2 or N_PUSH or N_CALL or
          ((S_DEC1 or S_DEC2) and N_FETCH and IS_OUT);

  P_HL      <= S_DEC1 and IS_HALT;
  P_SVC     <= S_SVC;
  P_PRIVIO  <= S_PRIVIO;
  P_ZDIV    <= S_ZDIV;
  P_INVINST <= S_INVAL;
  P_VR      <= S_INTR3;

end RTL;

