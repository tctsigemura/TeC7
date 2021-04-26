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
            P_UPDATE_PC   : out std_logic_vector(1 downto 0);  -- PC の更新
            P_UPDATE_SP   : out std_logic_vector(1 downto 0);  -- SP の更新
            P_LOAD_IR     : out std_logic;                     -- IR のロード
            P_LOAD_DR     : out std_logic;                     -- DR のロード
            P_LOAD_FLAG   : out std_logic;                     -- FLAG のロード
            P_LOAD_TMP    : out std_logic;                     -- TMP のロード
            P_LOAD_GR     : out std_logic;                     -- 汎用レジスタのロード
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
constant STATE_ST1   : std_logic_vector(4 downto 0) := "01011";
constant STATE_ST2   : std_logic_vector(4 downto 0) := "01100";
constant STATE_PUSH  : std_logic_vector(4 downto 0) := "01101";
constant STATE_POP   : std_logic_vector(4 downto 0) := "01110";
constant STATE_CALL1 : std_logic_vector(4 downto 0) := "01111";
constant STATE_RET   : std_logic_vector(4 downto 0) := "10000";
constant STATE_RETI1 : std_logic_vector(4 downto 0) := "10001";
constant STATE_RETI2 : std_logic_vector(4 downto 0) := "10010";
constant STATE_RETI3 : std_logic_vector(4 downto 0) := "10011";

signal   I_STATE     : std_logic_vector(4 downto 0);

signal   I_STOP : std_logic;
signal   I_INTR : std_logic;

begin
    
    process (P_CLK, P_RESET)
    begin
        if (P_RESET='1') then
            I_STATE <= STATE_FETCH;
            I_STOP  <= '0';
            I_INTR  <= '0';
        elsif (P_CLK'event and P_CLK='1') then
            case I_STATE is
                when STATE_FETCH =>
                    if (I_STOP='0' and I_INTR='1') then
                        I_STATE <= STATE_INTR1;
                        P_FLAG_P <= '1';
                    elsif (I_STOP='0' and I_INTR='0') then
                        P_LOAD_IR <= '1';
                        P_LOAD_GR <= '1';
                        P_SELECT_W <= W_S4;
                    end if;
                when STATE_WAIT  => null;
                when STATE_INTR1 => null;
                when STATE_INTR2 => null;
                when STATE_INTR3 => null;
                when STATE_INTR4 => null;
                when STATE_DEC1  => null;
                when STATE_DEC2  => null;
                when STATE_ALU1  => null;
                when STATE_ALU2  => null;
                when STATE_ST1   => null;
                when STATE_ST2   => null;
                when STATE_PUSH  => null;
                when STATE_POP   => null;
                when STATE_RET   => null;
                when STATE_RETI1 => null;
                when STATE_RETI2 => null;
                when STATE_RETI3 => null;
                when others => null;
            end case;
        end if;
    end process;
    
end RTL;
