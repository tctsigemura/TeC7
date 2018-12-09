--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2012-2018 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   上記著作権者は，Free Software Foundation によって公開されている GNU 一般公
-- 衆利用許諾契約書バージョン２に記述されている条件を満たす場合に限り，本ソース
-- コード(本ソースコードを改変したものを含む．以下同様)を使用・複製・改変・再配
-- 布することを無償で許諾する．
--
--   本ソースコードは＊全くの無保証＊で提供されるものである。上記著作権者および
-- 関連機関・個人は本ソースコードに関して，その適用可能性も含ﾟて，いかなる保証
-- も行わない．また，本ソースコードの利用により直接的または間接的に生じたいかな
-- る損害に関しても，その責任を負わない．
--
--

--
-- TaC/tac_pio.vhd : TaC PIO
--
-- 2018.12.09           : PIOの出力を最大 12 ビット化
-- 2012.01.10           : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity TAC_PIO is
    Port ( P_CLK : in  std_logic;
           P_RESET : in  std_logic;
           P_EN : in  std_logic;
           P_IOR : in  std_logic;
           P_IOW : in  std_logic;
           P_INT : out  std_logic;
           P_ADDR : in  std_logic_vector (1 downto 0);
           P_DIN : in  std_logic_vector (7 downto 0);
           P_DOUT : out  std_logic_vector (7 downto 0);

           P_ADC_REF  : out  std_logic_vector(7 downto 0);
           P_EXT_IN   : in   std_logic_vector(7 downto 0);
           P_EXT_OUT  : out  std_logic_vector(11 downto 0);
           P_EXT_MODE : out  std_logic;
           P_MODE     : in   std_logic_vector(1 downto 0)
         );
end TAC_PIO;

architecture Behavioral of TAC_PIO is
  signal i_ext_out  : std_logic_vector(11 downto 0);
  signal i_ext_mode : std_logic;
  signal i_adc  : std_logic_vector(7 downto 0);

begin
  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        i_ext_out <= "000000000000";
        i_adc <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (P_EN='1' and P_IOW='1') then
          if (P_ADDR(1)='0') then
            if (P_ADDR(0)='0') then
              i_ext_out(7 downto 0) <= P_DIN;
            else
              i_adc <= P_DIN;
            end if;
          else
            i_ext_mode <= P_DIN(7);
            i_ext_out(11 downto 8) <= P_DIN(3 downto 0);
          end if;
        end if;
      end if;
    end process;
      
  P_DOUT <= P_EXT_IN when (P_ADDR(0)='0') else "000000" & P_MODE;
  P_ADC_REF <= i_adc;
  P_EXT_OUT <= i_ext_out;
  P_EXT_MODE <= i_ext_mode;
  P_INT <= '0';
end Behavioral;

