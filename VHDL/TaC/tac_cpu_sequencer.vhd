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
    port (  P_CLK         : in std_logic;
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

signal   I_TRANS     : std_logic_vector(6 downto 0);

constant TR_KEEP            : std_logic_vector(6 downto 0) := "0000000";
constant TR_FETCH_CON       : std_logic_vector(6 downto 0) := "0000001";
constant TR_FETCH_INTR1     : std_logic_vector(6 downto 0) := "0000010";
constant TR_FETCH_DEC1      : std_logic_vector(6 downto 0) := "0000011";
constant TR_WAIT_FETCH      : std_logic_vector(6 downto 0) := "0000100";
constant TR_CON_FETCH       : std_logic_vector(6 downto 0) := "0000101";
constant TR_INTR1_INTR2     : std_logic_vector(6 downto 0) := "0000110";
constant TR_INTR2_INTR3     : std_logic_vector(6 downto 0) := "0000111";
constant TR_INTR3_INTR4     : std_logic_vector(6 downto 0) := "0001000";
constant TR_INTR4_FETCH     : std_logic_vector(6 downto 0) := "0001001";
constant TR_DEC1_NO_HALT    : std_logic_vector(6 downto 0) := "0001010";
constant TR_DEC1_IMM        : std_logic_vector(6 downto 0) := "0001011";
constant TR_DEC1_DRCT       : std_logic_vector(6 downto 0) := "0001100";
constant TR_DEC1_INDR_ALU   : std_logic_vector(6 downto 0) := "0001101";
constant TR_DEC1_INDR_ST    : std_logic_vector(6 downto 0) := "0001110";
constant TR_DEC1_SHORT_ALU  : std_logic_vector(6 downto 0) := "0001111";
constant TR_DEC1_SHORT_DIV  : std_logic_vector(6 downto 0) := "0010000";
constant TR_DEC1_INDR_IN    : std_logic_vector(6 downto 0) := "0010001";
constant TR_DEC1_INDR_OUT   : std_logic_vector(6 downto 0) := "0010010";
constant TR_DEC1_PUSH       : std_logic_vector(6 downto 0) := "0010011";
constant TR_DEC1_POP        : std_logic_vector(6 downto 0) := "0010100";
constant TR_DEC1_RET        : std_logic_vector(6 downto 0) := "0010101";
constant TR_DEC1_RETI       : std_logic_vector(6 downto 0) := "0010110";
constant TR_DEC2_ALU        : std_logic_vector(6 downto 0) := "0010111";
constant TR_DEC2_ST         : std_logic_vector(6 downto 0) := "0011000";
constant TR_DEC2_JMP        : std_logic_vector(6 downto 0) := "0011001";
constant TR_DEC2_CALL       : std_logic_vector(6 downto 0) := "0011010";
constant TR_DEC2_IN         : std_logic_vector(6 downto 0) := "0011011";
constant TR_DEC2_OUT        : std_logic_vector(6 downto 0) := "0011100";
constant TR_ALU1_FETCH      : std_logic_vector(6 downto 0) := "0011101";
constant TR_ST1_FETCH       : std_logic_vector(6 downto 0) := "0011110";
constant TR_CALL1_FETCH     : std_logic_vector(6 downto 0) := "0011111";
constant TR_IN1_FETCH       : std_logic_vector(6 downto 0) := "0100000";
constant TR_ALU2_FETCH      : std_logic_vector(6 downto 0) := "0100001";
constant TR_ST2_FETCH       : std_logic_vector(6 downto 0) := "0100010";
constant TR_ALU3_FETCH      : std_logic_vector(6 downto 0) := "0100011";
constant TR_IN2_FETCH       : std_logic_vector(6 downto 0) := "0100100";
constant TR_PUSH_FETCH      : std_logic_vector(6 downto 0) := "0100101";
constant TR_POP_FETCH       : std_logic_vector(6 downto 0) := "0100110";
constant TR_RET_FETCH       : std_logic_vector(6 downto 0) := "0100111";
constant TR_RETI1_RETI2     : std_logic_vector(6 downto 0) := "0101000";
constant TR_RETI2_RETI3     : std_logic_vector(6 downto 0) := "0101001";
constant TR_RETI3_FETCH     : std_logic_vector(6 downto 0) := "0101010";

signal   I_IS_ALU    : std_logic;

begin

    -- TODO
    -- - MMU待ちをどうやって処理するか

    -- LD, ADD, SUB, CMP, AND, OR, XOR, ADDS, MUL, DIV, MOD, MULL, DIVL, SHLA, SHLL, SHRA, SHRL
    I_IS_ALU <= '1' when (P_OP1 = "00001") or ("00011" <= P_OP1 and P_OP1 <= "01110") or (P_OP1(4 downto 2) = "100") else '0';

    -- 遷移の決定
    case I_STATE is
        when STATE_FETCH =>
            I_TRANS <=
                TR_FETCH_DEC1       when P_STOP = '0' and P_INTR = '0' else
                TR_FETCH_INTR1      when P_STOP = '0' and P_INTR = '1' else
                TR_FETCH_CON;
        when STATE_WAIT =>
            if (P_INTR = '0') then
                I_TRANS <= TR_KEEP;
            else
                I_TRANS <= TR_WAIT_FETCH;
            end if;
        when STATE_CON =>
            I_TRANS <= TR_CON_FETCH;
        when STATE_INTR1 =>
            I_TRANS <= TR_INTR1_INTR2;
        when STATE_INTR2 =>
            I_TRANS <= TR_INTR2_INTR3;
        when STATE_INTR3 =>
            I_TRANS <= TR_INTR3_INTR4;
        when STATE_INTR4 =>
            I_TRANS <= TR_INTR4_FETCH;
        when STATE_DEC1 =>
            I_TRANS <=
                TR_DEC1_NO_HALT     when P_OP1 = "00000" or P_OP1 = "11111" else
                TR_DEC1_IMM         when P_OP2 = "010" else
                TR_DEC1_DRCT        when P_OP2(2 downto 1) = "00" else
                TR_DEC1_INDR_ALU    when (P_OP2 = "011" or P_OP2(2 downto 1) = "11") and I_IS_ALU else
                TR_DEC1_INDR_ST     when ((P_OP2 = "011" or P_OP2(2 downto 1) = "11") and P_OP1 = "00010") else
                TR_DEC1_SHORT_ALU   when P_OP2(2 downto 1) = "10" and (I_IS_ALU and P_OP1(4 downto 1) /= "0101") else
                TR_DEC1_SHORT_DIV   when P_OP2(2 downto 1) = "10" and P_OP1(4 downto 1) = "0101" else
                TR_DEC1_INDR_IN     when P_OP2(2 downto 1) = "11" and P_OP1 = "10110" else
                TR_DEC1_INDR_OUT    when P_OP2(2 downto 1) = "11" and P_OP1 = "10111" else
                TR_DEC1_PUSH        when P_OP1 = "11000" and P_OP2(2) = '0' else
                TR_DEC1_POP         when P_OP1 = "11000" and P_OP2(2) = '1' else
                TR_DEC1_RET         when P_OP1 = "11010" and P_OP2(2) = '0' else
                TR_DEC1_RETI;
        when STATE_DEC2 =>
            I_TRANS <=
                TR_DEC2_ALU         when I_IS_ALU = '1' else
                TR_DEC2_ST          when P_OP1 = "00010" else
                TR_DEC2_JMP         when P_OP1 = "10100" else
                TR_DEC2_CALL        when P_OP1 = "10101" else
                TR_DEC2_IN          when P_OP1 = "10110" else
                TR_DEC2_OUT;
        when STATE_ALU1 =>
            I_TRANS <= TR_ALU1_FETCH;
        when STATE_ST1 =>
            I_TRANS <= TR_ST1_FETCH;
        when STATE_CALL1 =>
            I_TRANS <= TR_CALL1_FETCH;
        when STATE_IN1 =>
            I_TRANS <= TR_IN1_FETCH;
        when STATE_ALU2 =>
            I_TRANS <= TR_ALU2_FETCH;
        when STATE_ST2 =>
            I_TRANS <= TR_ST2_FETCH;
        when STATE_ALU3 =>
            I_TRANS <= TR_ALU3_FETCH;
        when STATE_IN2 =>
            I_TRANS <= TR_IN2_FETCH;
        when STATE_PUSH =>
            I_TRANS <= TR_PUSH_FETCH;
        when STATE_POP =>
            I_TRANS <= TR_POP_FETCH;
        when STATE_RET =>
            I_TRANS <= TR_RET_FETCH;
        when STATE_RETI1 =>
            I_TRANS <= TR_RETI1_RETI2;
        when STATE_RETI2 =>
            I_TRANS <= TR_RETI2_RETI3;
        when STATE_RETI3 =>
            I_TRANS <= TR_RETI3_FETCH;
        when others => null;
    end case;

    -- ステートマシンはステートの遷移のみを書く
    process (P_CLK, P_RESET)
    begin
        if (P_RESET='1') then
            I_STATE <= STATE_FETCH;
            P_STOP  <= '0';
            P_INTR  <= '0';
        elsif (P_CLK'event and P_CLK='1') then
            case I_TRANS is
                when TR_WAIT_FETCH | TR_CON_FETCH | TR_INTR4_FETCH
                    | TR_ALU1_FETCH | TR_ALU2_FETCH | TR_ALU3_FETCH
                    | TR_ST1_FETCH | TR_ST2_FETCH
                    | TR_IN1_FETCH | TR_IN2_FETCH
                    | TR_PUSH_FETCH | TR_POP_FETCH
                    | TR_CALL1_FETCH | TR_RET_FETCH | TR_RETI3_FETCH
                    | TR_DEC1_NO_HALT | TR_DEC1_SHORT_ALU | TR_DEC1_INDR_OUT =>
                    I_STATE <= STATE_FETCH;
                when TR_FETCH_CON =>
                    I_STATE <= STATE_CON;
                when TR_FETCH_INTR1 =>
                    I_STATE <= STATE_INTR1;
                when TR_INTR1_INTR2 =>
                    I_STATE <= STATE_INTR2;
                when TR_INTR2_INTR3 =>
                    I_STATE <= STATE_INTR3;
                when TR_INTR3_INTR4 =>
                    I_STATE <= STATE_INTR4;
                when TR_FETCH_DEC1 =>
                    I_STATE <= STATE_DEC1;
                when TR_DEC1_IMM =>
                    I_STATE <= STATE_ALU1;
                when TR_DEC1_DRCT | TR_DEC2_ALU =>
                    I_STATE <= STATE_DEC2;
                -- TODO
                when others => null;
            end case;
        end if;
    end process;

    -- 信号に出力する内容をステートによって決める
    P_UPDATE_PC <=  "01" when I_STATE = STATE_DEC1 and (P_OP1 = "00000" or P_OP1 = "11111") else
                    "00";
    P_UPDATE_SP <= "00";--TODO
    --P_UPDATE_
    
end RTL;
