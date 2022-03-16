--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002 - 2021 by
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
-- TaC/tac_intc.vhd : Interrupt Controler
--
-- 2021.10.13 : TaC-CPU V3 対応
-- 2019.07.30 : 使用していない割込に関する警告を消す
-- 2013.01.06 : TaC-CPU V2 対応
-- 2012.01.22 : entity 名見直し
-- 2011.06.16 : TeC7 用に書き換える
-- 2010.07.20 : Subversion による管理を開始
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_INTC is
  port (
         P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_DOUT     : out std_logic_vector(15 downto 0);
         P_VR       : in  std_logic;
         P_EI       : in  std_logic;  -- 割込許可
         P_INTR     : out std_logic;
         P_INT_BIT  : in  std_logic_vector(15 downto 0)
       );
end TAC_INTC;

architecture RTL of TAC_INTC is

-- register
signal intReg  : std_logic_vector(15 downto 0);
signal intInp  : std_logic_vector(15 downto 0);
signal intInpD : std_logic_vector(15 downto 0);

-- signal
signal intSnd  : std_logic_vector(15 downto  0);
signal intMsk  : std_logic_vector(15 downto  1);

begin

  -- edge trigger
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      intInp  <= (others => '0');
      intInpD <= (others => '0');
      intReg  <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      intInp  <= P_INT_BIT(9 downto 0) & P_INT_BIT(15 downto 10);
      intInpD <= intInp;
      intReg  <= (intReg and not intSnd) or
                 (intInp and (intInpD xor intInp));
    end if;
  end process;

  -- select send signal
  intMsk <= (intMsk(14 downto 1) & '0') or intReg(14 downto 0);
  intSnd <= intReg and (not (intMsk & '0')) when (P_VR='1') else
            (others => '0');

  -- to cpu
  P_INTR  <= intMsk(6) or ((intMsk(15) or intReg(15)) and P_EI);
  P_DOUT(15 downto 5) <= "11111111111";
  P_DOUT(4 downto 1) <=
            "1010" when (intReg( 0) = '1') else  -- Int10(TlbMiss)
            "1011" when (intReg( 1) = '1') else  -- Int11(MemVio)
            "1100" when (intReg( 2) = '1') else  -- Int12(ZeroDiv)
            "1101" when (intReg( 3) = '1') else  -- Int13(PriVio)
            "1110" when (intReg( 4) = '1') else  -- Int14(InvInst)
            "1111" when (intReg( 5) = '1') else  -- Int15(SVC)
            "0000" when (intReg( 6) = '1') else  -- Int0 (Timer0)
            "0001" when (intReg( 7) = '1') else  -- Int1 (Timer1)
            "0010" when (intReg( 8) = '1') else  -- Int2 (RN4020 Rx)
            "0011" when (intReg( 9) = '1') else  -- Int3 (RN4020 Tx)
            "0100" when (intReg(10) = '1') else  -- Int4 (FT232 Rx)
            "0101" when (intReg(11) = '1') else  -- Int5 (FT232 Tx)
            "0110" when (intReg(12) = '1') else  -- Int6 (TeC Tx)
            "0111" when (intReg(13) = '1') else  -- Int7 (TeC Rx)
            "1000" when (intReg(14) = '1') else  -- Int8 (uSD)
            "1001"; --  (intReg(15) = '1') else  -- Int9 (PIO)
  P_DOUT(0) <= '0';
end RTL;

