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

-- ステート
constant S_FETCH : std_logic_vector(4 downto 0) := "00000";
constant S_WAIT1 : std_logic_vector(4 downto 0) := "00001";
constant S_WAIT2 : std_logic_vector(4 downto 0) := "00010";
constant S_INTR1 : std_logic_vector(4 downto 0) := "00011";
constant S_INTR2 : std_logic_vector(4 downto 0) := "00100";
constant S_INTR3 : std_logic_vector(4 downto 0) := "00101";
constant S_INTR4 : std_logic_vector(4 downto 0) := "00110";
constant S_DEC1  : std_logic_vector(4 downto 0) := "00111";
constant S_DEC2  : std_logic_vector(4 downto 0) := "01000";
constant S_ALU1  : std_logic_vector(4 downto 0) := "01001";
constant S_ALU2  : std_logic_vector(4 downto 0) := "01010";
constant S_ST1   : std_logic_vector(4 downto 0) := "01011";
constant S_ST2   : std_logic_vector(4 downto 0) := "01100";
constant S_PUSH  : std_logic_vector(4 downto 0) := "01101";
constant S_POP   : std_logic_vector(4 downto 0) := "01110";
constant S_CALL  : std_logic_vector(4 downto 0) := "01111";
constant S_RET   : std_logic_vector(4 downto 0) := "10000";
constant S_RETI1 : std_logic_vector(4 downto 0) := "10001";
constant S_RETI2 : std_logic_vector(4 downto 0) := "10010";
constant S_RETI3 : std_logic_vector(4 downto 0) := "10011";
constant S_IN1   : std_logic_vector(4 downto 0) := "10100";
constant S_IN2   : std_logic_vector(4 downto 0) := "10101";
constant S_SVC   : std_logic_vector(4 downto 0) := "10110";
constant S_INVAL : std_logic_vector(4 downto 0) := "10111";
constant S_ZDIV  : std_logic_vector(4 downto 0) := "11000";
constant S_PRIVIO: std_logic_vector(4 downto 0) := "11001";
constant S_CON1  : std_logic_vector(4 downto 0) := "11010";
constant S_CON2  : std_logic_vector(4 downto 0) := "11011";
constant S_CON3  : std_logic_vector(4 downto 0) := "11100";

signal   I_STATE     : std_logic_vector(4 downto 0);
signal   I_NEXT      : std_logic_vector(4 downto 0);

signal   I_UPDATE_PC : std_logic_vector(2 downto 0);
signal   I_UPDATE_SP : std_logic_vector(1 downto 0);
signal   I_ALU_START : std_logic;

signal   I_IS_INDR   : std_logic;                    -- FP相対,レジスタ間接
signal   I_IS_ALU    : std_logic;                    -- LD~SHRL (ST以外)
signal   I_JMP_GO    : std_logic;                    -- JMP条件成立

