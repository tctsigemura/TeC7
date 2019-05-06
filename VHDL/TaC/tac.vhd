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
-- TaC/tac.vhd : TaC Top Level Source Code
--
-- 2019.05.06 : TeC7a 用に新しいブランチ（RN4020 関連削除）
-- 2019.04.13 : TeC7d 用に RN4020_CON 追加，RN4020_SW 削除
-- 2019.02.28 : TAC_RAMにRESETを配線（IPLの複数バンク化）
-- 2019.02.18 : TaC モード以外では SETA+RESET で TaC をリセットするように変更
-- 2019.02.16 : TAC_CPU の P_PR の in/out 間違え訂正
-- 2019.02.09 : マイクロSDカードの挿入を検知できるようにする
-- 2019.02.03 : TeCのコンソールをTaCが操作できるようにする
-- 2019.01.24 : 空きI/Oアドレスのリードは 00H になるように変更
-- 2019.01.22 : MMU を追加
-- 2018.12.31 : CPU が停止中はタイマーも停止するように変更
-- 2018.12.09 : PIO の出力を最大12ビット化
-- 2018.07.13 : モードを3ビットに変更
-- 2018.07.13 : RN4020の受信バッファ（FIFO）追加
-- 2017.05.11 : TeC7b 対応
-- 2016.01.07 : 川部版と統合
-- 2012.09.26 : TaC-CUP V2 対応完了
-- 2012.01.22 : TeC とのインタフェースを削除
-- 2011.09.18 : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity TAC is
  port (
         P_CLK0       : in   std_logic;                      -- 49.1520MHz 0'
         P_CLK90      : in   std_logic;                      -- 49.1520MHz 90'
         P_MODE       : in   std_logic_vector(2 downto 0);   -- 0:TeC,1:TaC
         P_RESET      : in   std_logic;                      --   2,3:DEMO1,2

         -- CONSOLE(INPUT)
         P_DATA_SW   : in    std_logic_vector(7 downto 0);   -- Data  SW
         P_RESET_SW  : in    std_logic;
         P_SETA_SW   : in    std_logic;                      -- SETA  SW
         P_INCA_SW   : in    std_logic;                      -- INCA  SW
         P_DECA_SW   : in    std_logic;                      -- DECA  SW
         P_WRITE_SW  : in    std_logic;                      -- WRITE SW
         P_STEP_SW   : in    std_logic;                      -- STEP  SW
         P_BREAK_SW  : in    std_logic;                      -- BREAK SW
         P_STOP_SW   : in    std_logic;                      -- STOP  SW
         P_RUN_SW    : in    std_logic;                      -- RUN   SW
         P_RCW_SW    : in    std_logic;                      -- Rotate SW(CW)
         P_RCCW_SW   : in    std_logic;                      -- Rotate SW(CCW)

         -- CONSOLE(OUTPUT)
         P_A_LED     : out   std_logic_vector(7 downto 0);   -- Address LED
         P_D_LED     : out   std_logic_vector(7 downto 0);   -- Data LED
         P_R_LED     : out   std_logic;                      -- RUN   LED
         P_C_LED     : out   std_logic;                      -- Carry LED
         P_S_LED     : out   std_logic;                      -- Sing  LED
         P_Z_LED     : out   std_logic;                      -- Zero  LED
         P_G0_LED    : out   std_logic;                      -- G0    LED
         P_G1_LED    : out   std_logic;                      -- G1    LED
         P_G2_LED    : out   std_logic;                      -- G2    LED
         P_SP_LED    : out   std_logic;                      -- SP    LED
         P_PC_LED    : out   std_logic;                      -- PC    LED
         P_MM_LED    : out   std_logic;                      -- MM    LED
         P_BUZ       : out   std_logic;                      -- BUZZER OUT

         -- PIO
         P_ADC_REF  : out  std_logic_vector (7 downto 0);
         P_EXT_OUT  : out  std_logic_vector (11 downto 0);
         P_EXT_MODE : out  std_logic;
         P_EXT_IN   : in  std_logic_vector (7 downto 0);
         
         -- uSD
         P_SPI_SCLK  : out   std_logic;
         P_SPI_DIN   : in    std_logic;
         P_SPI_DOUT  : out   std_logic;
         P_SPI_CS    : out   std_logic;
         P_ACC_LED   : out   std_logic;                      -- access led
         P_SD_CD     : in    std_logic;                      -- card detection
         
         -- TEC
         P_TEC_RXD  : out  std_logic;                        -- to TeC SIO RXD
         P_TEC_TXD  : in   std_logic;                        -- to TeC SIO TXD

         -- FT232RL
         P_FT232RL_RXD : out std_logic;                      -- to FT SIO RXD
         P_FT232RL_TXD : in  std_logic;                      -- to FT SIO TXD

         -- TeC CONSOLE
         P_TEC_DLED : in std_logic_vector(7 downto 0);
         P_TEC_DSW  : out std_logic_vector(7 downto 0);
         P_TEC_FNC  : out std_logic_vector(7 downto 0);
         P_TEC_CTL  : out std_logic_vector(2 downto 0);
         P_TEC_ENA  : out std_logic;
         P_TEC_RESET: in std_logic;
         P_TEC_SETA : in std_logic
       );
