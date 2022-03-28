--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2011-2022 by
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
-- 2022.03.21           : 動作テスト完了
-- 2021.12.09           : ページング方式に変更開始
-- 2019.12.19           : CPU停止時（コンソール動作時）はアドレス変換禁止
-- 2019.07.30           : アドレスエラー追加
-- 2019.01.22           : 新しく追加
--

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

entity TAC_MMU is
  Port ( P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_EN       : in  std_logic;                     -- i/o enable
         P_IOR      : in  std_logic;                     -- i/o read
         P_IOW      : in  std_logic;                     -- i/o write

         P_LI       : in  std_logic;                     -- inst. fetch(exec)
         P_PR       : in  std_logic;                     -- Privilege mode
         P_WAIT     : out std_logic;                     -- Wait Request
         P_VIO_INT  : out std_logic;                     -- MemVio/BadAdr excp.
         P_TLB_INT  : out std_logic;                     -- TLB miss exception

         -- from cpu
         P_ADDR     : in  std_logic_vector(15 downto 0); -- Virtual address
         P_MR       : in  std_logic;                     -- Memory Request
         P_RW       : in  std_logic;                     -- read/write
         P_BT       : in  std_logic;                     -- byte access
         P_DIN      : in  std_logic_vector(15 downto 0); -- data from cpu
         P_DOUT     : out std_logic_vector(15 downto 0); -- data to cpu

         -- to memory
         P_ADDR_MEM : out std_logic_vector(15 downto 0); -- Physical address
         P_MR_MEM   : out std_logic;                     -- Memory Request
         P_RW_MEM   : out std_logic;                     -- read/write
         P_BT_MEM   : out std_logic;                     -- byte access
         P_BANK_MEM : out std_logic;                     -- ipl bank
         P_DOUT_MEM : out std_logic_vector(15 downto 0); -- to memory
         P_DIN_MEM  : in  std_logic_vector(15 downto 0)  -- from memory
       );
end TAC_MMU;

architecture Behavioral of TAC_MMU is
signal enMmu   : std_logic;                              -- Enable MMU
signal mapPage : std_logic;                              -- activate mapping
signal tlbMiss : std_logic;                              -- TLB miss
signal memVio  : std_logic;                              -- Memory Violation
signal badAdr  : std_logic;                              -- Bad Address

--TLBエントリのビット構成
--|<------ 8 ---->|<-- 5 -->|<-3->|<------ 8 ---->|
--+---------------+-+-+-+-+-+-----+---------------+
--|       PAGE    |V|*|*|R|D|R/W/X|      FRAME    |
--+---------------+-+-+-+-+-+-----+---------------+
-- 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
--PAGE:ページ番号, V:Valid, *:未定義, R:Reference, D:Dirty,
--R/W/X:Read/Write/eXecute, FRAME:フレーム番号

subtype TlbField is std_logic_vector(23 downto 0);
type TlbArray is array(0 to 7) of TlbField;             -- array of 24bit * 8

signal TLB     : TlbArray;                              -- TLB
signal entry   : TlbField;                              -- target TLB entry
signal index   : std_logic_vector(3 downto 0);          -- index of TLB entry
signal page    : std_logic_vector(7 downto 0);          -- page no
signal offs    : std_logic_vector(7 downto 0);          -- in page offset

signal memReq  : std_logic;                             -- memory request
signal memWrt  : std_logic;                             -- memory write
signal insFet  : std_logic;                             -- instruction fetch
signal fltPage : std_logic_vector(7 downto 0);          -- Page happend fault
signal fltRsn  : std_logic_vector(1 downto 0);          -- reason of fault
signal fltAdr  : std_logic_vector(15 downto 0);         -- address of fault
signal waitSt  : std_logic;                             -- wait status

