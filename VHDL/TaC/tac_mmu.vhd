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
-- 2021.12.09           : ページング方式に変更
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
         P_EN       : in  std_logic;                     -- i/o enable
         P_IOR      : in  std_logic;                     -- i/o read
         P_IOW      : in  std_logic;                     -- i/o write

         P_LI       : in  std_logic;                     -- inst. fetch(exec)
         P_PR       : in  std_logic;                     -- Privilege mode
         P_STOP     : in  std_logic;                     -- Panel RUN F/F
         P_WAIT     : out std_logic;                     -- Wait Request
         P_VIO_INT  : out std_logic;                     -- MemVio/BadAdr inter
         P_TLB_INT  : out std_logic;                     -- TLB miss inter

         -- from cpu
         P_ADDR     : in  std_logic_vector(15 downto 0); -- Virtual address
         P_MR       : in  std_logic;                     -- Memory Request
         P_RW       : in  std_logic;                     -- read/write
         P_BT       : in  std_logic;                     -- byte access
         P_DIN      : in  std_logic_vector(15 downto 0); -- Memory/IO data
         P_DOUT     : out std_logic_vector(15 downto 0); -- Memory/IO data

         -- to memory
         P_ADDR_MEM : out std_logic_vector(15 downto 0); -- Physical address
         P_MR_MEM   : out std_logic;                     -- Memory Request
         P_RW_MEM   : out std_logic;                     -- read/write
         P_BT_MEM   : out std_logic;                     -- byte access
         P_BANK_MEM : out std_logic;                     -- ipl bank
         P_DOUT_MEM : out std_logic_vector(15 downto 0); -- to memory
         P_DIN_MEM  : in  std_logic_vector(15 downto 0)  -- form memory
       );
end TAC_MMU;

architecture Behavioral of TAC_MMU is
signal i_en  : std_logic;                                -- Enable resister
--signal i_b   : std_logic_vector(15 downto 0);          -- Base  register
--signal i_l   : std_logic_vector(15 downto 0);          -- Limit register
signal i_act   : std_logic;                              -- Activate MMU
signal i_mis   : std_logic;                              -- TLB miss
signal i_vio   : std_logic;                              -- Memory Violation
signal i_adr   : std_logic;                              -- Bad Address

--TLBエントリのビット構成
--|<------ 8 ---->|<-- 5 -->|<-3->|<------ 8 ---->|
--+---------------+-+-+-+-+-+-----+---------------+
--|       PAGE    |V|*|*|R|D|R/W/X|      FRAME    |
--+---------------+-+-+-+-+-+-----+---------------+
-- 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0
--PAGE:ページ番号, V:Valid, *:未定義, R:Reference, D:Dirty,
--R/W/X:Read/Write/eXecute, FRAME:フレーム番号

subtype TLB_field is std_logic_vector(23 downto 0);
type TLB_array is array(0 to 7) of TLB_field;           -- array of 24bit * 8

signal TLB : TLB_array;
signal entry : TLB_field;                               -- target TLB entry
signal index : std_logic_vector(3 downto 0);            -- index of TLB entry
signal page : std_logic_vector(7 downto 0);             -- page no
signal offs : std_logic_vector(7 downto 0);             -- in page offset
signal i_mr : std_logic;                                -- memory request
signal i_rw : std_logic;                                -- memory write
signal i_li : std_logic;                                -- instruction fetch
signal intr_page : std_logic_vector(7 downto 0);        -- Page happend inter
signal intr_cause : std_logic_vector(1 downto 0):="00"; -- reason of inter
signal i_wait_stat : std_logic;

begin
  -- 1クロックのWaitを出力する
  P_WAIT <= (not i_wait_stat) and P_MR;
  process(P_CLK,P_RESET)
  begin
    if (P_RESET='0') then
      i_wait_stat <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if (P_MR='1' and i_wait_stat='0') then
        i_wait_stat <= '1';
      else
        i_wait_stat <= '0';
      end if;
    end if;
  end process;

  -- メモリアクセス関係の信号線はMMUの入り口でラッチする(10nsをTLB等が使用)
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      page  <= P_ADDR(15 downto 8);
      offs  <= P_ADDR(7  downto 0);
      i_mr  <= P_MR;
      i_rw  <= P_RW;
      i_li  <= P_LI;
      i_act <= (not P_PR) and (not P_STOP) and P_MR and i_en;
      i_adr <= P_ADDR(0) and not P_BT and P_MR;
      P_RW_MEM   <= P_RW;
      P_BT_MEM   <= P_BT;
      P_DOUT_MEM <= P_DIN;
    end if;
  end process;

  process(page,TLB)
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

  i_mis <= index(3) and i_act;

