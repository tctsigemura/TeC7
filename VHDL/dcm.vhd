--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2019 by
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
-- dcm.vhd : クロック生成
--
-- 2019.08.27 : 新規作成
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

entity DCM is
    Port ( P_CLK_IN      : in    std_logic;  -- 9.8304MHz
           P_49_152MHz0  : out   std_logic;
           P_49_152MHz90 : out   std_logic;
           P_2_4576MHz   : out   std_logic;
           P_LOCKED      : out   std_logic
         );
end DCM;

architecture Behavioral of DCM is
  signal i_49_152MHz     : std_logic;
  signal i_locked_tac    : std_logic;
  signal i_locked_delay  : std_logic;
  signal i_locked_tec    : std_logic;

  component DCM_TAC
    Port ( CLK_IN1       : in    std_logic;
           CLK_OUT1      : out   std_logic;
           LOCKED        : out   std_logic
         );
  end component;

  component DELAY90
    Port ( CLK_IN1           : in     std_logic;
           CLK_OUT1          : out    std_logic;
           CLK_OUT2          : out    std_logic;
           LOCKED            : out    std_logic
         );
  end component;

  component DCM_TEC
    Port ( CLK_IN1       : in     std_logic;
           CLK_OUT1      : out    std_logic;
           LOCKED        : out    std_logic
         );
  end component;


begin
  DCM_TAC1 : DCM_TAC
    port map ( CLK_IN1  => P_CLK_IN,
               CLK_OUT1 => i_49_152MHz,
               LOCKED   => i_locked_tac
             );
				 
  DELAY : DELAY90
    port map ( CLK_IN1  => i_49_152MHz,
               CLK_OUT1 => P_49_152MHz0,
               CLK_OUT2 => P_49_152MHz90,
               LOCKED   => i_locked_delay
             );

  DCM_TEC1 : DCM_TEC
    port map ( CLK_IN1  => P_CLK_IN,
               CLK_OUT1 => P_2_4576MHz,
               LOCKED   => i_locked_tec
             );

    P_LOCKED <= i_locked_tac and i_locked_delay and i_locked_tec;

end Behavioral;
