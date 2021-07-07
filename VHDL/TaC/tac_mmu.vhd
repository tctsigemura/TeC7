--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2011-2019 by
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
-- TaC/tac_mmu.vhd : TaC Memory Management Unit Source Code
--
-- 2019.12.19           : CPU停止時（コンソール動作時）はアドレス変換禁止
-- 2019.07.30           : アドレスエラー追加
-- 2019.01.22           : 新しく追加
--

library IEEE;
use IEEE.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;

entity TAC_MMU is
  Port ( P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_EN       : in  std_logic;
         P_IOW      : in  std_logic;
         P_MMU_MR   : in  std_logic;                     -- Memory Request(CPU)
         P_BT       : in  std_logic;                     -- Byte access
         P_PR       : in  std_logic;                     -- Privilege mode
         P_STOP     : in  std_logic;                     -- Panel RUN F/F
         P_VIO_INT  : out std_logic;                     -- Memory Vio inter
         P_ADR_INT  : out std_logic;                     -- Bad Address inter
         P_MR       : out std_logic;                     -- Memory Request
         P_ADDR     : out std_logic_vector(15 downto 0); -- Physical address
         P_MMU_ADDR : in  std_logic_vector(15 downto 0); -- Virtual address
         P_DIN      : in  std_logic_vector(15 downto 0)  --TLBのエントリがOUTで
                                                         --はいる
         P_DOUT     : out std_logic_vector(15 downto 0);                                       
         --mmu kara cpu data bus : out warikomigenin to sono pe-ji
       );
end TAC_MMU;

--プロセス切替時、ページテーブルを読み込めるようにする

architecture Behavioral of TAC_MMU is
--signal i_en  : std_logic;                                -- Enable resister
--signal i_b   : std_logic_vector(15 downto 0);            -- Base  register
--signal i_l   : std_logic_vector(15 downto 0);            -- Limit register
--signal i_act : std_logic;                                -- Activate
--signal i_vio : std_logic;                                -- Memory Violation
--signal i_adr : std_logic;                                -- Bad Address

--TLB page index
signal p0 : std_logic_vector(7 downto 0);
signal p1 : std_logic_vector(7 downto 0);
signal p2 : std_logic_vector(7 downto 0);
signal p3 : std_logic_vector(7 downto 0);
signal p4 : std_logic_vector(7 downto 0);
signal p5 : std_logic_vector(7 downto 0);
signal p6 : std_logic_vector(7 downto 0);
signal p7 : std_logic_vector(7 downto 0);

--TLB page tabele entry
signal pte0 : std_logic_vector(15 downto 0);
signal pte1 : std_logic_vector(15 downto 0);
signal pte2 : std_logic_vector(15 downto 0);
signal pte3 : std_logic_vector(15 downto 0);
signal pte4 : std_logic_vector(15 downto 0);
signal pte5 : std_logic_vector(15 downto 0);
signal pte6 : std_logic_vector(15 downto 0);
signal pte7 : std_logic_vector(15 downto 0);

signal pte_out : std_logic_vector(15 downto 0);
signal p_in : std_logic_vector(7 downto 0);     --page number
signal offset : std_logic_vector(7 downto 0);
signal f_out : std_logic_vector(7 downto 0);    --frame number

p_in <= P_ADDR(15 downto 8);
offset <= P_ADDR(7 downto 0);
f_out <= pte_out(7 downto 0);

begin 

  --CAM
  process(P_CLK)
  begin 
    if (P_CLK'event and P_CLK='1') then
      if (p_in=p0)
        pte_out <= pte0;
      elsif (p_in=p1)
        pte_out <= pte1;
      elsif (p_in=p2)
        pte_out <= pte2;
      elsif (p_in=p3)
        pte_out <= pte3;
      elsif (p_in=p4)
        pte_out <= pte4;
      elsif (p_in=p5)
        pte_out <= pte5;
      elsif (p_in=p6)
        pte_out <= pte6;
      elsif (p_in=p7)
        pte_out <= pte7;
      end if;
    end if;
  end process;

--begin
  --process(P_RESET, P_CLK)
  --begin
    --if (P_RESET='0') then
      --i_b <= "0000000000000000";
      --i_l <= "0000000000000000";
      --i_en <= '0';
    --elsif (P_CLK'event and P_CLK='1') then
      --if (P_EN='1' and P_IOW='1') then
        --if (P_MMU_ADDR(2)='0') then
          --i_en <= P_DIN(0);
        --elsif (P_MMU_ADDR(1)='0') then
          --i_b <= P_DIN;
        --else
          --i_l <= P_DIN;
        --end if;
      --end if;
    --end if;
  --end process;

  --i_act <= (not P_PR) and (not P_STOP) and P_MMU_MR and i_en;
  --i_vio <= '1' when (P_MMU_ADDR>=i_l and i_act='1') else '0';
  --i_adr <= P_MMU_ADDR(0) and i_act and not P_BT;
  --P_ADDR <= (P_MMU_ADDR + i_b) when (i_act='1') else P_MMU_ADDR;
  --P_MR <= P_MMU_MR and (not i_vio);
  --P_VIO_INT <= i_vio;
  --P_ADR_INT <= i_adr;

end Behavioral;
