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

--
-- TaC/tac_panel.vhd : TaC Console Panel
--
-- 2019.01.23           : P_RESET の fanout を減らす対策
-- 2019.01.15           : RESETスイッチにもデバウンスを追加
-- 2016.01.10           : 電源投入時 "RUN" 状態から始まるようにする
-- 2016.01.07           : 未使用の出力 P_BUZ を '0' に接続
-- 2013.07.17           : STOPスイッチの誤動作対応
-- 2012.09.26           : TaC-CPU V2 対応完了
-- 2012.01.22           : entity 名、見直し
-- 2011.06.26           : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

entity TAC_PANEL is
  port ( P_CLK0     : in  std_logic;                       -- clock 0'
         P_CLK90    : in  std_logic;                       -- clock 90'
         P_RESET_IN : in  std_logic;                       -- reset signal
         P_1kHz     : in  std_logic;                       -- sampling timing

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
end TAC_PANEL;

architecture RTL of TAC_PANEL is
  -- register
  signal i_addrReg  : std_logic_vector(15 downto 0); -- address register
  signal i_datReg   : std_logic_vector(15 downto 0); -- data register
  signal i_rtryReg  : std_logic_vector( 4 downto 0); -- rotary sw position
  signal i_runFF    : std_logic;                     -- run Flip/Flop
  signal i_writeFF  : std_logic;                     -- write Flip/Flop

  -- sampling timing
  signal i_cnt      : std_logic_vector( 4 downto 0); -- counter
  signal i_delay    : std_logic;                     -- delaied i_cnt[4]
  signal i_smp      : std_logic;                     -- sampling timing

  -- signal
  signal i_func     : std_logic_vector( 3 downto 0); -- console function reg.
  signal i_reset0   : std_logic;                     -- unique reset signal.
  signal i_reset1   : std_logic;                     -- copy(internal).
  signal i_reset2   : std_logic;                     -- copy(external).
  signal i_incaSw   : std_logic;                     -- increment address sw.
  signal i_decaSw   : std_logic;                     -- decrement address sw.
  signal i_setaSw   : std_logic;                     -- set address sw.
  signal i_writeSw  : std_logic;                     -- write data sw.
  signal i_rstSw    : std_logic;                     -- reset sw.
  signal i_runSw    : std_logic;                     -- run program
  signal i_rcwSw    : std_logic;                     -- rotate clock wise
  signal i_rccwSw   : std_logic;                     -- rotate c-clock wise
  signal i_stopSw   : std_logic;                     -- stop sw.
  signal i_leds     : std_logic_vector( 8 downto 0); -- LED
  
  signal i_ladd     : std_logic;                     -- address msb
  
  attribute EQUIVALENT_REGISTER_REMOVAL : string;
  attribute EQUIVALENT_REGISTER_REMOVAL of i_reset1 : signal is "NO";
  attribute EQUIVALENT_REGISTER_REMOVAL of i_reset2 : signal is "NO";
  
  component TRSW
    port ( P_CLK    : in  std_logic;               -- CLK
           P_RESET  : in  std_logic;               -- Reset
           P_S      : in  std_logic;               -- S
           P_SMP    : in  std_logic;               -- Sample(20ms)
           P_RPT    : in  std_logic;               -- Repeate
           P_Q      : out std_logic                -- Q
         );
  end component;

begin  -- RTL
  -- unused
  P_BUZ <= '0';

  -- sw's sampling signal
  process(P_RESET_IN, P_CLK0)
  begin
    if (P_RESET_IN='0') then
      i_cnt   <= "00000";
      i_delay <= '0';
    elsif (P_CLK0'event and P_CLK0='1') then
      if (P_1kHz='1') then
        i_cnt <= i_cnt + 1;
      end if;
      i_delay <= i_cnt(4);
      i_smp   <= i_cnt(4) and not i_delay;         -- edge detection
    end if;
  end process;
    
  -- reset sw
  rstSw   : TRSW port map (P_CLK0, '1', P_RESET_SW, i_smp, '0', i_rstSW  );
  process(P_CLK90)
  begin
    if (P_CLK90'event and P_CLK90='0') then
      i_reset0 <= not (i_rstSW or (not P_RESET_IN));
      i_reset1 <= i_reset0;
      i_reset2 <= i_reset0;
    end if;
  end process;
  P_RESET <= i_reset2;

  -- triggerd sw
  runSw   : TRSW port map (P_CLK0, '1', P_RUN_SW,   i_smp, '0', i_runSw  );
  decaSw  : TRSW port map (P_CLK0, '1', P_DECA_SW,  i_smp, '1', i_decaSw );
  incaSw  : TRSW port map (P_CLK0, '1', P_INCA_SW,  i_smp, '1', i_incaSw );
  setaSw  : TRSW port map (P_CLK0, '1', P_SETA_SW,  i_smp, '0', i_setaSw );
  rcwSw   : TRSW port map (P_CLK0, '1', P_RCW_SW,   i_smp, '1', i_rcwSw  );
  rccwSw  : TRSW port map (P_CLK0, '1', P_RCCW_SW,  i_smp, '1', i_rccwSw );
  writeSw : TRSW port map (P_CLK0, '1', P_WRITE_SW, i_smp, '0', i_writeSw);

  -- rotary sw
  process(P_CLK0)
  begin
    if (P_CLK0'event and P_CLK0='1') then
      if (i_rcwSw='1' and not (i_rtryReg="10001")) then
        i_rtryReg <= i_rtryReg + 1;
      elsif (i_rccwSw='1' and not (i_rtryReg="00000")) then
        i_rtryReg <= i_rtryReg - 1;
      end if;
    end if;
  end process;

  -- (G0,G1,G2,SP,PC,MM) LED decoder (L_DEC)
  P_G0_LED <= i_leds(8);
  P_G1_LED <= i_leds(7);
  P_G2_LED <= i_leds(6);
  P_SP_LED <= i_leds(5);
  P_PC_LED <= i_leds(4);
  P_MM_LED <= i_leds(3);
  P_C_LED  <= i_leds(2);
  P_S_LED  <= i_leds(1);
  P_Z_LED  <= i_leds(0);
  with i_rtryReg select
    i_leds <=
    "100000100" when "00000", -- G0
    "010000100" when "00001", -- G1
    "001000100" when "00010", -- G2
    "000100100" when "00011", -- G3
    "000010100" when "00100", -- G4
    "000001100" when "00101", -- G5
    "100000010" when "00110", -- G6
    "010000010" when "00111", -- G7
    "001000010" when "01000", -- G8
    "000100010" when "01001", -- G9
    "000010010" when "01010", -- G10
    "000001010" when "01011", -- G11
    "100000001" when "01100", -- FP
    "010000001" when "01101", -- SP
    "001000001" when "01110", -- PC
    "000100001" when "01111", -- FLAG
    "000010001" when "10000", -- Memory Data
    "000001001" when others;  -- Memory Address

  -- write Flip Flop
  process(i_reset1, P_CLK0)
  begin
    if (i_reset1='0') then
      i_writeFF <= '0';
    elsif (P_CLK0'event and P_CLK0='1') then
      if (i_writeSw='1') then
        i_writeFF <= '1';
      elsif (P_AIN(7 downto 1)="1111111" and P_IR='1' and P_RW='0') then
        i_writeFF <= '0';               -- i/o read FEH
      end if;
    end if;
  end process;
  
  -- i_func decoder (F_DEC)
  i_func(3 downto 0) <=
    "0000" when (i_rtryReg(4)='0' and i_writeFF='0') else
    "0001" when (i_rtryReg(4)='0' and i_writeFF='1') else
    "1101" when (i_rtryReg(4)='1' and i_rtryReg(0)='0' and i_writeFF='0') else
    "1110" when (i_rtryReg(4)='1' and i_rtryReg(0)='0' and i_writeFF='1') else
    "1111";

  -- Address Register
  process(i_reset1, P_CLK0)
  begin
    if (P_CLK0'event and P_CLK0='1') then
      if (i_setaSw='1') then                            -- 8bit shift
        i_ladd <= P_DATA_SW(0);
        i_addrReg <= i_addrReg(7 downto 1)& i_ladd& P_DATA_SW(7 downto 1)& '0';
      elsif (i_incaSw='1') then
        i_addrReg <= i_addrReg + 2;                     -- increment
      elsif (i_decaSw='1') then
        i_addrReg <= i_addrReg - 2;                     -- decrement
      end if;
    end if;
  end process;

  -- run Flip/Flop
  P_R_LED <= i_runFF;
  P_STOP  <= not i_runFF;
  process(i_reset1, P_CLK0)
  begin
    if (i_reset1='0') then
      i_runFF <= '1';
    elsif (P_CLK0'event and P_CLK0='1') then
      i_stopSw <= P_STOP_SW;                           -- clocked signal
      if (i_stopSw='1' or                              -- console stop sw.
          P_HL='1' or                                  -- halt instruction
          (P_STEP_SW='1' and P_LI='1' and P_MR='1') or -- step
          (P_BREAK_SW='1' and P_AIN=i_addrReg and      -- break
           P_LI='1' and P_MR='1')) then
        i_runFF <= '0';
      elsif (i_runSw='1') then                         -- console run sw.
        i_runFF <= '1';
      end if;
    end if;
  end process;

  -- (address, data) LED
  P_A_LED <= i_datReg(15 downto 8);
  P_D_LED <= i_datReg( 7 downto 0);
  process(i_reset1, P_CLK0)
  begin
    if (i_reset1='0') then
      i_datReg <= "0000000000000000";
    elsif (P_CLK0'event and P_CLK0='1') then
      if (P_AIN(7 downto 0)="11111000" and P_IR='1' and P_RW='1') then
        i_datReg <= P_DIN;
      end if;
    end if;
  end process;

  -- DOUT
  P_DOUT <=
    ("000000000000" & i_func               ) when (P_AIN(2 downto 1)="11") else
    ("000000000000" & i_rtryReg(3 downto 0)) when (P_AIN(2 downto 1)="10") else
    ( i_addrReg                            ) when (P_AIN(2 downto 1)="01") else
    ("00000000" & P_DATA_SW                );  -- (P_AIN(2 downto 1)="00") 
  
end RTL;
    
