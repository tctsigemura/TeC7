--
-- TaC VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2017 - 2019 by
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
--  TaC/tac_RN4020.vhd : RN4020 インタフェース
--
-- 2019.04.13 : TeC7d 用に RN4020_CON 追加，RN4020_SW 削除
-- 2019.02.26 : 接続状態を記録するためのRESETされないレジスタ追加
-- 2018.07.13 : 受信バッファ（FIFO）を追加
-- 2018.07.12 : SIOを取り込む
-- 2017.05.09 : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_RN4020 is
  port ( P_CLK     : in  std_logic;                      -- 49.1520MHz
         P_RESET   : in  std_logic;                      -- Reset
         P_IOW     : in  std_logic;                      -- I/O Write
         P_IOR     : in  std_logic;                      -- I/O Read
         P_EN      : in  std_logic;                      -- Enable
         P_ADDR    : in  std_logic_vector(1 downto 0);   -- Address(2 downto 1)
         P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
         P_DIN     : in  std_logic_vector(7 downto 0);   -- Data Input
         P_INT_TxD : out std_logic;                      -- 送信割り込み
         P_INT_RxD : out std_logic;                      -- 受信割り込み

         P_TxD     : out std_logic;                      -- シリアル出力
         P_RxD     : in  std_logic;                      -- シリアル入力
         P_CTS     : in  std_logic;                      -- Clear To Send
         P_RTS     : out std_logic;                      -- Request To Send

         P_CMD     : out std_logic;                      -- RN4020_CMD/MLDP
         P_CON     : in  std_logic;                      -- RN4020_CON
         P_HW      : out std_logic                       -- RN4020_HW
       );
end TAC_RN4020;

architecture RTL of TAC_RN4020 is

-- Address decode
signal i_en_cmd   : std_logic;
signal i_iow_cmd  : std_logic;
signal i_ior_cmd  : std_logic;

signal i_en_dat   : std_logic;
signal i_iow_dat  : std_logic;
signal i_ior_dat  : std_logic;

signal i_en_ctl   : std_logic;
signal i_iow_ctl  : std_logic;
signal i_ior_sta  : std_logic;

signal i_en_ram   : std_logic;
signal i_iow_ram  : std_logic;
--signal i_ior_ram  : std_logic;
signal i_ram : std_logic_vector(7 downto 1) := "0000000";

-- Internal bus
signal i_cts      : std_logic;
signal i_rts      : std_logic;

-- Registers
signal i_cmd      : std_logic_vector(3 downto 0);
signal i_tx_dat   : std_logic_vector(7  downto 0);
signal i_tx_sft   : std_logic_vector(7  downto 0);
signal i_tx_out   : std_logic;
signal i_tx_fll   : std_logic;
signal i_tx_ena   : std_logic;
signal i_tx_cnt1  : std_logic_vector(12 downto 0);
signal i_tx_cnt2  : std_logic_vector(3  downto 0);
signal i_tx_ei    : std_logic;
signal i_tx_cts   : std_logic;

signal i_rx_dat   : std_logic_vector(7  downto 0);
signal i_rx_sft   : std_logic_vector(7  downto 0);
signal i_rx_ena   : std_logic;
signal i_rx_cnt1  : std_logic_vector(12 downto 0);
signal i_rx_cnt2  : std_logic_vector(3  downto 0);
signal i_rx_ei    : std_logic;
signal i_rx_db1   : std_logic;
signal i_rx_db2   : std_logic;
signal i_rx_fll   : std_logic;
signal i_rx_wrt   : std_logic;
signal i_rx_red   : std_logic;
signal i_rx_emp   : std_logic;
signal i_rx_smp   : std_logic;

-- ボーレートを決定する定数
constant BAUDIV  : std_logic_vector(12 downto 0) := "0000110101011";
-- 49.1520MHz / 9600   = 5120  (0001 0100 0000 0000b)
-- 49.1520MHz / 19200  = 2560  (0000 1010 0000 0000b)
-- 49.1520MHz / 38400  = 1280  (0000 0101 0000 0000b)
-- 49.1520MHz / 115200 = 426.7 (0000 0001 1010 1011b)

component TAC_FIFO is
  generic (
    width     : integer;
    depth     : integer;
    threshold : integer
    );
  port (
    P_CLK   : in  std_logic;
    P_RESET : in  std_logic;

    P_FULL  : out std_logic;
    P_WRITE : in  std_logic;
    P_DIN   : in  std_logic_vector(width-1 downto 0);

    P_EMPTY : out std_logic;
    P_READ  : in  std_logic;
    P_DOUT  : out std_logic_vector(width-1 downto 0)
  );
end component;

begin
  -- FiFo
  TAC_FIFO0 : TAC_FIFO generic map (
    width     => 8,
    depth     => 128,
    threshold => 7)
    port map (P_CLK, P_RESET, i_rx_fll, i_rx_wrt, i_rx_sft,
              i_rx_emp, i_rx_red, i_rx_dat);

  -- Address decoder
  i_en_cmd <= '1' when (P_ADDR="10" and P_EN='1') else '0';
  i_iow_cmd <= P_IOW and i_en_cmd;
  i_ior_cmd <= P_IOR and i_en_cmd;

  i_en_dat <= '1' when (P_ADDR="00" and P_EN='1') else '0';
  i_iow_dat <= P_IOW and i_en_dat;
  i_ior_dat <= P_IOR and i_en_dat;

  i_en_ctl <= '1' when (P_ADDR="01" and P_EN='1') else '0';
  i_iow_ctl <= P_IOW and i_en_ctl;
  i_ior_sta <= P_IOR and i_en_ctl;

  i_en_ram <= '1' when (P_ADDR="11" and P_EN='1') else '0';
  i_iow_ram <= P_IOW and i_en_ram;
