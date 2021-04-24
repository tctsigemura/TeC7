--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2021 by
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
-- TaC/tac_cpu_sequencer.vhd : TaC CPU Sequencer VHDL Source Code
--
-- 2021.04.12           : 新規作成
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_CPU_SEQUENCER is
    port (  P_CLK         : in std_logic;
            P_UPDATE_PC   : out std_logic_vector(1 downto 0);  -- PC の更新
            P_UPDATE_SP   : out std_logic_vector(1 downto 0);  -- SP の更新
            P_LOAD_IR     : out std_logic;                     -- IR のロード
            P_LOAD_DR     : out std_logic;                     -- DR のロード
            P_LOAD_FLAG   : out std_logic;                     -- FLAG のロード
            P_LOAD_TMP    : out std_logic;                     -- TMP のロード
            P_LOAD_GR     : out std_logic;                     -- 汎用レジスタのロード
          --TODO
            );
end TAC_CPU_SEQUENCER;

architecture RTL of TAC_CPU_SEQUENCER is


    
end RTL;
