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
use IEEE.numeric_std.ALL;

entity TAC_MMU is
  Port ( P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_EN       : in  std_logic;               
         P_IOW      : in  std_logic;
         P_RW       : in  std_logic;                     -- read write
         P_LI       : in  std_logic;                     -- instruction fetch
         P_MMU_MR   : in  std_logic;                     -- Memory Request(CPU)
         P_BT       : in  std_logic;                     -- Byte access
         P_PR       : in  std_logic;                     -- Privilege mode
         P_STOP     : in  std_logic;                     -- Panel RUN F/F
         P_VIO_INT  : out std_logic;                     -- Mem Vio bad adr inter
         P_TLB_INT  : out std_logic;                     -- TLB miss inter
         P_MR       : out std_logic;                     -- Memory Request
         P_ADDR     : out std_logic_vector(15 downto 0); -- Physical address
         P_MMU_ADDR : in  std_logic_vector(15 downto 0); -- Virtual address
         P_DIN      : in  std_logic_vector(15 downto 0); -- data from cpu
         P_DOUT     : out std_logic_vector(15 downto 0)  -- 
       );
end TAC_MMU;

architecture Behavioral of TAC_MMU is
signal i_en  : std_logic;                                -- Enable resister
--signal i_b   : std_logic_vector(15 downto 0);            -- Base  register
--signal i_l   : std_logic_vector(15 downto 0);            -- Limit register
signal i_act : std_logic;                                -- Activate MMU
signal i_vio : std_logic;                                -- Memory Violation
signal i_mis : std_logic;                                -- TLB miss
signal i_adr : std_logic;                                -- Bad Address

--TLBエントリのビット構成
--|<------ 8 ---->|<-- 5 -->|<-3->|<------ 8 ---->|
--+---------------+-+-+-+-+-+-----+---------------+
--|       PAGE    |V|*|*|R|D|R/W/X|      FRAME    |
--+---------------+-+-+-+-+-+-----+---------------+
-- 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 
--PAGE:ページ番号, V:Valid, *:未定義, R:Reference, D:Dirty,
--R/W/X:Read/Write/eXecute, FRAME:フレーム番号

subtype TLB_field is std_logic_vector(23 downto 0); 
type TLB_array is array(0 to 7) of TLB_field;           --array of 24bit * 8 

signal TLB : TLB_array;                                 --TLB
signal index : std_logic_vector(3 downto 0);            
signal entry : TLB_field;                               --target TLB entry 
signal page : std_logic_vector(7 downto 0);
signal offset : std_logic_vector(7 downto 0);
signal v_addr : std_logic_vector(15 downto 0);
signal tlbmiss : std_logic;                             -- not exist page
signal request : std_logic_vector(2 downto 0);          --RWX request from cpu
signal perm_vio : std_logic;                            --RWX Violation

begin 
  page <= v_addr(15 downto 8);
  offset <= v_addr(7 downto 0);
  request <= not P_RW & P_RW & P_LI;    --RWX どれか一つが'1'
  
  entry <= TLB(TO_INTEGER(unsigned (index(2 downto 0))));
  tlbmiss <= index(3);
  perm_vio <= '1' when (request and entry(10 downto 8))="000" else '0';

  index <= X"0" when page & '1'=TLB(0)(23 downto 15) else
           X"1" when page & '1'=TLB(1)(23 downto 15) else
           X"2" when page & '1'=TLB(2)(23 downto 15) else
           X"3" when page & '1'=TLB(3)(23 downto 15) else
           X"4" when page & '1'=TLB(4)(23 downto 15) else
           X"5" when page & '1'=TLB(5)(23 downto 15) else
           X"6" when page & '1'=TLB(6)(23 downto 15) else
           X"7" when page & '1'=TLB(6)(23 downto 15) else
           X"8";

  --register CPUからの仮想アドレスを保時
  process(P_CLK,P_MMU_MR)
  begin
    if(P_CLK'event and P_CLK='1') then
      if(i_act='1') then
        v_addr <= P_MMU_ADDR;
      end if;
    end if;
  end process;

  --TLB操作
  process(P_CLK,P_RESET)
  begin 
    if (P_RESET='0') then
      i_en <= '0';
    elsif (P_CLK'event and P_CLK='1') then

      if(P_EN='1' and P_IOW='1') then
        if(P_MMU_ADDR(5 downto 4)='11') then
          if(P_MMU_ADDR(1)='1') then
            i_en <= P_DIN(0);
          end if;
        elsif(P_MMU_ADDR(1)='0') then
          TLB(TO_INTEGER(unsigned(not P_MMU_ADDR(4) & P_MMU_ADDR(3 downto 2))))
            (23 downto 16) <= P_DIN(7 downto 0);
        else
          TLB(TO_INTEGER(unsigned(not P_MMU_ADDR(4) & P_MMU_ADDR(3 downto 2))))
            (15 downto 0) <= P_DIN;
        end if;

      --ページヒット時のD,Rビットの書き換え
      elsif(tlbmiss='0' and i_act='1') then 
        if (perm_vio='0') then
          if(request(1)='1') then
            TLB(TO_INTEGER(unsigned (index(2 downto 0))))(11) <= '1';
          end if;
          if((request(2) or request(0))='1') then
            TLB(TO_INTEGER(unsigned (index(2 downto 0))))(12) <= '1'; 
          end if; 
        end if;
      end if; --if(P_EN='1' and P_IOW='1')
    
    end if;
  end process;

  i_act <= (not P_PR) and (not P_STOP) and P_MMU_MR and i_en;
  i_vio <= i_act and perm_vio;
  i_adr <= P_MMU_ADDR(0) and i_act and not P_BT;           
  i_mis <= i_act and tlbmiss;                               --TLB MISS

  P_ADDR <= entry(7 downto 0) & offset when (i_act='1') else
            P_MMU_ADDR;

  P_MR <= P_MMU_MR and (not i_vio) and (not i_mis);
  P_VIO_INT <= i_adr or i_vio;    
  P_TLB_INT <= i_mis;                       
  
  --割り込み時の出力
  P_DOUT <= "00000000" & TLB(TO_INTEGER(unsigned                             --TLBの上位8ビット
            (not P_MMU_ADDR(4) & P_MMU_ADDR(3 downto 2))))(23 downto 16)   
            when (P_MMU_ADDR(1)='0' and P_MMU_ADDR(5 downto 4)<"11") else

            TLB(TO_INTEGER(unsigned                                          --TLBの下位16ビット
            (not P_MMU_ADDR(4) & P_MMU_ADDR(3 downto 2))))(15 downto 0)                  
            when (P_MMU_ADDR(1)='1' and P_MMU_ADDR(5 downto 4)<"11") else
            
            "00000000" & page                                                --F4h ページ番号
            when (P_MMU_ADDR(1)='0' and P_MMU_ADDR(5 downto 4)="11") else            
            "0000000000000000" when i_adr='1' else                           --F2h 奇数アドレス
            "0000000000000001" when i_vio='1' else                           --F2h RWX違反                                                
            "XXXXXXXXXXXXXXXX";

--relocation register
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