begin

  -- LD,ADD,SUB,CMP,AND,OR,XOR,ADDS,MUL,DIV,MOD,SHLA,SHLL,SHRA,SHRL
  I_IS_ALU   <= '1' when (P_OP1/="00000" and P_OP1/="00010" and   -- NO,ST 以外
                          P_OP1<="01100") or                      -- MODまで
                         P_OP1(4 downto 2)="100" else '0';        -- SHIFT
  I_IS_INDR  <= '1' when P_OP2="011" or P_OP2(2 downto 1)="11" else '0';

  -- JMP 命令のとき、 JMP するか
  I_JMP_GO    <=
    '1' when P_OP1="10100" and
             ((P_RD="0000" and P_FLAG_Z='1') or                         -- JZ
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
             ) else '0';

  -- ステート遷移を決める組み合わせ回路
  I_NEXT <=
    S_WAIT1  when I_STATE=S_SVC or I_STATE=S_INVAL or
                  I_STATE=S_ZDIV or I_STATE=S_PRIVIO or
                  ((I_STATE=S_FETCH or I_STATE=S_DEC1 or
                    I_STATE=S_DEC2 or I_STATE=S_RETI1) and
                   P_TLBMISS='1') else
    S_WAIT2  when I_STATE=S_WAIT1 else
    S_INTR1  when I_STATE=S_FETCH and P_INTR='1' else
    S_INTR2  when I_STATE=S_INTR1 else
    S_INTR3  when I_STATE=S_INTR2 else
    S_INTR4  when I_STATE=S_INTR3 else
    S_PRIVIO when I_STATE=S_DEC1 and
                  ((P_OP1="11111" and P_FLAG_P='0') or               -- HALT
                   (P_OP1(4 downto 1)="1011" and                     -- IN/OUT
                    P_FLAG_P='0' and P_FLAG_I='0')) else
    S_ZDIV   when (I_STATE=S_ALU1 or I_STATE=S_ALU2) and P_ALU_ZDIV='1' else
    S_DEC1   when I_STATE=S_FETCH and P_STOP='0' else -- and P_INTR='0' else
    S_DEC2   when I_STATE=S_DEC1 and P_OP2(2 downto 1)="00" and     -- Drct,Idx
                  ((P_OP1/="00000" and P_OP1<=01100) or             -- LD〜MOD
                   (P_OP1(4 downto 3)="10")) else                   -- SFT〜OUT
    S_ALU1   when (I_STATE=S_DEC1 and I_IS_ALU='1' and P_OP2="010") or -- Imm
                  (I_STATE=S_DEC2 and I_IS_ALU='1') else
    S_ALU2   when (I_STATE=S_DEC1 and I_IS_ALU='1') else
    S_ST1    when I_STATE=S_DEC2 and P_OP1="00010" else
    S_ST2    when I_STATE=S_DEC1 and P_OP1="00010" and I_IS_INDR='1' else
    S_PUSH   when I_STATE=S_DEC1 and P_OP1="11000" and P_OP2(2)='0' else
    S_POP    when I_STATE=S_DEC1 and P_OP1="11000" and P_OP2(2)='1' else
    S_CALL   when I_STATE=S_DEC2 and P_OP1="10101" else
    S_RET    when I_STATE=S_DEC1 and P_OP1="11010" and P_OP2(2)='0' else
    S_RETI1  when I_STATE=S_DEC1 and P_OP1="11010" and P_OP2(2)='1' else
    S_RETI2  when I_STATE=S_RETI1 else
    S_RETI3  when I_STATE=S_RETI2 else
    S_IN1    when I_STATE=S_DEC2 and P_OP1="10110" else
    S_IN2    when I_STATE=S_DEC1 and
                  P_OP1="10110" and P_OP2(2 downto 1)="11" else
    S_FETCH  when (I_STATE=S_DEC1 and
                   ((P_OP1="00000" and P_OP2="000") or              -- NO
                    (P_OP1="11111" and P_OP2="111") or              -- HALT
                    (P_OP1="10111" and P_OP2(2 downto 1)="11"))) or -- OUT
                  (I_STATE=S_DEC2 and
                   (P_OP1="10100" or P_OP1="10111")) else           -- JMP/OUT
    S_SVC    when I_STATE=S_DEC1 and P_OP1="11110" else
    S_INVAL  when I_STATE=S_DEC1 or I_STATE=S_DEC2 else
    S_CON1   when (I_STATE=S_FETCH and P_STOP='1') or I_STATE=S_CON3 else
    S_CON2   when I_STATE=S_CON1 and P_STOP='1' else
    S_CON3   when I_STATE=S_CON2 else
    S_FETCH;

  -- ステートの遷移
  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      I_STATE <= S_FETCH;
    elsif (P_CLK'event and P_CLK='1') then
      if P_WAIT='0' then
        I_STATE <= I_NEXT;
      end if;
    end if;
  end process;

  -- 信号に出力する内容をステートによって決める

  P_CON <= "01" when I_STATE=S_CON1 and P_STOP='1' else
           "10" when I_STATE=S_CON2 else
           "11" when I_STATE=S_CON3 else
           "00";

  P_UPDATE_PC <= "000" when P_WAIT='1' else I_UPDATE_PC;
  I_UPDATE_PC <= "100" when (I_STATE=S_DEC1 and                     -- PC+=2
                             (I_NEXT=S_FETCH or I_NEXT=S_IN2)) or
                            I_STATE=S_ALU2 or I_STATE=S_ST2 or
                            I_STATE=S_PUSH or I_STATE=S_POP or
                            I_STATE=S_SVC else
                 "101" when (I_STATE=S_DEC2 and                     -- PC+=4
                             ((P_OP1="10100" and I_JMP_GO='0') or   --   JMP
                              P_OP1(4 downto 1)="1011")) or         --   IN/OUT
                            I_STATE=S_ALU1 or I_STATE=S_ST1 else
                 "110" when I_STATE=S_INTR3 or I_STATE=S_INTR4 or   -- PC<-Din
                            I_STATE=S_RETI1 or I_STATE=S_RET or
                            (I_STATE=S_CON3 and P_OP2(1 downto 0)="11") else
                 "111" when (I_STATE=S_DEC2 and                     -- PC<-EA
                             P_OP1="10100" and I_JMP_GO='1') or     --   JMP
                            I_STATE=S_CALL else                     --   CALL
                 "000";                                             -- 保持

  P_UPDATE_SP <= "00"  when P_WAIT='1' else I_UPDATE_SP;
  I_UPDATE_SP <= "01"  when I_STATE=S_POP or I_STATE=S_RET or        -- SP+=2
                            I_STATE=S_RETI2 or I_STATE=S_RETI3 else
                 "10"  when I_STATE=S_INTR1 or I_STATE=S_INTR2 or    -- SP-=2
                            I_STATE=S_CALL or I_STATE=S_PUSH else
                 "00";                                               -- 保持

  P_LOAD_IR <= '1' when I_STATE=S_FETCH or I_NEXT=S_CON2 else '0';

  P_LOAD_DR <= '1' when I_NEXT=S_DEC1 or
                        (I_STATE=S_DEC1 and P_OP2/="101") or       -- Imm4 以外
                        (I_STATE=S_DEC2 and P_OP1/="10101") or     -- CALL 以外
                        I_STATE=S_RETI2 or
                        I_STATE=S_CON2  else '0';

  -- ADD, SUB, ..., SHRL ではフラグが変化する
  P_LOAD_FLAG <= '1' when (I_STATE=S_ALU1 or I_STATE=S_ALU2) and
                          P_OP1/="00001" else '0';                 -- LD 以外

  P_LOAD_TMP <= '1' when I_NEXT=S_INTR1 else '0';

  P_LOAD_GR <= '1' when (I_STATE=S_ALU1 and P_OP1 /= "00101") or
                        (I_STATE=S_ALU2 and P_OP1 /= "00101") or
                        I_STATE=S_IN1 or I_STATE=S_IN2 or
                        I_STATE=S_POP or I_STATE=S_RETI3 or
                        (I_STATE=S_CON3 and P_OP2(1 downto 0)="10") else '0';

  -- AOUT
  P_SELECT_A <= "000" when I_NEXT=S_DEC1 or I_STATE=S_INTR4 else   -- PC
                "001" when I_STATE=S_DEC1 and                      -- PC+2
                           (I_NEXT=S_DEC2 or I_NEXT=S_ALU1) else
                "100" when I_NEXT=S_POP or I_NEXT=S_RET or         -- SP
                           I_NEXT=S_RETI1 or
                           I_STATE=S_RET or I_STATE=S_RETI2 else
                "101" when I_STATE=S_RETI1 else                    -- SP+2
                "110" when I_STATE=S_INTR1 or I_STATE=S_INTR2 or   -- SP-2
                           I_NEXT=S_PUSH or I_NEXT=S_CALL else
                "010";                                             -- EA

  -- DOUT
  P_SELECT_D <= "010" when I_NEXT=S_CALL else                      -- PC+4
                "101" when (I_NEXT=S_ST1 or I_NEXT=S_ST2) and 
                          P_OP2="111" and P_ADDR0='0' else       -- GR[Rd]>>>8
                "100" when ((I_STATE=S_DEC1 or I_STATE=S_DEC2) and -- GR[Rd]
                            I_NEXT=S_FETCH) or
                           I_NEXT=S_PUSH or I_NEXT=S_ST1 or
                           I_NEXT=S_ST2 or I_STATE=S_CON2 else
                "111" when I_STATE=S_INTR2 else                   -- TMP
                "000";                                            -- PC

  -- DIN から DR
  P_SELECT_W <= "01" when I_STATE=S_FETCH else                    -- S4
                "10" when P_OP2="111" and P_ADDR0='1' else        -- L8
                "11" when P_OP2="111" and P_ADDR0='0' else        -- H8
                "00";                                             -- 16

  P_ALU_START <= '0' when P_WAIT='1' else I_ALU_START;
  I_ALU_START <= '1' when I_NEXT=S_ALU1 or I_NEXT=S_ALU2 else '0';

  -- Memory Request
  P_MR <= '1' when I_NEXT=S_DEC1 or I_NEXT=S_DEC2 or I_NEXT=S_ALU1 or
                   (I_NEXT=S_ALU2 and I_IS_INDR='1') or
                   I_NEXT=S_ST1 or I_NEXT=S_ST2 or I_NEXT=S_PUSH or
                   I_NEXT=S_POP or I_NEXT=S_CALL or I_NEXT=S_RET or
                   I_STATE=S_RET or I_NEXT=S_RETI1 or I_NEXT=S_RETI2 or
                   I_NEXT=S_RETI3 or I_STATE=S_INTR1 or
                   I_STATE=S_INTR2 or I_STATE=S_INTR4 else '0';

  -- I/O Request
  P_IR <= '1' when I_NEXT=S_IN1 or I_NEXT=S_IN2 or
                   ((I_STATE = S_DEC1 or I_STATE = S_DEC2) and
                    I_NEXT = S_FETCH and P_OP1 = "10111") else '0'; -- OUT

  -- Read/Write
  P_RW <= '1' when I_STATE=S_INTR1 or I_STATE=S_INTR2 or
                   I_NEXT=S_ST1 or I_NEXT=S_ST2 or
                   I_NEXT=S_PUSH or I_NEXT=S_CALL or
                   ((I_STATE = S_DEC1 or I_STATE = S_DEC2) and
                    I_NEXT = S_FETCH and P_OP1 = "10111") else '0'; -- OUT

  P_HL      <= '1' when I_STATE=S_DEC1 and P_OP1="11111" else '0';
  P_SVC     <= '1' when I_STATE=S_SVC    else '0';
  P_PRIVIO  <= '1' when I_STATE=S_PRIVIO else '0';
  P_ZDIV    <= '1' when I_STATE=S_ZDIV   else '0';
  P_INVINST <= '1' when I_STATE=S_INVAL  else '0';
  P_VR      <= '1' when I_STATE=S_INTR3  else '0';

end RTL;

