--
-- TaC VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2002-2010 by
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
--  trsw.vhd : push スイッチの入力を、チャタリングのないトリガ信号に変換する
--
--
-- 2010.07.20           : Subversion による管理を開始
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TRSW is
  port ( P_CLK    : in  std_logic;                      -- CLK
         P_RESET  : in  std_logic;                      -- Reset
         P_S      : in  std_logic;                      -- Switch(INPUT)
         P_SMP    : in  std_logic;                      -- Sample(20ms)
         P_RPT    : in  std_logic;                      -- Repeate
         P_Q      : out std_logic                       -- Q(OUTPUT)
       );
end TRSW;

architecture RTL of TRSW is

-- Flip Flop
signal I_PREV     : std_logic;
signal I_CNT1     : std_logic_vector(3 downto 0);      -- リピート開始タイマ
signal I_CNT2     : std_logic_vector(1 downto 0);      -- リピート間隔タイマ

begin
  P_Q <= P_SMP and P_S and (not I_PREV);

  process(P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      I_PREV  <= '0';
      I_CNT1  <= "0000";
      I_CNT2  <= "00";
    elsif (P_CLK' event and P_CLK='1') then
      if (P_SMP='1') then
        if (P_S='1') then
          if (I_PREV='0') then
            I_PREV  <= '1';
          elsif (I_CNT1="1111") then
            if (I_CNT2="00") then
              I_PREV  <= '0';
            end if;
            I_CNT2 <= I_CNT2 + 1;
          elsif (P_RPT='1') then
            I_CNT1 <= I_CNT1 + 1;
          end if;
        else
          I_PREV    <= '0';
          I_CNT1    <= "0000";
          I_CNT2    <= "00";
        end if;
      end if;
    end if;
  end process;

end RTL;

