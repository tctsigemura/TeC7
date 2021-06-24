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
signal I_OUT  : std_logic_vector(16 downto 0);

signal I_S1   : std_logic_vector(15 downto 0);
signal I_S3   : std_logic_vector(15 downto 0);
signal I_S7   : std_logic_vector(15 downto 0);
signal I_SHL  : std_logic_vector(15 downto 0);

signal I_E8   : std_logic_vector(15 downto 0);
signal I_S8   : std_logic_vector(15 downto 0);
signal I_E12  : std_logic_vector(15 downto 0);
signal I_S12  : std_logic_vector(15 downto 0);
signal I_E14  : std_logic_vector(15 downto 0);
signal I_S14  : std_logic_vector(15 downto 0);
signal I_E15  : std_logic_vector(15 downto 0);
signal I_SHR  : std_logic_vector(15 downto 0);

signal I_DIV  : std_logic_vector(4 downto 0);
signal I_YX   : std_logic_vector(31 downto 0);
signal I_Y    : std_logic_vector(15 downto 0);
signal I_X    : std_logic_vector(15 downto 0);

begin

    P_BUSY <= I_BUSY;
    P_OUT  <= I_OUT(15 downto 0);

    I_OUT  <= '0' & P_B                 when P_OP1 = "00001" else   -- LD
              ('0' & P_A) + P_B         when P_OP1 = "00011" else   -- ADD
              ('0' & P_A) - P_B         when P_OP1(4 downto 1) = "0010"-- SUB, CMP
              '0' & (P_A and P_B)       when P_OP1 = "00110" else   -- AND
              '0' & (P_A or P_B)        when P_OP1 = "00111" else   -- OR
              '0' & (P_A xor P_B)       when P_OP1 = "01000" else   -- XOR
              ('0' & P_A) + (P_B & '0') when P_OP1 = "01001" else   -- ADDS
              (P_A * P_B)(16 downto 0)  when P_OP1 = "01010" else   -- MUL
              P_A(15) & I_SHL           when P_OP1(4 downto 1) = "1000"-- SHLA, SHLL
              P_A(0) & I_SHR            when P_OP1(4 downto 1) = "1001"-- SHRA, SHRL
              -- XXX: 本当にINのときにP_Bか確認する（OUT？）
              '0' & P_B                 when P_OP1 = "10110" or     -- IN
                                             P_OP1 = "11000" else   -- PUSH
              (others => '0');
    
    -- 左シフト
    I_S1    <= P_A(14 downto 0) & "0" when P_B(0) = '1' else P_A;
    I_S3    <= I_S1(13 downto 0) & "00" when P_B(1) = '1' else I_S1;
    I_S7    <= I_S3(11 downto 0) & "0000" when P_B(2) = '1' else I_S3;
    I_SHL   <= I_S7(7 downto 0) & "00000000" when P_B(3) = '1' else I_S3;

    -- 右シフト
    I_SIGN  <= P_A(15) when P_OP1 = "10010" else '0';
    I_E8    <= (15 downto 8 => I_SIGN) & P_A(15 downto 8);
    I_S8    <= I_E8 when P_B(3) = '1' else P_A;
    I_E12   <= (15 downto 12 => I_SIGN) & I_S8(15 downto 4);
    I_S12   <= I_E12 when P_B(2) = '1' else I_S8;
    I_E14   <= (15 downto 14 => I_SIGN) & I_S12(15 downto 2);
    I_S14   <= I_E14 when P_B(1) = '1' else I_S12;
    I_E15   <= I_SIGN & I_S14(15 downto 1);
    I_SHR   <= I_E15 when P_B(0) = '0' else I_S14;

    -- 割り算
    I_Y <= I_YX(30 downto 16);
    I_X <= I_YX(15 downto 0);

    process (P_CLK, P_RESET)
    begin
        if (P_RESET = '1') then
            I_BUSY <= '0';
        elsif (P_CLK 'event and P_CLK = '1') then
            if (P_START = '1' and (P_OP1 = "01011" or P_OP1 = "01100")) then
                case I_DIV is
                    when 0 =>
                        P_BUSY <= '1';
                        I_DIV <= 1;
                        I_YX <= "0000000000000000" & P_A;
                    when 1 =>
                        if I_YX(30 downto 15) >= I_B then
                            I_YX <= '1' & (I_YX(30 downto 15) - I_B) & I_YX(14 downto 0);
                        else
                            I_YX <= '0' & I_YX(30 downto 0);
                        end if;
                        I_DIV <= 2;
                    when 2 =>
                        if I_YX(29 downto 14) >= I_B then
                            I_YX <= I_YX(31 downto 31) & '1' & (I_YX(29 downto 14) - I_B) & I_YX(13 downto 0);
                        else
                            I_YX <= I_YX(31 downto 31) & '0' & I_YX(29 downto 0);
                        end if;
                        I_DIV <= 3;
                    when 3 =>
                        if I_YX(28 downto 13) >= I_B then
                            I_YX <= I_YX(31 downto 30) & '1' & (I_YX(28 downto 13) - I_B) & I_YX(12 downto 0);
                        else
                            I_YX <= I_YX(31 downto 30) & '0' & I_YX(28 downto 0);
                        end if;
                        I_DIV <= 4;
                    when 4 =>
                        if I_YX(27 downto 12) >= I_B then
                            I_YX <= I_YX(31 downto 29) & '1' & (I_YX(27 downto 12) - I_B) & I_YX(11 downto 0);
                        else
                            I_YX <= I_YX(31 downto 29) & '0' & I_YX(27 downto 0);
                        end if;
                        I_DIV <= 5;
                    when 5 =>
                        if I_YX(26 downto 11) >= I_B then
                            I_YX <= I_YX(31 downto 28) & '1' & (I_YX(26 downto 11) - I_B) & I_YX(10 downto 0);
                        else
                            I_YX <= I_YX(31 downto 28) & '0' & I_YX(26 downto 0);
                        end if;
                        I_DIV <= 6;
                    when 6 =>
                        if I_YX(25 downto 10) >= I_B then
                            I_YX <= I_YX(31 downto 27) & '1' & (I_YX(25 downto 10) - I_B) & I_YX(9 downto 0);
                        else
                            I_YX <= I_YX(31 downto 27) & '0' & I_YX(25 downto 0);
                        end if;
                        I_DIV <= 7;
                    when 7 =>
                        if I_YX(24 downto 9) >= I_B then
                            I_YX <= I_YX(31 downto 26) & '1' & (I_YX(24 downto 9) - I_B) & I_YX(8 downto 0);
                        else
                            I_YX <= I_YX(31 downto 26) & '0' & I_YX(24 downto 0);
                        end if;
                        I_DIV <= 8;
                    when 8 =>
                        if I_YX(23 downto 8) >= I_B then
                            I_YX <= I_YX(31 downto 25) & '1' & (I_YX(23 downto 8) - I_B) & I_YX(7 downto 0);
                        else
                            I_YX <= I_YX(31 downto 25) & '0' & I_YX(23 downto 0);
                        end if;
                        I_DIV <= 9;
                    when 9 =>
                        if I_YX(22 downto 7) >= I_B then
                            I_YX <= I_YX(31 downto 24) & '1' & (I_YX(22 downto 7) - I_B) & I_YX(6 downto 0);
                        else
                            I_YX <= I_YX(31 downto 24) & '0' & I_YX(22 downto 0);
                        end if;
                        I_DIV <= 10;
                    when 10 =>
                        if I_YX(21 downto 6) >= I_B then
                            I_YX <= I_YX(31 downto 23) & '1' & (I_YX(21 downto 6) - I_B) & I_YX(5 downto 0);
                        else
                            I_YX <= I_YX(31 downto 23) & '0' & I_YX(21 downto 0);
                        end if;
                        I_DIV <= 11;
                    when 11 =>
                        if I_YX(20 downto 5) >= I_B then
                            I_YX <= I_YX(31 downto 22) & '1' & (I_YX(20 downto 5) - I_B) & I_YX(4 downto 0);
                        else
                            I_YX <= I_YX(31 downto 22) & '0' & I_YX(20 downto 0);
                        end if;
                        I_DIV <= 12;
                    when 12 =>
                        if I_YX(19 downto 4) >= I_B then
                            I_YX <= I_YX(31 downto 21) & '1' & (I_YX(19 downto 4) - I_B) & I_YX(3 downto 0);
                        else
                            I_YX <= I_YX(31 downto 21) & '0' & I_YX(19 downto 0);
                        end if;
                        I_DIV <= 13;
                    when 13 =>
                        if I_YX(18 downto 3) >= I_B then
                            I_YX <= I_YX(31 downto 20) & '1' & (I_YX(18 downto 3) - I_B) & I_YX(2 downto 0);
                        else
                            I_YX <= I_YX(31 downto 20) & '0' & I_YX(18 downto 0);
                        end if;
                        I_DIV <= 14;
                    when 14 =>
                        if I_YX(17 downto 2) >= I_B then
                            I_YX <= I_YX(31 downto 19) & '1' & (I_YX(17 downto 2) - I_B) & I_YX(1 downto 0);
                        else
                            I_YX <= I_YX(31 downto 19) & '0' & I_YX(17 downto 0);
                        end if;
                        I_DIV <= 15;
                    when 15 =>
                        if I_YX(16 downto 1) >= I_B then
                            I_YX <= I_YX(31 downto 18) & '1' & (I_YX(16 downto 1) - I_B) & I_YX(0);
                        else
                            I_YX <= I_YX(31 downto 18) & '0' & I_YX(16 downto 0);
                        end if;
                        I_DIV <= 16;
                        ;
                    when 16 =>
                        if I_YX(15 downto 0) >= I_B then
                            I_YX <= I_YX(31 downto 17) & '1' & (I_YX(15 downto 0) - I_B);
                        else
                            I_YX <= I_YX(31 downto 17) & '0' & I_YX(15 downto 0);
                        end if;
                        I_DIV <= 17;
                    when 17 =>
                        P_BUSY <= '0';
                end case;
            end if;
        end if;
    end process;
    
end RTL;