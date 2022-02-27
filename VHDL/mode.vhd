--
-- TaC7 VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2011 by
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
--  mode.vhd : ジャンパーのセッティングからモードを決める
--
--
-- 2018.07.13           : RN4020の工場出荷時リセット用のモードを追加
-- 2011.09.18           : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity MODE is
  port (
         P_CLK    : in    std_logic;
         P_LOCKED : in    std_logic;
         P_JP     : inout std_logic_vector(1 downto 0);
         P_MODE   : out   std_logic_vector(2 downto 0);
         P_RESET  : out   std_logic
       );
end MODE;

architecture RTL of MODE is
  -- FSM state
  constant INIT  : std_logic_vector(3 downto 0) := "0000";
  constant TEMP  : std_logic_vector(3 downto 0) := "0001";
  constant TeC   : std_logic_vector(3 downto 0) := "1000";
  constant TaC   : std_logic_vector(3 downto 0) := "1001";
  constant DEMO1 : std_logic_vector(3 downto 0) := "1010";
  constant DEMO2 : std_logic_vector(3 downto 0) := "1011";
  constant RESET : std_logic_vector(3 downto 0) := "1111";

  -- FSM
  signal i_fsm   : std_logic_vector(3 downto 0);

  begin
    P_RESET <= i_fsm(3);                           -- mode is determined
    P_MODE  <= i_fsm(2 downto 0);                  -- mode

    process(P_CLK, P_LOCKED)
      begin
        if (P_LOCKED='0') then
          i_fsm <= INIT;
          P_JP  <= "ZZ";
        elsif (P_CLK'event and P_CLK='1') then
          if (i_fsm=INIT) then                     -- Initial state
            if (P_JP="10") then
              i_fsm <= TeC;                        -- TeC mode
            elsif (P_JP="01") then
              i_fsm <= TaC;                        -- TaC mode
            elsif (P_JP="00") then
              i_fsm <= RESET;                      -- RN4020 Factory Reset
            else
              i_fsm <= TEMP;                       -- DEMO mode candidate
              P_JP <= "0Z";                        -- output to jumper
            end if;
          elsif (i_fsm=TEMP) then                  -- DEMO mode candidate state
            if (P_JP="01") then
              i_fsm <= DEMO1;                      --   DEMO mode 1
            else
              i_fsm <= DEMO2;                      --   DEMO mode 2
            end if;
            P_JP <= "ZZ";                          --   switch off output
          end if;
        end if;
      end process;
end RTL;