end TAC;

architecture Behavioral of TAC is

-- clock and reset
signal i_1kHz           : std_logic;
signal i_cnt16          : std_logic_vector(15 downto 0);
signal i_reset_panel    : std_logic;

-- control bus
signal i_reset          : std_logic;
signal i_stop           : std_logic;
signal i_intr           : std_logic;
signal i_hl             : std_logic;
signal i_vr             : std_logic;
signal i_li             : std_logic;
signal i_mr             : std_logic;
signal i_ir             : std_logic;
signal i_rw             : std_logic;
signal i_bt             : std_logic;
signal i_int_bit        : std_logic_vector(15 downto 0);
signal i_pr             : std_logic;
signal i_cpu_mr         : std_logic;

-- address bus
signal i_addr           : std_logic_vector(15 downto 0);
signal i_cpu_addr       : std_logic_vector(15 downto 0);

-- data bus
signal i_dout_cpu       : std_logic_vector(15 downto 0);
signal i_din_cpu        : std_logic_vector(15 downto 0);
signal i_dout_panel     : std_logic_vector(15 downto 0);
signal i_dout_ram       : std_logic_vector(15 downto 0);
signal i_dout_tmr       : std_logic_vector(15 downto 0);
signal i_dout_intc      : std_logic_vector(15 downto 0);
signal i_dout_spi       : std_logic_vector(15 downto 0);
signal i_dout_sio1      : std_logic_vector( 7 downto 0);  -- FT232RL
signal i_dout_sio2      : std_logic_vector( 7 downto 0);  -- TeC
signal i_dout_pio       : std_logic_vector( 7 downto 0);
signal i_dout_tmr0      : std_logic_vector(15 downto 0);
signal i_dout_tmr1      : std_logic_vector(15 downto 0);
signal i_dout_tec       : std_logic_vector( 7 downto 0);

-- address decoder
signal i_ior            : std_logic;
signal i_iow            : std_logic;
signal i_en_spi         : std_logic;
signal i_en_sio1        : std_logic;    -- FT232RL
signal i_en_sio2        : std_logic;    -- TeC
signal i_en_pio         : std_logic;
signal i_en_tmr0        : std_logic;
signal i_en_tmr1        : std_logic;
signal i_en_tec         : std_logic;
signal i_en_mmu         : std_logic;
signal i_en_ram         : std_logic;

-- bus for DMA
signal i_addr_dma       : std_logic_vector(14 downto 0);
signal i_dout_dma       : std_logic_vector(15 downto 0);
signal i_dout_ram_dma   : std_logic_vector(15 downto 0);
signal i_rw_dma         : std_logic;
signal i_mr_dma         : std_logic;

component TAC_INTC is
  port (
         P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;

         P_DOUT     : out std_logic_vector(15 downto 0);
         P_VR       : in  std_logic;
         P_INTR     : out std_logic;

         P_INT_BIT  : in  std_logic_vector(15 downto 0)
       );
end component;