begin
  -- 1クロックのWaitを出力する
  P_WAIT <= (not waitSt) and P_MR;
  process(P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      waitSt <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if (P_MR='1' and waitSt='0') then
        waitSt <= '1';
      else
        waitSt <= '0';
      end if;
    end if;
  end process;

  -- メモリアクセス関係の信号線はMMUの入り口でラッチする(10nsをTLB等が使用)
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      page    <= P_ADDR(15 downto 8);
      offs    <= P_ADDR(7  downto 0);
      memReq  <= P_MR;
      memWrt  <= P_RW;
      insFet  <= P_LI;
      badAdr  <= P_ADDR(0) and (not P_BT) and P_MR;
      mapPage <= (not P_PR) and P_MR and enMmu;
      P_RW_MEM <= P_RW;
      P_BT_MEM <= P_BT;
      P_DOUT_MEM <= P_DIN;
    end if;
  end process;

  -- TLB の検索
  process(page, TLB)
  begin
    if    (page & '1'=TLB(0)(23 downto 15)) then
      index <= X"0";
      entry <= TLB(0);
    elsif (page & '1'=TLB(1)(23 downto 15)) then
      index <= X"1";
      entry <= TLB(1);
    elsif (page & '1'=TLB(2)(23 downto 15)) then
      index <= X"2";
      entry <= TLB(2);
    elsif (page & '1'=TLB(3)(23 downto 15)) then
      index <= X"3";
      entry <= TLB(3);
    elsif (page & '1'=TLB(4)(23 downto 15)) then
      index <= X"4";
      entry <= TLB(4);
    elsif (page & '1'=TLB(5)(23 downto 15)) then
      index <= X"5";
      entry <= TLB(5);
    elsif (page & '1'=TLB(6)(23 downto 15)) then
      index <= X"6";
      entry <= TLB(6);
    elsif (page & '1'=TLB(7)(23 downto 15)) then
      index <= X"7";
      entry <= TLB(7);
    else
      index <= "1XXX";
      entry <= (others => 'X');
    end if;
  end process;

  -- TLB ミス例外
  tlbMiss <= mapPage and index(3);

  -- メモリ保護例外
  memVio  <= mapPage and (not index(3)) and
           (((not memWrt) and (not entry(10))) or                -- read
            ((    memWrt) and (not entry( 9))) or                -- write
            ((    insFet) and (not (entry(10) and entry(8)))));  -- fetch

  -- 物理アドレス
  P_ADDR_MEM(15 downto 8) <= entry(7 downto 0) when (mapPage='1') else page;
  P_ADDR_MEM(7 downto 0) <= offs;

  -- 例外が発生していなければメモリをアクセスする
  --   タイミングが厳しい．
  --     アドレス違反やメモリ保護違反でメモリを破壊しても
  --     プロセスを打ち切ればよいので妥協することにする．
  -- P_MR_MEM <= memReq and not (tlbMiss or badAdr or memVio);
  P_MR_MEM <= memReq and not tlbMiss;

  -- メモリ関係の例外をCPUに知らせる
  P_VIO_INT <= badAdr or memVio;            -- 割り込みコントローラだけに接続
  P_TLB_INT <= tlbMiss;                     -- 割り込みコントローラとCPUに接続

  --TLB操作
  process(P_CLK,P_RESET)
  begin
    if (P_RESET='0') then
      P_BANK_MEM <= '0';                                -- IPL ROM
      enMmu <= '0';                                     -- MMU Enable
    elsif (P_CLK'event and P_CLK='1') then
      if(P_EN='1' and P_IOW='1') then                   -- IO[80h - A9h]
        if(P_ADDR(5 downto 4)="10") then                --   Axh
          if(P_ADDR(3 downto 1)="000") then             --    A0h or A1h
            P_BANK_MEM <= P_DIN(0);
          elsif(P_ADDR(3 downto 1)="001") then          --    A2h or A3h
            enMmu <= P_DIN(0);
          end if;
        elsif(P_ADDR(1)='0') then                       --   8xh or 9xh (TLB)
          TLB(conv_integer(P_ADDR(4 downto 2)))(23 downto 16)
            <= P_DIN(7 downto 0);
        else
          TLB(conv_integer(P_ADDR(4 downto 2)))(15 downto 0)
            <= P_DIN;
        end if;
      elsif(mapPage='1' and
            tlbMiss='0' and memVio='0') then            -- TLB Hit
        TLB(conv_integer(index(2 downto 0)))(11) <=     -- D bit
          entry(11) or memWrt;
        TLB(conv_integer(index(2 downto 0)))(12) <= '1'; -- R bit
      end if;
    end if;
  end process;

  --割り込みページとその原因のレジスタ
  process(P_CLK, P_RESET)
  begin
    if(P_RESET='0') then
      fltRsn <= "00";
    elsif(P_CLK'event and P_CLK='1') then
      if(tlbMiss='1') then                              -- TLB miss なら
        fltPage <= page;                                --   原因ページを記憶
      end if;
      if(badAdr='1' or memVio='1') then                 -- その他例外なら
        fltRsn <= fltRsn or (badAdr & memVio);          --   原因を記憶
        fltAdr <= page & offs;                          --   原因アドレスを記憶
      elsif(P_EN='1' and P_IOR='1' and
            P_ADDR(5 downto 1)="10010") then            -- IO[A4h - A5h]
        fltRsn <= "00";
      end if;
    end if;
  end process;

  -- CPU への出力
  P_DOUT <=
      P_DIN_MEM when (P_IOR='0') else                     -- 通常はメモリ
      "00000000" & TLB(conv_integer(P_ADDR(4 downto 2)))(23 downto 16)
        when (P_ADDR(5)='0' and P_ADDR(1)='0') else       -- 80h,84h,...,9Ch
      TLB(conv_integer(P_ADDR(4 downto 2)))(15 downto 0)
        when (P_ADDR(5)='0') else                         -- 82h,86h,...,9Eh
      fltAdr when (P_ADDR(2)='0') else                    -- A2h 割込み原因Adr
      "00000000000000" & fltRsn when (P_ADDR(1)='0') else -- A4h 割込み原因
      "00000000" & fltPage;                               -- A6h TLBmissページ

end Behavioral;
