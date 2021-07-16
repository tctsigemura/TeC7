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
         P_DIN      : in  std_logic_vector(15 downto 0); --TLBのエントリ
         P_DOUT     : out std_logic_vector(15 downto 0);         
         P_IOR      : out std_logic;                     --どのページでミスしたか知らせる  
       );
end TAC_MMU;

--プロセス切替時、ページテーブルを読み込めるようにする

architecture Behavioral of TAC_MMU is
signal i_en  : std_logic;                                -- Enable resister
--signal i_b   : std_logic_vector(15 downto 0);            -- Base  register
--signal i_l   : std_logic_vector(15 downto 0);            -- Limit register
signal i_act : std_logic;                                -- Activate MMUが動くか
signal i_vio : std_logic;                                -- Memory Violation
--signal i_adr : std_logic;                                -- Bad Address

subtype TLB_field is std_logic_vector(23 downto 0);     --page + ctrl + frame
type TLB_array is array (7 downto 0) of TLB_field;      --24bit * 8 array

signal TLB : TLB_array;                                 --TLB
signal tar_field : TLB_field;                           --検索したtlb field
signal key_page : std_logic_vector(7 downto 0);         --キーとなるページ番号  
signal tar_frame : std_logic_vector(7 downto 0);        --frame number
signal entry : std_logic_vector(15 downto 0);           --c + frame
signal index : std_logic_vector(10 downto o);           --n + page
signal flag : std_logic;

begin 

  key_page <= P_ADDR(15 downto 8);                        
  offset <= P_ADDR(7 downto 0);
  tar_frame <= tar_field(7 downto 0);

  --CAM for loopが使える？
  process(P_CLK)
  begin 
    if (P_CLK'event and P_CLK='1') then
    --if(なにかしらの条件)
        if (key_page=TLB[0])
          tar_field <= TLB[0];
        elsif (key_page=TLB[1])
          tar_field <= TLB[1];
        elsif (key_page=TLB[2])
          tar_field <= TLB[2];
        elsif (key_page=TLB[3])
          tar_field <= TLB[3];
        elsif (key_page=TLB[4])
          tar_field <= TLB[4];
        elsif (key_page=TLB[5])
          tar_field <= TLB[5];
        elsif (key_page=TLB[6])
          tar_field <= TLB[6];
        elsif (key_page=TLB[7])
          tar_field <= TLB[7];
        end if;
    --else page miss
    --end if;
    end if
  end process
  
  --エントリの入れ替え
  process(P_CLK)
  begin 
    if(P_RESET]=0) then
      --TLB clear?
      i_en <= 0;
    elsif (P_CLK'event and P_CLK='1') then
      if(P_EN='1' and P_IOW='1') then //書き込みモード時はP_MMU_ADDRとP_DIN
        if(P_MMU_ADDR(2)='0') then
          i_en <= '1';
        elsif(P_MMU_ADDR(1)='0') then    
          entry <= P_DIN;
        else
          index <= P_DIN;
          flag <= '1';
        end if;
      end if;
    end if;
  end process;

  --for loopかcaseが使える？
  process(P_CLK)
  begin
    if(P_CLK'event and P_CLK='1') then
      if(f='1') then
        if(index(10 downto 8)="000") then
          TLB[0](23 downto 16) <= index(7 downto 0);
          TLB[0](15 downto 0) <= entry;
        elsif (index(10 downto 8)="001")
          TLB[1](23 downto 16) <= index(7 downto 0);
          TLB[1](15 downto 0) <= entry;
        elsif (index(10 downto 8)="010")
          TLB[2](23 downto 16) <= index(7 downto 0);
          TLB[2](15 downto 0) <= entry;
        elsif (index(10 downto 8)="011")
          TLB[3](23 downto 16) <= index(7 downto 0);
          TLB[3](15 downto 0) <= entry;
        elsif (index(10 downto 8)="100")
          TLB[4](23 downto 16) <= index(7 downto 0);
          TLB[4](15 downto 0) <= entry;
        elsif (index(10 downto 8)="101")
          TLB[5](23 downto 16) <= index(7 downto 0);
          TLB[5](15 downto 0) <= entry;
        elsif (index(10 downto 8)="110")
          TLB[6](23 downto 16) <= index(7 downto 0);
          TLB[6](15 downto 0) <= entry;
        elsif (index(10 downto 8)="111")
          TLB[7](23 downto 16) <= index(7 downto 0);
          TLB[7](15 downto 0) <= entry;
        end if;
      end if;
      f <= '0';
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
