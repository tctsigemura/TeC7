--
-- TaC VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2017 by
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
-- 2017.05.09          : 新規作成
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

         P_SW      : out std_logic;                      -- RN4020_SW
         P_CMD     : out std_logic;                      -- RN4020_CMD/MLDP
         P_HW      : out std_logic                       -- RN4020_HW
       );
end TAC_RN4020;

architecture RTL of TAC_RN4020 is

-- Address decode
signal i_en_sio    : std_logic;
signal i_en_cmd    : std_logic;

-- Internal bus
signal i_data      : std_logic_vector(7 downto 0);
signal i_cts       : std_logic;
signal i_rts       : std_logic;

-- Registers
signal i_cmd       : std_logic_vector(3 downto 0) := "0001";

-- SIO
component TAC_SIO
  port ( P_CLK     : in  std_logic;                      -- 49.1520MHz
         P_RESET   : in  std_logic;                      -- Reset
         P_IOW     : in  std_logic;                      -- I/O Write
         P_IOR     : in  std_logic;                      -- I/O Read
         P_EN      : in  std_logic;                      -- Enable
         P_ADDR    : in  std_logic;                      -- Address
         P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
         P_DIN     : in  std_logic_vector(7 downto 0);   -- Data Input
         P_INT_TxD : out std_logic;                      -- SIO 送信割り込み
         P_INT_RxD : out std_logic;                      -- SIO 受信割り込み

         P_TxD     : out std_logic;                      -- シリアル出力
         P_RxD     : in  std_logic;                      -- シリアル入力
         P_CTS     : in  std_logic;                      -- Clear To Send
         P_RTS     : out std_logic;                      -- Request To Send

         P_BAUDIV  : in  std_logic_vector(12 downto 0)   -- Baud Divsior
       );
end component;

begin
  -- Address decoder
  i_en_sio <= (not P_ADDR(1)) and P_EN;
  i_en_cmd <= '1' when (P_ADDR="10" and P_EN='1') else '0';
  
  -- Data Bus
  P_DOUT <= i_data when i_en_sio='1' else
            "0000"&i_cmd when i_en_cmd='1' else "00000000";

  -- CMD
  P_SW  <= i_cmd(0);
  P_CMD <= i_cmd(1);
  P_HW  <= i_cmd(2);
    
  process (P_CLK, P_RESET)
  begin
    if (P_RESET='0') then
      i_cmd <= "0001";
    elsif (P_CLK'event and P_CLK='1') then
      if (P_IOW='1' and i_en_cmd='1') then
        i_cmd <= P_DIN(3 downto 0);
      end if;
    end if;
  end process;

  -- SIO
  i_cts <= (not i_cmd(3)) or P_CTS;     -- ハードウェアフロー制御OFFなら常時ON
  P_RTS <= (not i_cmd(3)) or i_rts;     -- ハードウェアフロー制御OFFなら常時ON

  TAC_SIO1 : TAC_SIO
  port map (
         P_CLK      => P_CLK,
         P_RESET    => P_RESET,
         P_IOW      => P_IOW,
         P_IOR      => P_IOR,
         P_EN       => i_en_sio,
         P_ADDR     => P_ADDR(0),
         P_DOUT     => i_data,
         P_DIN      => P_DIN,
         P_INT_TxD  => P_INT_TxD,
         P_INT_RxD  => P_INT_RxD,
         P_TxD      => P_TxD,
         P_RxD      => P_RxD,
         P_CTS      => i_cts,
         P_RTS      => i_rts,
         P_BAUDIV   => "0000110101011"  -- 115,200 baud
       );
end RTL;
