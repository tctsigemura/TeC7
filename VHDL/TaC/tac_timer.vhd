--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2012 - 2018 by
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
-- TaC/tac_timer.vhd : TaC TIMER
--
-- 2018.12.31 : CPU が停止中はタイマーも停止するように変更
-- 2016.01.08 : TMR_ENA が無視されるバグを訂正
-- 2012.03.02 : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_TIMER is
    Port ( P_CLK     : in  std_logic;
           P_RESET   : in  std_logic;
           P_EN      : in  std_logic;
           P_IOR     : in  std_logic;
           P_IOW     : in  std_logic;
           P_INT     : out std_logic;
           P_ADDR    : in  std_logic;
           P_1kHz    : in  std_logic;              -- 1kHz pulse
           P_DIN     : in  std_logic_vector (15 downto 0);
           P_DOUT    : out std_logic_vector (15 downto 0);
           P_STOP    : in  std_logic
         );
end TAC_TIMER;

architecture Behavioral of TAC_TIMER is
signal TMR_Cnt    : std_logic_vector(15 downto 0);  -- タイマーのカウンタ
signal TMR_Max    : std_logic_vector(15 downto 0);  -- タイマーの周期
signal TMR_Ena  : std_logic;                     -- タイマーのスタート/ストップ
signal TMR_Int    : std_logic;                     -- タイマー割込み発生中
signal TMR_Int_Ena: std_logic;                     -- タイマー割込み許可
signal I_TMR_Mat  : std_logic;                     -- Max と Cnt が一致した
signal I_INT_TMR_P: std_logic;                     -- 割込み発生時にパルスを発生

begin
  I_TMR_Mat <= '1' when (TMR_CNT=TMR_Max) else '0';  -- カウンタ = 目的の値
  I_INT_TMR_P <= P_1kHz and I_TMR_Mat;               -- 割込み発生パルス
  P_INT <= I_INT_TMR_P and TMR_Int_Ena;
  P_DOUT <= TMR_CNT when (P_ADDR='0') else
            TMR_Int & "000000000000000";

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      TMR_CNT <= "0000000000000000";
      TMR_Max <= "0000000000000001";
      TMR_Ena <= '0';
      TMR_Int <= '0';
      TMR_Int_Ena <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      -- 周期,スタートストップ,スタートストップ
      if (P_EN='1' and P_IOW='1') then
        if (P_ADDR='0') then
          TMR_Max <= P_DIN;               -- 周期を変更
          TMR_Ena <= '0';                 -- 変更時に自動的に止まる
        else
          TMR_Ena <= P_DIN(0);            -- スタートストップ
          TMR_Int_Ena <= P_DIN(15);       -- 割込み許可
        end if;
      end if;

      --
      if (I_INT_TMR_P='1') then
        TMR_Int <= '1';
      elsif (P_EN='1' and P_IOR='1') then
        TMR_Int <= '0';
      end if;

      -- タイマーのカウンタ制御
      if ((P_EN='1' and P_IOW='1' and
           P_ADDR='1') or I_INT_TMR_P='1') then
        TMR_CNT <= "0000000000000000";  -- Start/Stop、コンペアマッチでリセット
      elsif (P_1kHz='1' and TMR_Ena='1' and P_STOP='0') then
        TMR_CNT <= TMR_CNT + 1;         -- それ以外ではカウントアップ
      end if;
    end if;
  end process;
end Behavioral;

