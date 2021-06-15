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
signal I_FLAG : std_logic;

begin

    P_BUSY <= I_BUSY;
    P_OUT  <= I_OUT(15 downto 0);

    I_OUT  <= '0' & P_A                 when P_OP1 = "00001"        -- LD
              ('0' & P_A) + P_B         when P_OP1 = "00011"        -- ADD
              ('0' & P_A) - P_B         when P_OP1 = "00100" or     -- SUB
                                             P_OP1 = "00101"        -- CMP
              '0' & (P_A and P_B)       when P_OP1 = "00110"        -- AND
              '0' & (P_A or P_B)        when P_OP1 = "00111"        -- OR
              '0' & (P_A xor P_B)       when P_OP1 = "01000"        -- XOR
              ('0' & P_A) + (P_B & '0') when P_OP1 = "01001"        -- ADDS
              (P_A * P_B)(16 downto 0)  when P_OP1 = "01010"        -- MUL
              I_SHL                     when P_OP1 = "10000" or     -- SHLA
                                             P_OP1 = "10001"        -- SHLL
              I_SHR                     when P_OP1 = "10010" or     -- SHRA
                                             P_OP1 = "10011"        -- SHRL
              -- XXX: 本当にINのときにP_Bか確認する（OUT？）
              P_B                       when P_OP1 = "10110" or     -- IN
                                             P_OP1 = "11000"        -- PUSH
              (others => '0')           when others;


    process (P_CLK, P_RESET)
    begin
        I_FLAG <= '0';
        if (P_RESET = '1') then
            I_BUSY <= '0';
        elsif (P_CLK 'event and P_CLK = '1') then
            if (P_START = '1') then
                P_BUSY <= P_OP1 = "01011" or P_OP1 = "01100";
            end if;
        end if;
    end process;
    
end RTL;