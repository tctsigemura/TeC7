--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2021 by
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
  P_INTR        : in std_logic;
  P_ALU_BUSY    : in std_logic;
  P_OP1         : in std_logic_vector(4 downto 0);
  P_OP2         : in std_logic_vector(2 downto 0);
  P_UPDATE_PC   : out std_logic_vector(1 downto 0);  -- PC の更新
  P_UPDATE_SP   : out std_logic_vector(1 downto 0);  -- SP の更新
  P_LOAD_IR     : out std_logic;                     -- IR のロード
  P_LOAD_DR     : out std_logic;                     -- DR のロード
  P_LOAD_FLAG   : out std_logic;                     -- FLAG のロード
  P_LOAD_TMP    : out std_logic;                     -- TMP のロード
  P_LOAD_GR     : out std_logic;                     -- 汎用レジスタのロード
  P_SELECT_A    : out std_logic_vector(2 downto 0);  -- アドレス出力の選択
  P_SELECT_D    : out std_logic_vector(2 downto 0);  -- データ出力の選択
  P_SELECT_W    : out std_logic_vector(1 downto 0);  -- DR への入力の選択
  P_SELECT_B    : out std_logic;                     -- ALU B への入力の選択
  P_ALU_START   : out std_logic;
  P_ALU_BUSY    : in std_logic;
  P_ALU_OVERFLOW: in std_logic;
  P_ALU_CARRY   : in std_logic;
  P_ALU_ZERO    : in std_logic;
  P_ALU_SIGN    : in std_logic;
  P_MR          : out std_logic;                     -- Memory Request
  P_IR          : out std_logic;                     -- I/O Request
  P_RW          : out std_logic                      -- Read/Write
  --TODO
  );
end TAC_CPU_SEQUENCER;
  
architecture RTL of TAC_CPU_SEQUENCER is

-- ステート
constant STATE_FETCH : std_logic_vector(4 downto 0) := "00001";
constant STATE_WAIT  : std_logic_vector(4 downto 0) := "00010";
constant STATE_INTR1 : std_logic_vector(4 downto 0) := "00011";
constant STATE_INTR2 : std_logic_vector(4 downto 0) := "00100";
constant STATE_INTR3 : std_logic_vector(4 downto 0) := "00101";
constant STATE_INTR4 : std_logic_vector(4 downto 0) := "00110";
constant STATE_DEC1  : std_logic_vector(4 downto 0) := "00111";
constant STATE_DEC2  : std_logic_vector(4 downto 0) := "01000";
constant STATE_ALU1  : std_logic_vector(4 downto 0) := "01001";
constant STATE_ALU2  : std_logic_vector(4 downto 0) := "01010";
constant STATE_ALU3  : std_logic_vector(4 downto 0) := "01011";
constant STATE_ST1   : std_logic_vector(4 downto 0) := "01100";
constant STATE_ST2   : std_logic_vector(4 downto 0) := "01101";
constant STATE_PUSH  : std_logic_vector(4 downto 0) := "01110";
constant STATE_POP   : std_logic_vector(4 downto 0) := "01111";
constant STATE_CALL1 : std_logic_vector(4 downto 0) := "10000";
constant STATE_RET   : std_logic_vector(4 downto 0) := "10001";
constant STATE_RETI1 : std_logic_vector(4 downto 0) := "10010";
constant STATE_RETI2 : std_logic_vector(4 downto 0) := "10011";
constant STATE_RETI3 : std_logic_vector(4 downto 0) := "10100";
constant STATE_IN1   : std_logic_vector(4 downto 0) := "11000";
constant STATE_IN2   : std_logic_vector(4 downto 0) := "11001";
constant STATE_CON   : std_logic_vector(4 downto 0) := "11111";

signal   I_STATE     : std_logic_vector(4 downto 0);

signal   I_IS_INDR   : std_logic;
signal   I_IS_ALU    : std_logic;
signal   I_JMP_GO    : std_logic;
signal   I_IS_DIV    : std_logic;

