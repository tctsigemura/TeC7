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



begin

    
    
end RTL;