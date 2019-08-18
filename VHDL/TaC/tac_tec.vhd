--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2019 by
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
-- TaC/tac_tec.vhd : TaC TeC CONSOLE
--
-- 2019.07.30           : P_IOR に関する警告を消す
-- 2019.02.03           : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity TAC_TEC is
    Port ( P_CLK      : in  std_logic;
           P_RESET    : in  std_logic;
           P_EN       : in  std_logic;
--         P_IOR      : in  std_logic;
           P_IOW      : in  std_logic;
           P_ADDR     : in  std_logic_vector (1 downto 0);
           P_DIN      : in  std_logic_vector (7 downto 0);
           P_DOUT     : out std_logic_vector (7 downto 0);

           P_TEC_DLED : in std_logic_vector(7 downto 0);
           P_TEC_DSW  : out std_logic_vector(7 downto 0);
           P_TEC_FNC  : out std_logic_vector(7 downto 0);
           P_TEC_CTL  : out std_logic_vector(2 downto 0);
           P_TEC_ENA  : out std_logic;
           P_TEC_RESET: in std_logic;
           P_TEC_SETA : in std_logic
         );
end TAC_TEC;

architecture Behavioral of TAC_TEC is
  signal i_dsw : std_logic_vector(7 downto 0);
  signal i_fnc : std_logic_vector(7 downto 0);
  signal i_ctl : std_logic_vector(3 downto 0);

begin
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_dsw <= "00000000";
      i_fnc <= "00000000";
      i_ctl <= "0000";
    elsif (P_CLK'event and P_CLK='1') then
      if (P_EN='1' and P_IOW='1') then
        if (P_ADDR="01") then
          i_dsw <= P_DIN;
        elsif (P_ADDR="10") then
          i_fnc <= P_DIN;
        elsif (P_ADDR="11") then
          i_ctl(2 downto 0) <= P_DIN(2 downto 0);
          i_ctl(3) <= P_DIN(7);
        end if;
      end if;
    end if;
  end process;

  P_TEC_DSW <= i_dsw;
  P_TEC_FNC <= i_fnc;
  P_TEC_CTL <= i_ctl(2 downto 0);
  P_TEC_ENA <= i_ctl(3);

  P_DOUT <= P_TEC_DLED when (P_ADDR="00") else
            "000000" & P_TEC_RESET & P_TEC_SETA when (P_ADDR="11") else
            "00000000";
end Behavioral;