component TAC_CPU
  port (
         P_CLK0     : in  std_logic;                       -- Clock
         P_CLK90    : in  std_logic;
         P_RESET    : in  std_logic;                       -- Reset

         P_ADDR     : out std_logic_vector(15 downto 0);   -- ADDRESS BUS
         P_DIN      : in  std_logic_vector(15 downto 0);   -- DATA    BUS
         P_DOUT     : out std_logic_vector(15 downto 0);   -- DATA    BUS

         P_RW       : out std_logic;                       -- Read/Write
         P_IR       : out std_logic;                       -- I/O Req.
         P_MR       : out std_logic;                       -- Memory Req.
         P_LI       : out std_logic;                       -- Instruction Fetch
         P_VR       : out std_logic;                       -- Vector Req.
         P_HL       : out std_logic;                       -- Halt instruction
         P_BT       : out std_logic;                       -- Byte To
         P_PR       : out std_logic;                       -- Privilege Mode
         P_INTR     : in  std_logic;                       -- Intrrupt
         P_STOP     : in  std_logic                        -- Bus Request
       );
end component;

component TAC_PANEL
  port (
         P_CLK0     : in  std_logic;
         P_CLK90    : in  std_logic;
         P_RESET_IN : in  std_logic;
         P_1kHz     : in  std_logic;

         -- CPU BUS
         P_AIN      : in  std_logic_vector(15 downto 0);   -- address bus
         P_DIN      : in  std_logic_vector(15 downto 0);   -- data in
         P_DOUT     : out std_logic_vector(15 downto 0);   -- data out
         P_RW       : in  std_logic;                       -- read/write
         P_IR       : in  std_logic;                       -- i/o req.
         P_MR       : in  std_logic;                       -- memory req.
         P_LI       : in  std_logic;                       -- load instruction
         P_HL       : in  std_logic;                       -- halt instruction
         P_STOP     : out std_logic;                       -- stop the cpu
         P_RESET    : out std_logic;                       -- reset [OUTPUT]

         -- console switchs(inputs)
         P_DATA_SW  : in std_logic_vector(7 downto 0);     -- data sw.
         P_RESET_SW : in std_logic;                        -- reset sw.
         P_SETA_SW  : in std_logic;                        -- set address sw.
         P_INCA_SW  : in std_logic;                        -- increment addr sw.
         P_DECA_SW  : in std_logic;                        -- decrement addr sw.
         P_WRITE_SW : in std_logic;                        -- write data sw
         P_STEP_SW  : in std_logic;                        -- step exe.mode sw.
         P_BREAK_SW : in std_logic;                        -- break exe.mode sw.
         P_STOP_SW  : in std_logic;                        -- stop program
         P_RUN_SW   : in std_logic;                        -- run program
         P_RCW_SW   : in std_logic;                        -- rotate clock wise
         P_RCCW_SW  : in std_logic;                        -- rotate

         -- cosole leds(outputs)
         P_A_LED    : out std_logic_vector(7 downto 0);    -- address LED
         P_D_LED    : out std_logic_vector(7 downto 0);    -- data LED
         P_R_LED    : out std_logic;                       -- run CPU
         P_C_LED    : out std_logic;                       -- Carry LED
         P_S_LED    : out std_logic;                       -- Sing  LED
         P_Z_LED    : out std_logic;                       -- Zero  LED
         P_G0_LED   : out std_logic;                       -- G0 LED
         P_G1_LED   : out std_logic;                       -- G1 LED
         P_G2_LED   : out std_logic;                       -- G2 LED
         P_SP_LED   : out std_logic;                       -- SP LED
         P_PC_LED   : out std_logic;                       -- PC LED
         P_MM_LED   : out std_logic;                       -- MM LED
         P_BUZ      : out std_logic                        -- Buzzer
       );
end component;

component TAC_RAM
  port (
         P_CLK    : in  std_logic;
         P_RESET  : in  std_logic;
         P_IOE    : in  std_logic;                         -- I/O Enable
         P_IOW    : in  std_logic;                         -- I/O Write
         -- for CPU
         P_AIN1   : in  std_logic_vector(15 downto 0);
         P_DIN1   : in  std_logic_vector(15 downto 0);
         P_DOUT1  : out std_logic_vector(15 downto 0);
         P_RW1    : in  std_logic;
         P_MR1    : in  std_logic;
         P_BT     : in  std_logic;
         -- for DMA
         P_AIN2   : in  std_logic_vector(14 downto 0);
         P_DIN2   : in  std_logic_vector(15 downto 0);
         P_DOUT2  : out std_logic_vector(15 downto 0);
         P_RW2    : in  std_logic;
         P_MR2    : in  std_logic
  );
