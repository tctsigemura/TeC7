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
-- TaC/tac_cpu_alu.vhd : TaC CPU ALU VHDL Source Code
--
-- 2021.04.12           : 新規作成
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_CPU_ALU is
    port (  P_CLK       : in std_logic;
            P_RESET     : in std_logic;
            P_START     : in std_logic;
            P_OP1       : in std_logic_vector(4 downto 0);
            P_A         : in std_logic_vector(15 downto 0);
            P_B         : in std_logic_vector(15 downto 0);
            P_BUSY      : out std_logic;
            P_OUT       : out std_logic_vector(15 downto 0);
            P_OVERFLOW  : out std_logic;
            P_CARRY     : out std_logic;
            P_ZERO      : out std_logic;
            P_SIGN      : out std_logic
            );
end TAC_CPU_ALU;

architecture RTL of TAC_CPU_ALU is

signal I_BUSY : std_logic;

begin

    P_BUSY <= I_BUSY;

    process (P_CLK, P_RESET)
    begin
        if (P_RESET = '1') then
            I_BUSY <= '0';
        elsif (P_CLK 'event and P_CLK = '1') then
            if (P_START = '1') then
                P_BUSY <= '1';
                case P_OP1 is
                    when "00000" => null; -- NO
                    when "00001" => null; -- LD
                    when "00010" => null; -- ST
                    when "00011" => null; -- ADD
                    when "00100" => null; -- SUB
                    when "00101" => null; -- CMP
                    when "00110" => null; -- AND
                    when "00111" => null; -- OR
                    when "01000" => null; -- XOR
                    when "01001" => null; -- ADDS
                    when "01010" => null; -- MUL
                    when "01011" => null; -- DIV
                    when "01100" => null; -- MOD
                    when "01101" => null; -- MULL
                    when "01110" => null; -- DIVL
                    when "01111" => null;
                    when "10000" => null; -- SHLA
                    when "10001" => null; -- SHLL
                    when "10010" => null; -- SHRA
                    when "10011" => null; -- SHRL
                    when "10100" => null; -- JMP
                    when "10101" => null; -- CALL
                    when "10110" => null; -- IN
                    when "10111" => null; -- OUT
                    when "11000" => null; -- PUSH, POP
                    when "11001" => null;
                    when "11010" => null; -- RET, RETI
                    when "11011" => null;
                    when "11100" => null; -- EI, DI
                    when "11101" => null;
                    when "11110" => null; -- SVC
                    when "11111" => null; -- HALT
                end case;
            end if;
        end if;
    end process;
    
end RTL;