--i_ior_ram <= P_IOR and i_en_ram;

  -- Data Bus
  P_DOUT <= ("0000" & i_cmd) when i_ior_cmd='1' else
            i_rx_dat when i_ior_dat='1' else
            ((not i_tx_fll)&(not i_rx_emp)&"000000") when i_ior_sta='1' else
            i_ram & P_CON;

  -- CMD
  P_CMD <= i_cmd(1);
  P_HW  <= i_cmd(2);
  i_cts <= (not i_cmd(3)) or P_CTS;     -- ハードウェアフロー制御OFFなら常時ON
  P_RTS <= (not i_cmd(3)) or i_rts;     -- ハードウェアフロー制御OFFなら常時ON

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_cmd <= "0001";
    elsif (P_CLK'event and P_CLK='1') then
      if (i_iow_cmd='1') then
        i_cmd <= P_DIN(3 downto 0);
      end if;
    end if;
  end process;

  -- Ctl
  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_tx_ei <= '0';
      i_rx_ei <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if (i_iow_ctl='1') then
        i_tx_ei <= P_DIN(7);
        i_rx_ei <= P_DIN(6);
      end if;
    end if;
  end process;

  -- Debounce
  process (P_CLK, P_RESET)
  begin
    if (P_CLK'event and P_CLK='1') then
      i_tx_cts <= i_cts;
      i_rx_db1 <= P_RxD;
      i_rx_db2 <= i_rx_db1;
    end if;
  end process;

  -- Tx
  P_TXD <= i_tx_out or (not i_tx_ena);
  P_INT_TxD <= (not i_tx_fll) and i_tx_ei;

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_tx_dat <= "00000000";
      i_tx_fll <= '0';
    elsif (P_CLK' event and P_CLK='1') then
      if (i_iow_dat='1') then
        i_tx_dat <= P_DIN;
        i_tx_fll <= '1';
      elsif (i_tx_ena='0' and i_tx_cts='1') then
        i_tx_fll <= '0';
      end if;
    end if;
  end process;

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_tx_sft <= "00000000";
      i_tx_out <= '0';
      i_tx_ena <= '0';
      i_tx_cnt1 <= "0000000000000";
      i_tx_cnt2 <= "0000";
    elsif (P_CLK' event and P_CLK='1') then
      if (i_tx_ena='1') then
        if (i_tx_cnt1=BAUDIV) then
          i_tx_out <= i_tx_sft(0);
          i_tx_sft(6 downto 0) <= i_tx_sft(7 downto 1);
          i_tx_sft(7) <= '1';
          i_tx_cnt1 <= "0000000000000";
          if (i_tx_cnt2="1001") then
            i_tx_ena <= '0';
            i_tx_cnt2 <= "0000";
          else
            i_tx_cnt2 <= i_tx_cnt2 + 1;
          end if;
        else
          i_tx_cnt1 <= i_tx_cnt1 + 1;
        end if;
      elsif (i_tx_fll='1' and i_tx_cts='1') then
        i_tx_sft <= i_tx_dat;
        i_tx_out <= '0';
        i_tx_ena <= '1';
        i_tx_cnt1 <= "0000000000000";
      end if;
    end if;
  end process;

  -- Rx
  i_rts <= not i_rx_fll;
  P_INT_RxD <= (not i_rx_emp) and i_rx_ei and (not i_rx_red);  -- Edge Trigger
  i_rx_smp <= '1' when i_rx_cnt1 = '0'&BAUDIV(12 downto 1) else '0';
  i_rx_wrt <= '1' when i_rx_smp='1' and i_rx_cnt2="1001" else '0';

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_rx_red <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if (i_ior_dat='1') then
        i_rx_red <= '1';
      else
        i_rx_red <= '0';
      end if;
    end if;
  end process;

  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_rx_sft <= "00000000";
      i_rx_ena <= '0';
      i_rx_cnt1 <= "0000000000000";
      i_rx_cnt2 <= "0000";
    elsif (P_CLK'event and P_CLK='1') then
      if (i_rx_ena='1') then
        if (i_rx_smp='1') then
          i_rx_sft(6 downto 0) <= i_rx_sft(7 downto 1);
          i_rx_sft(7) <= i_rx_db2;
          if (i_rx_cnt2="0000" and i_rx_db2='1') then  -- check start bit
            i_rx_ena <= '0';                           -- not start bit
          elsif (i_rx_cnt2="1001") then
            i_rx_ena <= '0';
            i_rx_cnt2 <= "0000";
          else
            i_rx_cnt2 <= i_rx_cnt2 + 1;
          end if;
        end if;
        if (i_rx_cnt1=BAUDIV) then
          i_rx_cnt1 <= "0000000000000";
        else
          i_rx_cnt1 <= i_rx_cnt1 + 1;
        end if;
      elsif (i_rx_db1='0' and i_rx_db2='1') then  -- expet start bit
        i_rx_ena  <= '1';
        i_rx_cnt1 <= "0000000000000";
      end if;
    end if;
  end process;

  -- RAM
  process (P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (i_iow_ram='1') then
        i_ram <= P_DIN(7 downto 1);
      end if;
    end if;
  end process;

end RTL;