end component;

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
         P_RxD     : in  std_logic                       -- シリアル入力
       );
end component;

component TAC_SPI
  Port ( P_CLK     : in  STD_LOGIC;
         P_RESET   : in  STD_LOGIC;
         P_EN      : in  STD_LOGIC;
         P_IOR     : in  STD_LOGIC;
         P_IOW     : in  STD_LOGIC;
         P_INT     : out std_logic;
         P_ADDR : in  std_logic_vector (1 downto 0);
         P_DIN : in  std_logic_vector (15 downto 0);
         P_DOUT : out  std_logic_vector (15 downto 0);
         
         P_ADDR_DMA : out  std_logic_vector (14 downto 0);
         P_DIN_DMA  : in  std_logic_vector (15 downto 0);
         P_DOUT_DMA : out std_logic_vector (15 downto 0);
         P_RW_DMA   : out std_logic;
         P_MR_DMA   : out std_logic;
         
         P_SCLK     : out STD_LOGIC;
         P_DI       : in  STD_LOGIC;
         P_DO       : out STD_LOGIC;
         P_CS       : out STD_LOGIC;
         P_ACC      : out STD_LOGIC;
         P_CD       : in  STD_LOGIC
       );
end component;

component TAC_PIO
    Port ( P_CLK     : in  STD_LOGIC;
           P_RESET   : in  STD_LOGIC;
           P_EN      : in  STD_LOGIC;
           P_IOR     : in  STD_LOGIC;
           P_IOW     : in  STD_LOGIC;
           P_INT     : out  STD_LOGIC;
           P_ADDR    : in  STD_LOGIC_VECTOR (1 downto 0);
           P_DIN     : in  STD_LOGIC_VECTOR (7 downto 0);
           P_DOUT    : out  STD_LOGIC_VECTOR (7 downto 0);
              
           P_ADC_REF : out  STD_LOGIC_VECTOR(7 downto 0);
           P_EXT_IN  : in   STD_LOGIC_VECTOR(7 downto 0);
           P_EXT_OUT : out  STD_LOGIC_VECTOR(11 downto 0);
           P_EXT_MODE: out  STD_LOGIC;
           P_MODE    : in   STD_LOGIC_VECTOR(2 downto 0)
         );
end component;

component TAC_TIMER is
    Port ( P_CLK     : in  std_logic;
           P_RESET   : in  std_logic;
           P_EN      : in  std_logic;
           P_IOR     : in  std_logic;
           P_IOW     : in  std_logic;
           P_INT     : out std_logic;
           P_ADDR    : in  std_logic;
           P_1kHz    : in  std_logic;
           P_DIN     : in  std_logic_vector (15 downto 0);
           P_DOUT    : out std_logic_vector (15 downto 0);
           P_STOP    : in  std_logic
         );
end component;

component TAC_MMU is 
  Port ( P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_EN       : in  std_logic;
         P_IOW      : in  std_logic;
         P_MMU_MR   : in  std_logic;
         P_PR       : in  std_logic;                     -- Privilege mode
         P_INT      : out std_logic;
         P_MR       : out std_logic;
         P_ADDR     : out std_logic_vector(15 downto 0); -- Physical address
         P_MMU_ADDR : in  std_logic_vector(15 downto 0); -- Virtual address
         P_DIN      : in  std_logic_vector(15 downto 0)
       );
end component;