--  index <= X"0" when page & '1'=TLB(0)(23 downto 15) else
--           X"1" when page & '1'=TLB(1)(23 downto 15) else
--           X"2" when page & '1'=TLB(2)(23 downto 15) else
--           X"3" when page & '1'=TLB(3)(23 downto 15) else
--           X"4" when page & '1'=TLB(4)(23 downto 15) else
--           X"5" when page & '1'=TLB(5)(23 downto 15) else
--           X"6" when page & '1'=TLB(6)(23 downto 15) else
--           X"7" when page & '1'=TLB(7)(23 downto 15) else
--           X"8";
--
--  entry <= TLB(TO_INTEGER(unsigned (index(2 downto 0))));
--  request <= (not P_RW) & P_RW & P_LI;

  i_vio <= i_act and
           (((not i_rw) and (not entry(10))) or                -- read
            ((    i_rw) and (not entry( 9))) or                -- write
            ((    i_li) and (not (entry(10) and entry(8)))));  -- fetch

  -- i_vio <= not entry(9) when request="010" else    -- write
  --          not entry(10) when request="100" else   -- read
  --          not (entry(10) and entry(8));           -- fetch

  -- 物理アドレス
  P_ADDR_MEM(15 downto 8) <= entry(7 downto 0) when (i_act='1') else page;
  P_ADDR_MEM(7 downto 0) <= offs;

  -- 何も問題がない場合だけメモリをアクセスする
  P_MR_MEM <= i_mr and not (i_act and index(3));          -- タイミングが厳しい

  -- メモリ関係の例外をCPUに知らせる
  P_VIO_INT <= i_adr or i_vio;
  P_TLB_INT <= i_mis;

  --TLB操作
  process(P_CLK,P_RESET)
  begin
    if (P_RESET='0') then
      P_BANK_MEM <= '1';                            -- デバッグ用に'1'
      -- P_BANK_MEM <= '0';                            -- IPL ROM
      i_en <= '0';
      for I in TLB'range loop
        TLB(I)<=(others => '0');
      end loop;

    elsif (P_CLK'event and P_CLK='1') then
      if(P_EN='1' and P_IOW='1') then               -- 80h <= P_ADDR <=A9h
        if(P_ADDR(5 downto 4)="10") then              -- A-h
          if(P_ADDR(3 downto 1)="000") then           -- A0h or A1h
            P_BANK_MEM <= P_DIN(0);
          elsif(P_ADDR(3 downto 1)="001") then        -- A2h or A3h
            i_en <= P_DIN(0);
          elsif(P_ADDR(3 downto 1)="100") then        -- A8h or A9h
            for I in TLB'range loop
              TLB(I)<=(others => '0');
            end loop;
          end if;
        elsif(P_ADDR(1)='0') then                   -- 8-h or 9-h
          TLB(TO_INTEGER(unsigned(P_ADDR(4 downto 2))))(23 downto 16)
            <= P_DIN(7 downto 0);
        else
          TLB(TO_INTEGER(unsigned(P_ADDR(4 downto 2))))(15 downto 0)
            <= P_DIN;
        end if;

      --ページヒット時のD,Rビットの書き換え
      elsif(i_mis='0' and i_vio='0') then
          TLB(TO_INTEGER(unsigned(index(2 downto 0))))(11) <=       -- D bit
            entry(11) or i_rw;
          TLB(TO_INTEGER(unsigned(index(2 downto 0))))(12) <= '1';  -- R bit
      end if;
    end if;
  end process;

  --割り込みページとその原因のレジスタ
  process(P_CLK,P_RESET,P_ADDR,i_mis,i_adr,i_vio)
  begin
    if(P_RESET='0') then
      intr_cause <= "00";
    elsif(P_CLK'event and P_CLK='1') then
      if(i_mis='1') then
        intr_page <= page;
      end if;
      if(i_adr='1' or i_vio='1') then
        intr_cause <= intr_cause or (i_adr & i_vio);
      elsif(P_EN='1' and P_IOR='1' and P_ADDR(5 downto 1)="10010") then
        intr_cause <= "00";
      end if;
    end if;
  end process;

  -- CPU への出力
  P_DOUT <= P_DIN_MEM when (P_IOR='0') else               -- 通常はメモリ

            "00000000" & TLB(TO_INTEGER(unsigned          -- TLBの上位8ビット
            (P_ADDR(4 downto 2))))(23 downto 16)
            when (P_ADDR(1)='0' and P_ADDR(5)='0') else

            TLB(TO_INTEGER(unsigned                       -- TLBの下位16ビット
            (P_ADDR(4 downto 2))))(15 downto 0)
            when (P_ADDR(1)='1' and P_ADDR(5)='0') else

            "00000000" & intr_page                        --A6h ページ番号
            when (P_ADDR(1)='1' and P_ADDR(5)='1') else

            "00000000000000" & intr_cause;           --A4h 割り込み原因　下2桁


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
        --if (P_ADDR(2)='0') then
          --i_en <= P_DIN(0);
        --elsif (P_ADDR(1)='0') then
          --i_b <= P_DIN;
        --else
          --i_l <= P_DIN;
        --end if;
      --end if;
    --end if;
  --end process;

  --i_act <= (not P_PR) and (not P_STOP) and P_MR and i_en;
  --i_vio <= '1' when (P_ADDR>=i_l and i_act='1') else '0';
  --i_adr <= P_ADDR(0) and i_act and not P_BT;
  --P_ADDR_MEM <= (P_ADDR + i_b) when (i_act='1') else P_ADDR;
  --P_MR_MEM <= P_MR and (not i_vio);
  --P_VIO_INT <= i_vio;
  --P_ADR_INT <= i_adr;

end Behavioral;