begin
  
  -- TODO
  -- - MMU待ちをどうやって処理するか
  
  -- LD, ADD, SUB, CMP, AND, OR, XOR, ADDS, MUL, DIV, MOD, MULL, DIVL, SHLA, SHLL, SHRA, SHRL
  I_IS_ALU    <= '1' when P_OP1 /= "00000" and P_OP1 /= "00010" and P_OP1(4 downto 2) <= "100" else '0';
  I_IS_INDR   <= '1' when P_OP2 = "011" or P_OP2(2 downto 1) = "11" else '0';
  I_IS_SHORT  <= '1' when P_OP2(2 downto 1) = "10" else '0';
  I_IS_DIV    <= '1' when P_OP1(4 downto 1) = "0101" else '0';
  
  -- ステートマシンはステートの遷移のみを書く
  process (P_CLK, P_RESET)
  begin
    if (P_RESET='1') then
      I_STATE <= STATE_FETCH;
      P_STOP  <= '0';
      P_INTR  <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      case I_STATE is
        when STATE_FETCH =>
          I_STATE <=
          STATE_DEC1  when P_STOP = '0' and P_INTR = '0' else
          STATE_DEC2  when P_STOP = '0' and P_INTR = '1' else
          STATE_CON;
        when STATE_WAIT =>
          I_STATE <= STATE_FETCH when P_INTR = '0' else STATE_WAIT;
        when STATE_INTR1 =>
          I_STATE <= STATE_INTR2;
        when STATE_INTR2 =>
          I_STATE <= STATE_INTR3;
        when STATE_INTR3 =>
          I_STATE <= STATE_INTR4;
        when STATE_DEC1 =>
          I_STATE <=
            STATE_ALU1  when P_OP2 = "010" else
            STATE_ALU2  when I_IS_INDR and I_IS_ALU else
            STATE_ALU3  when I_IS_SHORT and I_IS_DIV else
            STATE_DEC2  when P_OP2(2 downto 1) = "00" else
            STATE_ST2   when I_IS_INDR and P_OP1 = "00010" else
            STATE_PUSH  when P_OP1 = "11000" and P_OP2(2) = '0' else
            STATE_POP   when P_OP1 = "11000" and P_OP2(2) = '1' else
            STATE_RET   when P_OP1 = "11010" and P_OP2(2) = '0' else
            STATE_RETI1 when P_OP1 = "11010" and P_OP2(2) = '1' else
            STATE_FETCH;
        when STATE_DEC2 =>
          I_STATE <=
            STATE_ALU1  when I_IS_ALU else
            STATE_ST1   when P_OP1 = "00010" else
            STATE_CALL1 when P_OP1 = "10101" else
            STATE_FETCH;
        when others =>
          I_STATE <= STATE_FETCH;
      end case;
    end if;
  end process;
  
  -- 信号に出力する内容をステートによって決める
  
  P_UPDATE_PC <=
    "01"  when I_TR = TR_DEC1_NO_HALT or I_TR = TR_DEC1_SHORT_ALU
            or I_TR = TR_DEC1_INDR_IN or I_TR = TR_DEC1_INDR_OUT
            or I_TR = TR_ALU2_FETCH or I_TR = TR_ST2_FETCH
            or I_TR = TR_ALU3_FETCH or I_TR = TR_PUSH_FETCH
            or I_TR = TR_POP_FETCH else
    "10"  when (I_TR = DEC2_JMP and I_JMP_GO = '0') or I_TR = TR_DEC2_IN
            or I_TR = TR_DEC2_OUT or I_TR = TR_ALU1_FETCH
            or I_TR = TR_ST1_FETCH else
    "11"  when I_TR = TR_INTR4_FETCH or I_TR = TR_RET_FETCH
            or I_TR = TR_RETI2_RETI3 else
    "00";
  
  P_UPDATE_SP <=
    "01"  when I_TR = TR_POP_FETCH or I_TR = TR_RET_FETCH
            or I_TR = TR_RETI2_RETI3 or I_TR = TR_RETI3_FETCH else
    "10"  when I_TR = TR_INTR1_INTR2 or I_TR = TR_INTR2_INTR3
            or I_TR = TR_CALL1_FETCH or I_TR = TR_PUSH_FETCH else
    "00";
  
  P_LOAD_IR <= '1' when I_TR = TR_FETCH_DEC1 else '0';
  
  P_LOAD_DR <=
    '1' when I_TR = TR_LOAD_DR or I_TR = TR_DEC1_IMM
          or I_TR = TR_DEC1_DRCT or I_TR = TR_DEC1_INDR_IN
          or I_TR = TR_DEC1_POP or I_TR = TR_DEC1_RET
          or I_TR = TR_DEC2_ALU or I_TR = TR_DEC2_IN
          or I_TR = TR_RETI1_RETI2 else
    '0';
  
  -- ADD, SUB, ..., SHRL ではフラグが変化する
  P_LOAD_FLAG <= '1' when P_OP1 >= "00011" and P_OP1 <= "10011" else '0';
  
  P_LOAD_TMP <= '1' when I_STATE = STATE_FETCH and P_INTR = '1' else '0';
  
  P_LOAD_GR <=
    '1' when (I_STATE = STATE_DEC1 and I_IS_SHORT and I_IS_ALU)
          or I_STATE = STATE_ALU2 or I_STATE = STATE_ALU3
          or I_STATE = STATE_IN1 or I_STATE = STATE_IN2
          or I_STATE = STATE_RETI3 else
    '0';
  
  P_SELECT_A <=
    "001" when I_STATE = STATE_DEC1 and (P_OP2 = "000" or P_OP2 = "010") else
    "010" when (I_STATE = STATE_DEC1 and I_IS_INDR)
            or (I_STATE = STATE_DEC2 and (
              I_IS_ALU or P_OP1 = "00010" or P_OP1(4 downto 1) = "1011")) else
    "100" when (I_STATE = STATE_DEC1 and ((P_OP1 = "11000" and P_OP2(2) = '1')
              or P_OP1 = "11010"))
            or I_STATE = STATE_RET or I_STATE = STATE_RETI2 else
    "101" when I_STATE = STATE_RETI1 else
    "110" when I_STATE = STATE_INTR1 or I_STATE = STATE_INTR2
            or (I_STATE = STATE_DEC1 and P_OP1 = "11000" and P_OP2(2) = '0')
            or (I_STATE = STATE_DEC2 and P_OP1 = "10101") else
    "000";
  
  P_SELECT_D <=
    "010" when I_STATE = STATE_DEC2 and P_OP1 = "10101" else
    "100" when (I_STATE = STATE_DEC1 and (
            (I_IS_INDR and (P_OP1 = "00010" or P_OP1 = "10111"))
              or (P_OP1 = "11000" and P_OP2(2) = '0')))
            or (I_STATE = STATE_DEC2 and P_OP1 = "10111") else
    "111" when I_STATE = STATE_INTR2 else
    "000";
  
  P_SELECT_W <=
    "01" when I_STATE = STATE_FETCH and P_INTR = '0' and P_STOP = '0' else
    "00";
  
  P_SELECT_B <=
    '1' when I_STATE = STATE_IN1 or I_STATE = STATE_IN2
          or I_STATE = STATE_POP or I_STATE = STATE_RETI3 else
    '0';
  
  P_ALU_START <=
    '1' when (I_STATE = STATE_DEC1 and (
          P_OP2 = "010" or (I_IS_INDR and I_IS_ALU)
            or (I_IS_SHORT and I_IS_DIV)))
          or (I_STATE = STATE_DEC2 and I_IS_ALU) else
    '0';

  P_MR <=
    '1' when (I_STATE = STATE_FETCH and P_INTR = '0' and P_STOP = '0')
          or I_STATE = STATE_INTR1 or I_STATE = STATE_INTR2
          or I_STATE = STATE_INTR4
          or (I_STATE = STATE_DEC1 and P_OP1 /= "00000" and P_OP1 /= "11111"
            and P_OP2 /= "100" and P_OP2 /= "101"
            and (P_OP2 /= "111" or P_OP2(4 downto 1) /= "1011"))
          or (I_STATE = STATE_DEC2 and P_OP1 /= "10100"
            and P_OP1(4 downto 1) /= "1011")
          or I_STATE = STATE_RET
          or I_STATE = STATE_RETI1 or I_STATE = STATE_RETI2 else
    '0';
  
  -- P_IR
  -- P_RW
            
end RTL;
                