component TAC_TEC is 
  Port ( P_CLK      : in  std_logic;
         P_RESET    : in  std_logic;
         P_EN       : in  std_logic;
         P_IOR      : in  std_logic;
         P_IOW      : in  std_logic;
         P_ADDR     : in  std_logic_vector (1 downto 0);
         P_DIN      : in  std_logic_vector (7 downto 0);
         P_DOUT     : out std_logic_vector (7 downto 0);

         P_TEC_DLED : in std_logic_vector(7 downto 0);
         P_TEC_DSW  : out std_logic_vector(7 downto 0);
         P_TEC_FNC  : out std_logic_vector(7 downto 0);
         P_TEC_CTL  : out std_logic_vector(2 downto 0);
         P_TEC_ENA  : out std_logic;
         P_TEC_RESET: in std_logic;
         P_TEC_SETA : in std_logic
       );
end component;

begin
  -- アドレス違反用(将来実装)
  i_int_bit(10) <= '0';

  -- マイクロプログラムが発生する例外が 12 ～ 15 を使用
  i_int_bit(12) <= '0';
  i_int_bit(13) <= '0';
  i_int_bit(14) <= '0';
  i_int_bit(15) <= '0';

  -- TaCモード以外では RESET+SETA でTaCをリセットできる
  i_reset_panel <= P_RESET_SW when (P_MODE=1) else P_TEC_RESET and P_TEC_SETA;
   
  -- CNT16 (1kHz のパルスを発生する)
  i_1kHz <= '1' when (i_cnt16=49151) else '0';

  process(P_CLK0, P_RESET)
    begin
      if (P_RESET='0') then
        i_cnt16 <= "0000000000000000";
      elsif (P_CLK0'event and P_CLK0='1') then
        if (i_1kHz='1') then
          i_cnt16 <= "0000000000000000";
        else
          i_cnt16 <= i_cnt16 + 1;
        end if;
      end if;
    end process;
  
  -- Interrupt controller
  TAC_INTC1 : TAC_INTC
    port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,

         P_DOUT     => i_dout_intc,
         P_VR       => i_vr,
         P_INTR     => i_intr,
         P_INT_BIT  => i_int_bit
      );

  -- TaC CPU
  TAC_CPU1 : TAC_CPU
  port map (
         P_CLK0     => P_CLK0,
         P_CLK90    => P_CLK90,
         P_RESET    => i_reset,

         P_ADDR     => i_cpu_addr,
         P_DIN      => i_din_cpu,
         P_DOUT     => i_dout_cpu,

         P_RW       => i_rw,
         P_IR       => i_ir,
         P_MR       => i_cpu_mr,
         P_LI       => i_li,
         P_VR       => i_vr,
         P_HL       => i_hl,
         P_BT       => i_bt,
         P_PR       => i_pr,
         P_INTR     => i_intr,
         P_STOP     => i_stop
  );
  
  i_iow       <= i_ir and i_rw and (not i_li);
  i_ior       <= i_ir and (not i_rw) and (not i_li);
  i_en_tmr0   <= '1' when (i_addr(7 downto 2)="000000") else '0'; -- 00~03
  i_en_tmr1   <= '1' when (i_addr(7 downto 2)="000001") else '0'; -- 04~07
  i_en_sio1   <= '1' when (i_addr(7 downto 2)="000010") else '0'; -- 08~0b
  i_en_sio2   <= '1' when (i_addr(7 downto 2)="000011") else '0'; -- 0c~0f
  i_en_spi    <= '1' when (i_addr(7 downto 3)="00010")  else '0'; -- 10~17
  i_en_pio    <= '1' when (i_addr(7 downto 3)="00011")  else '0'; -- 18~1f
--i_en_rn     <= '1' when (i_addr(7 downto 3)="00101")  else '0'; -- 28~2f
  i_en_tec    <= '1' when (i_addr(7 downto 3)="00110")  else '0'; -- 30~37
  i_en_ram    <= '1' when (i_addr(7 downto 1)="1111000")else '0'; -- f0~f1
  i_en_mmu    <= '1' when (i_addr(7 downto 3)="11110" and
                      (i_addr(2)='1' or i_addr(1)='1')) else '0'; -- f2~f7
 
  i_din_cpu <= i_dout_ram   when (i_mr='1') else
               i_dout_panel when (i_ir='1' and i_addr(7 downto 3)="11111") else
               i_dout_tmr0  when (i_ir='1' and i_en_tmr0='1') else
               i_dout_tmr1  when (i_ir='1' and i_en_tmr1='1') else
               ("00000000"&i_dout_sio1) when (i_ir='1' and i_en_sio1='1') else
               ("00000000"&i_dout_sio2) when (i_ir='1' and i_en_sio2='1') else
               i_dout_spi when (i_ir='1' and i_en_spi='1') else
               ("00000000"&i_dout_pio) when (i_ir='1' and i_en_pio='1') else
