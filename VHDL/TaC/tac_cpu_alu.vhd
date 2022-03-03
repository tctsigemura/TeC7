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
            P_ZDIV      : out std_logic;
            P_OUT       : out std_logic_vector(15 downto 0);
            P_OVERFLOW  : out std_logic;
            P_CARRY     : out std_logic;
            P_ZERO      : out std_logic;
            P_SIGN      : out std_logic
         );
end TAC_CPU_ALU;

architecture RTL of TAC_CPU_ALU is

signal I_BUSY : std_logic;
signal I_ZDIV : std_logic;
signal I_OUT  : std_logic_vector(16 downto 0);

signal I_S1   : std_logic_vector(15 downto 0);
signal I_S3   : std_logic_vector(15 downto 0);
signal I_S7   : std_logic_vector(15 downto 0);
signal I_SHL  : std_logic_vector(15 downto 0);

signal I_DIVMOD : std_logic;

signal I_SIGN : std_logic;
signal I_E8   : std_logic_vector(15 downto 0);
signal I_S8   : std_logic_vector(15 downto 0);
signal I_E12  : std_logic_vector(15 downto 0);
signal I_S12  : std_logic_vector(15 downto 0);
signal I_E14  : std_logic_vector(15 downto 0);
signal I_S14  : std_logic_vector(15 downto 0);
signal I_E15  : std_logic_vector(15 downto 0);
signal I_SHR  : std_logic_vector(15 downto 0);

signal I_CNT  : std_logic_vector(4 downto 0);
signal I_YX   : std_logic_vector(31 downto 0);
signal I_AmB  : std_logic_vector(16 downto 0);
signal I_AtB  : std_logic_vector(31 downto 0);

begin

    P_BUSY <= I_BUSY;
    P_OUT  <= I_OUT(15 downto 0);

    I_AtB <= P_A * P_B;

    P_ZDIV <= I_ZDIV;

    I_DIVMOD <= '1' when P_OP1="01011" or P_OP1="01100" else '0';

    I_OUT <= ('0' & P_A) + P_B         when P_OP1="00011"            -- ADD
        else ('0' & P_A) - P_B         when P_OP1(4 downto 1)="0010" -- SUB,CMP
        else '0' & (P_A and P_B)       when P_OP1="00110"            -- AND
        else '0' & (P_A or P_B)        when P_OP1="00111"            -- OR
        else '0' & (P_A xor P_B)       when P_OP1="01000"            -- XOR
        else ('0' & P_A) + (P_B & '0') when P_OP1="01001"            -- ADDS
        -- MUL では CARRY は常に 0
        else '0' & I_AtB(15 downto 0)  when P_OP1="01010"            -- MUL
        else '0' & I_YX(15 downto 0)   when P_OP1="01011"            -- DIV
        else '0' & I_YX(31 downto 16)  when P_OP1="01100"            -- MOD
        -- シフト命令では CARRY は 1 ビットシフトの時だけ正しい値になる
        else P_A(15) & I_SHL           when P_OP1(4 downto 1)="1000" -- SHL?
        else P_A(0)  & I_SHR           when P_OP1(4 downto 1)="1001" -- SHR?
        else '0' & P_B;                                 -- LD, IN, POP, RETI

    -- 左シフト
    I_S1   <= P_A(14 downto  0) & "0"        when P_B(0)='1' else P_A;
    I_S3   <= I_S1(13 downto 0) & "00"       when P_B(1)='1' else I_S1;
    I_S7   <= I_S3(11 downto 0) & "0000"     when P_B(2)='1' else I_S3;
    I_SHL  <= I_S7( 7 downto 0) & "00000000" when P_B(3)='1' else I_S7;

    -- 右シフト
    I_SIGN <= P_A(15) when P_OP1(0)='0' else '0';
    I_E8   <= (15 downto 8 => I_SIGN) & P_A(15 downto 8);
    I_S8   <= I_E8    when P_B(3)='1' else P_A;
    I_E12  <= (15 downto 12 => I_SIGN) & I_S8(15 downto 4);
    I_S12  <= I_E12   when P_B(2)='1' else I_S8;
    I_E14  <= (15 downto 14 => I_SIGN) & I_S12(15 downto 2);
    I_S14  <= I_E14   when P_B(1)='1' else I_S12;
    I_E15  <= I_SIGN & I_S14(15 downto 1);
    I_SHR  <= I_E15   when P_B(0)='1' else I_S14;

    -- 割り算
    I_AmB <= ('0' & I_YX(30 downto 15)) - P_B;
    process (P_CLK, P_RESET)
    begin
        if (P_RESET='0') then
            I_BUSY <= '0';
        elsif (P_CLK 'event and P_CLK = '1') then
            if (I_BUSY='1') then
                -- I_YX(31 downto 16) = あまり
                -- I_YX(15 downto 0) = 商
                if (I_AmB(16)='0') then
                    I_YX(31 downto 16) <= I_AmB(15 downto 0);
                else
                    I_YX(31 downto 16) <= I_YX(30 downto 15);
                end if;
                I_YX(15 downto 0) <= I_YX(14 downto 0) & not I_AmB(15);
                I_CNT <= I_CNT + 1;
                if (I_CNT=15) then
                    I_BUSY <= '0';
                end if;
            elsif (P_START = '1' and I_DIVMOD = '1' and I_ZDIV = '0') then
                I_BUSY <= '1';
                I_CNT <= "00000";
                I_YX <= "0000000000000000" & P_A;
            end if;
        end if;
    end process;

    -- フラグ
    P_OVERFLOW <=
      not (P_A(15) xor P_B(15)) and (I_OUT(15) xor P_A(15))
        when P_OP1="00011" else                              -- ADD
      (P_A(15) xor P_B(15)) and (I_OUT(15) xor P_A(15))
        when P_OP1="00100" or P_OP1="00101" else             -- SUB, CMP
      '0';
    P_CARRY <= I_OUT(16);
    P_ZERO <= '1' when I_OUT(15 downto 0) = (15 downto 0 => '0') else '0';
    P_SIGN <= I_OUT(15);

    -- ゼロ除算
    I_ZDIV <= '1' when I_DIVMOD = '1' and P_B = (15 downto 0 => '0') else '0';

end RTL;
