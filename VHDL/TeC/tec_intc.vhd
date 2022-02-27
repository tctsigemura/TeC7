--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2011 by
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
-- TeC Interrupt Controller VHDL Source Code
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;

entity TEC_INTC is
  port ( P_CLK   : in  std_logic;                        -- Clock
         P_RESET : in  std_logic;                        -- Reset
         P_LI    : in  std_logic;                        -- Instruction fetch
         P_MR    : in  std_logic;                        -- Memory Request

         P_INT0  : in  std_logic;                        -- INT0 (Timer)
         P_INT1  : in  std_logic;                        -- INT1 (SIO TdR)
         P_INT2  : in  std_logic;                        -- INT2 (SIO TdX)
         P_INT3  : in  std_logic;                        -- INT3 (Console)

         P_INTR  : out std_logic;                        -- Interrupt
         P_VECT  : out std_logic_vector(1 downto 0)      -- 割込み番号
        );
end TEC_INTC;

architecture RTL of TEC_INTC is
signal I_INT0 : std_logic;                               -- INT0 はラッチする
signal I_INT3 : std_logic;                               -- INT3 はラッチする

begin
  P_INTR <= I_INT0 or P_INT1 or  P_INT2 or  I_INT3;

  process(I_INT0, P_INT1, P_INT2)                        -- 割り込み番号を決める
  begin                                                  --   プライオリティ
    if (I_INT0='1') then                                 --     エンコーダ
      P_VECT <= "00";
    elsif (P_INT1='1') then
      P_VECT <= "01";
    elsif (P_INT2='1') then
      P_VECT <= "10";
    else
      P_VECT <= "11";
    end if;
  end process;

  -- INT0, INT3 はラッチする(CPU が認識したら自動的にリセットする)
  process(P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      I_INT0 <= '0';
      I_INT3 <= '0';
    elsif (P_CLK' event and P_CLK='1') then
      if (P_INT0='1') then                               -- INT0 をラッチする
        I_INT0 <= '1';
      elsif (P_MR='0' and P_LI='1') then                 -- CPU が INT0 を認識
        I_INT0 <= '0';                                   --   リセットする
      end if;
      if (P_INT3='1') then                               -- INT3 をラッチする
        I_INT3 <= '1';
      elsif (P_MR='0' and P_LI='1' and I_INT0='0'        -- CPU が INT3 を認識
             and P_INT1='0' and P_INT2='0') then
        I_INT3 <= '0';                                   --   リセットする
      end if;
    end if;
  end process;

end RTL;