--             ("00000000"&i_dout_rn) when (i_ir='1' and i_en_rn='1') else
               ("00000000"&i_dout_tec) when (i_ir='1' and i_en_tec='1') else
               i_dout_intc when (i_vr='1') else
               "0000000000000000";

  -- TaC PANEL
  TAC_PANEL1 : TAC_PANEL
  port map (
         P_CLK0     => P_CLK0,
         P_CLK90    => P_CLK90,
         P_RESET_IN => P_RESET,
         P_1kHz     => i_1kHz,

         -- CPU BUS
         P_AIN      => i_addr,
         P_DIN      => i_dout_cpu,
         P_DOUT     => i_dout_panel,
         P_RW       => i_rw,
         P_IR       => i_ir,
         P_MR       => i_mr,
         P_LI       => i_li,
         P_HL       => i_hl,
         P_STOP     => i_stop,
         P_RESET    => i_reset,

         -- console switchs(inputs)
         P_DATA_SW  => P_DATA_SW,
         P_RESET_SW => i_reset_panel,
         P_SETA_SW  => P_SETA_SW,
         P_INCA_SW  => P_INCA_SW,
         P_DECA_SW  => P_DECA_SW,
         P_WRITE_SW => P_WRITE_SW,
         P_STEP_SW  => P_STEP_SW,
         P_BREAK_SW => P_BREAK_SW,
         P_STOP_SW  => P_STOP_SW,
         P_RUN_SW   => P_RUN_SW,
         P_RCW_SW   => P_RCW_SW,
         P_RCCW_SW  => P_RCCW_SW,

         -- cosole leds(outputs)
         P_A_LED    => P_A_LED,
         P_D_LED    => P_D_LED,
         P_R_LED    => P_R_LED,
         P_C_LED    => P_C_LED,
         P_S_LED    => P_S_LED,
         P_Z_LED    => P_Z_LED,
         P_G0_LED   => P_G0_LED,
         P_G1_LED   => P_G1_LED,
         P_G2_LED   => P_G2_LED,
         P_SP_LED   => P_SP_LED,
         P_PC_LED   => P_PC_LED,
         P_MM_LED   => P_MM_LED,
         P_BUZ      => P_BUZ
  );

  TAC_MMU1: TAC_MMU
  port map (
         P_CLK         => P_CLK0,
         P_RESET       => i_reset,
         P_EN          => i_en_mmu,
         P_IOW         => i_iow,
         P_MMU_MR      => i_cpu_mr,
         P_PR          => i_pr,
         P_INT         => i_int_bit(11),
         P_MR          => i_mr,
         P_ADDR        => i_addr,
         P_MMU_ADDR    => i_cpu_addr, 
         P_DIN         => i_dout_cpu
  );

  -- RAM
  TAC_RAM1 : TAC_RAM
  port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,
         P_IOE      => i_en_ram,
         P_IOW      => i_iow,
         P_AIN1     => i_addr,
         P_DIN1     => i_dout_cpu,
         P_DOUT1    => i_dout_ram,
         P_RW1      => i_rw,
         P_MR1      => i_mr,
         P_BT       => i_bt,
         P_AIN2     => i_addr_dma,
         P_DIN2     => i_dout_dma,
         P_DOUT2    => i_dout_ram_dma,
         P_RW2      => i_rw_dma,
         P_MR2      => i_mr_dma
  );

  -- I/O
  TAC_SIO1 : TAC_SIO                    -- FT232RL
  port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,
         P_IOW      => i_iow,
         P_IOR      => i_ior,
         P_EN       => i_en_sio1,
         P_ADDR     => i_addr(1),
         P_DOUT     => i_dout_sio1,
         P_DIN      => i_dout_cpu(7 downto 0),
         P_INT_TxD  => i_int_bit(5),
         P_INT_RxD  => i_int_bit(4),
         P_TxD      => P_FT232RL_RXD,
         P_RxD      => P_FT232RL_TXD
       );

  TAC_SIO2 : TAC_SIO                    -- TeC
  port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,
         P_IOW      => i_iow,
         P_IOR      => i_ior,
         P_EN       => i_en_sio2,
         P_ADDR     => i_addr(1),
         P_DOUT     => i_dout_sio2,
         P_DIN      => i_dout_cpu(7 downto 0),
         P_INT_TxD  => i_int_bit(7),
         P_INT_RxD  => i_int_bit(6),
         P_TxD      => P_TEC_RXD,
         P_RxD      => P_TEC_TXD
       );

  TAC_SPI1 : TAC_SPI
  port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,
         P_EN       => i_en_spi,
         P_IOR      => i_ior,
         P_IOW      => i_iow,
         P_INT      => i_int_bit(8),
         P_ADDR     => i_addr(2 downto 1),
         P_DIN      => i_dout_cpu(15 downto 0),
         P_DOUT     => i_dout_spi,
         
         P_ADDR_DMA => i_addr_dma,
         P_DIN_DMA  => i_dout_ram_dma,
         P_DOUT_DMA => i_dout_dma,
         P_RW_DMA   => i_rw_dma,
         P_MR_DMA   => i_mr_dma,
         
         P_SCLK     => P_SPI_SCLK,
         P_DI       => P_SPI_DIN,
         P_DO       => P_SPI_DOUT,
         P_CS       => P_SPI_CS,
         P_ACC      => P_ACC_LED,
         P_CD       => P_SD_CD
       );

  TAC_PIO1 : TAC_PIO
  port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,
         P_EN       => i_en_pio,
         P_IOR      => i_ior,
         P_IOW      => i_iow,
         P_INT      => i_int_bit(9),
         P_ADDR     => i_addr(2 downto 1),
         P_DIN      => i_dout_cpu(7 downto 0),
         P_DOUT     => i_dout_pio,

         P_ADC_REF  => P_ADC_REF,
         P_EXT_IN   => P_EXT_IN,
         P_EXT_OUT  => P_EXT_OUT,
         P_EXT_MODE => P_EXT_MODE,
         P_MODE     => P_MODE
        );

  TAC_TIMER0: TAC_TIMER
  port map (
      P_CLK         => P_CLK0,
      P_RESET       => i_reset,
      P_EN          => i_en_tmr0,
      P_IOR         => i_ior,
      P_IOW         => i_iow,
      P_INT         => i_int_bit(0),
      P_ADDR        => i_addr(1),
      P_1kHz        => i_1kHz,
      P_DIN         => i_dout_cpu,
      P_DOUT        => i_dout_tmr0,
      P_STOP        => i_stop
    );

  TAC_TIMER1: TAC_TIMER
  port map (
      P_CLK         => P_CLK0,
      P_RESET       => i_reset,
      P_EN          => i_en_tmr1,
      P_IOR         => i_ior,
      P_IOW         => i_iow,
      P_INT         => i_int_bit(1),
      P_ADDR        => i_addr(1),
      P_1kHz        => i_1kHz,
      P_DIN         => i_dout_cpu,
      P_DOUT        => i_dout_tmr1,
      P_STOP        => i_stop
    );

  TAC_TEC1: TAC_TEC
  port map (
      P_CLK         => P_CLK0,
      P_RESET       => i_reset,
      P_EN          => i_en_tec,
      P_IOR         => i_ior,
      P_IOW         => i_iow,
      P_ADDR        => i_addr(2 downto 1),
      P_DIN         => i_dout_cpu(7 downto 0),
      P_DOUT        => i_dout_tec,

      P_TEC_DLED    => P_TEC_DLED,
      P_TEC_DSW     => P_TEC_DSW,
      P_TEC_FNC     => P_TEC_FNC,
      P_TEC_CTL     => P_TEC_CTL,
      P_TEC_ENA     => P_TEC_ENA,
      P_TEC_RESET   => P_TEC_RESET,
      P_TEC_SETA    => P_TEC_SETA
    );
	 
end Behavioral;
