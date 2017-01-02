--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2016 by
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
-- TaC/tac_com.vhd : TaC COM
--
-- 2016.08.30           : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity TAC_COM is
    Port ( P_CLK : in  std_logic;
           P_RESET : in  std_logic;
           P_EN : in  std_logic;
           P_IOW : in  std_logic;
           P_ADDR : in  std_logic_vector (1 downto 0);
           P_DIN : in  std_logic_vector (7 downto 0);

           P_COM_CTR : out   std_logic;
           P_CONSOLE_CTR : out  std_logic;
           P_SERIAL_CTR : out  std_logic;
           P_COM_LINE : out  std_logic_vector(18 downto 0)
         );
end TAC_COM;

architecture Behavioral of TAC_COM is
  signal i_com_1   : std_logic_vector(7 downto 0);
  signal i_com_2   : std_logic_vector(7 downto 0);
  signal i_com_3   : std_logic_vector(7 downto 0);
begin
  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        i_com_1 <= "00000000";
        i_com_2 <= "00000000";
        i_com_3 <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (P_EN='1' and P_IOW='1') then
          if (P_ADDR(1)='1') then
            i_com_3 <= P_DIN;
          elsif (P_ADDR(0)='1') then
            i_com_2 <= P_DIN;
          else
            i_com_1 <= P_DIN;
          end if;
        end if;
      end if;
    end process;
      
  P_COM_LINE    <= i_com_1 & i_com_2 & i_com_3(7 downto 5);
  P_COM_CTR     <= i_com_3(3);
  P_CONSOLE_CTR <= i_com_3(2);
  P_SERIAL_CTR  <= i_com_3(1);
  
end Behavioral;

