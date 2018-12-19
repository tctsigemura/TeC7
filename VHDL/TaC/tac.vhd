--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2011-2017 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   ��L���쌠�҂́CFree Software Foundation �ɂ���Č��J����Ă��� GNU ��ʌ�
-- �O���p�����_�񏑃o�[�W�����Q�ɋL�q����Ă�������𖞂����ꍇ�Ɍ���C�{�\�[�X
-- �R�[�h(�{�\�[�X�R�[�h�����ς������̂��܂ށD�ȉ����l)���g�p�E�����E���ρE�Ĕz
-- �z���邱�Ƃ𖳏��ŋ�������D
--
--   �{�\�[�X�R�[�h�́��S���̖��ۏ؁��Œ񋟂������̂ł���B��L���쌠�҂����
-- �֘A�@�ցE�l�͖{�\�[�X�R�[�h�Ɋւ��āC���̓K�p�\������߂āC�����Ȃ�ۏ�
-- ���s��Ȃ��D�܂��C�{�\�[�X�R�[�h�̗��p�ɂ�蒼�ړI�܂��͊ԐړI�ɐ�����������
-- �鑹�Q�Ɋւ��Ă��C���̐ӔC�𕉂�Ȃ��D
--
--

--
-- TaC/tac.vhd : TaC Top Level Source Code
--
-- 2018.07.13           : ���[�h��3�r�b�g�ɕύX
-- 2018.07.13           : RN4020�̎�M�o�b�t�@�iFIFO�j�ǉ�
-- 2017.05.11           : TeC7b �Ή�
-- 2016.01.07           : �암�łƓ���
-- 2012.09.26           : TaC-CUP V2 �Ή�����
-- 2012.01.22           : TeC �Ƃ̃C���^�t�F�[�X���폜
-- 2011.09.18           : �V�K�쐬
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
         P_EXT_OUT  : out  std_logic_vector (7 downto 0);
         P_EXT_IN   : in  std_logic_vector (7 downto 0);
         
         -- uSD
         P_SPI_SCLK  : out   std_logic;
         P_SPI_DIN   : in    std_logic;
         P_SPI_DOUT  : out   std_logic;
         P_SPI_CS    : out   std_logic;
         P_ACC_LED   : out   std_logic;                      -- access led
         
         -- TEC
         P_TEC_RXD  : out  std_logic;                        -- to TeC SIO RXD
         P_TEC_TXD  : in   std_logic;                        -- to TeC SIO TXD

         -- FT232RL
         P_FT232RL_RXD : out std_logic;                      -- to FT SIO RXD
         P_FT232RL_TXD : in  std_logic;                      -- to FT SIO TXD

         -- RN4020
         P_RN4020_RTS : in std_logic;
         P_RN4020_HW  : out std_logic;
         P_RN4020_CTS : out std_logic;
         P_RN4020_CMD : out std_logic;
         P_RN4020_SW  : out std_logic;
         P_RN4020_RX  : out std_logic;
         P_RN4020_TX  : in std_logic
       );
end TAC;

architecture Behavioral of TAC is

-- clock and reset
signal i_1kHz           : std_logic;

-- cnt16
signal i_cnt16          : std_logic_vector(15 downto 0);

-- control bus
signal i_reset          : std_logic;
signal i_stop           : std_logic;
signal i_intr           : std_logic;
signal i_hl             : std_logic;
signal i_vr             : std_logic;
signal i_li             : std_logic;
signal i_mr             : std_logic;                      -- MMU����o�͂��ꂽMR
signal i_ir             : std_logic;
signal i_rw             : std_logic;
signal i_bt             : std_logic;
signal i_int_bit        : std_logic_vector(15 downto 0);
signal i_pr             : std_logic;                      -- privilege Mode
signal i_cpu_mr         : std_logic;                      -- MMU�֓��͂����MR

-- address bus
signal i_addr           : std_logic_vector(15 downto 0);  -- MMU�̏o��
signal i_cpu_addr       : std_logic_vector(15 downto 0);  -- MMU�ւ̓���

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
signal i_dout_rn        : std_logic_vector( 7 downto 0);  -- RN4020
signal i_dout_pio       : std_logic_vector( 7 downto 0);
signal i_dout_tmr0      : std_logic_vector(15 downto 0);
signal i_dout_tmr1      : std_logic_vector(15 downto 0);

-- address decoder
signal i_ior            : std_logic;
signal i_iow            : std_logic;
signal i_en_spi         : std_logic;
signal i_en_sio1        : std_logic;    -- FT232RL
signal i_en_sio2        : std_logic;    -- TeC
signal i_en_rn          : std_logic;    -- RN4020
signal i_en_pio         : std_logic;
signal i_en_tmr0        : std_logic;
signal i_en_tmr1        : std_logic;
signal i_en_mmu         : std_logic;    -- MMU

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
			P_PR       : out std_logic;                       -- privilege Mode
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
         P_CLK   : in  std_logic;
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
         P_INT_TxD : out std_logic;                      -- SIO ���M���荞��
         P_INT_RxD : out std_logic;                      -- SIO ��M���荞��

         P_TxD     : out std_logic;                      -- �V���A���o��
         P_RxD     : in  std_logic                       -- �V���A������
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
         P_ACC      : out STD_LOGIC
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
           P_EXT_OUT : out  STD_LOGIC_VECTOR(7 downto 0);
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
           P_DOUT    : out std_logic_vector (15 downto 0)
         );
end component;

component TAC_RN4020 is
  port ( P_CLK     : in  std_logic;                      -- 49.1520MHz
         P_RESET   : in  std_logic;                      -- Reset
         P_IOW     : in  std_logic;                      -- I/O Write
         P_IOR     : in  std_logic;                      -- I/O Read
         P_EN      : in  std_logic;                      -- Enable
         P_ADDR    : in  std_logic_vector(1 downto 0);   -- Address(2 downto 1)
         P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
         P_DIN     : in  std_logic_vector(7 downto 0);   -- Data Input
         P_INT_TxD : out std_logic;                      -- ���M���荞��
         P_INT_RxD : out std_logic;                      -- ��M���荞��

         P_TxD     : out std_logic;                      -- �V���A���o��
         P_RxD     : in  std_logic;                      -- �V���A������
         P_CTS     : in  std_logic;                      -- Clear To Send
         P_RTS     : out std_logic;                      -- Request To Send

         P_SW      : out std_logic;                      -- RN4020_SW
         P_CMD     : out std_logic;                      -- RN4020_CMD/MLDP
         P_HW      : out std_logic                       -- RN4020_HW
       );
end component;

component TAC_MMU is
  Port ( P_CLK      : in  STD_LOGIC;
         P_RESET    : in  STD_LOGIC;
         P_EN       : in  STD_LOGIC;
         P_IOW      : in  STD_LOGIC;
         P_MMU_MR   : in  STD_LOGIC;
         P_PR       : in  STD_LOGIC;                        -- Execution mode (0:user, 1:privilege)
         P_INT      : out  STD_LOGIC;
         P_MR       : out  STD_LOGIC;
         P_ADDR     : out  STD_LOGIC_VECTOR(15 downto 0);   -- Physical address
         P_MMU_ADDR : in  STD_LOGIC_VECTOR(15 downto 0);    -- Virtual address, P_MMU_ADDR(1):I/O address
         P_DIN      : in  STD_LOGIC_VECTOR (15 downto 0)    -- B,L register (input)
       );
end component;

begin
  -- �A�h���X�ᔽ�p(��������)
  i_int_bit(10) <= '0';
  --i_int_bit(11) <= '0';

  -- �}�C�N���v���O���������������O�� 12 �` 15 ���g�p
  i_int_bit(12) <= '0';
  i_int_bit(13) <= '0';
  i_int_bit(14) <= '0';
  i_int_bit(15) <= '0';
  
  -- CNT16 (1kHz �̃p���X�𔭐�����)
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
  i_en_rn     <= '1' when (i_addr(7 downto 3)="00101")  else '0'; -- 28~2f
  i_en_mmu    <= '1' when (i_addr(7 downto 3)="11110")  else '0'; -- f0~f7
 
  i_din_cpu <= i_dout_ram   when (i_mr='1') else
               i_dout_panel when (i_ir='1' and i_addr(7 downto 3)="11111") else
               i_dout_tmr0  when (i_ir='1' and i_en_tmr0='1') else
               i_dout_tmr1  when (i_ir='1' and i_en_tmr1='1') else
               ("00000000"&i_dout_sio1) when (i_ir='1' and i_en_sio1='1') else
               ("00000000"&i_dout_sio2) when (i_ir='1' and i_en_sio2='1') else
               i_dout_spi when (i_ir='1' and i_en_spi='1') else
               ("00000000"&i_dout_pio) when (i_ir='1' and i_en_pio='1') else
               ("00000000"&i_dout_rn) when (i_ir='1' and i_en_rn='1') else
               i_dout_intc;

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
         P_RESET_SW => P_RESET_SW,
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

  -- RAM
  TAC_RAM1 : TAC_RAM
  port map (
         P_CLK      => P_CLK0,
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

  TAC_RN1 : TAC_RN4020                    -- TeC
  port map (
         P_CLK      => P_CLK0,
         P_RESET    => i_reset,
         P_IOW      => i_iow,
         P_IOR      => i_ior,
         P_EN       => i_en_rn,
         P_ADDR     => i_addr(2 downto 1),
         P_DOUT     => i_dout_rn,
         P_DIN      => i_dout_cpu(7 downto 0),
         P_INT_TxD  => i_int_bit(3),
         P_INT_RxD  => i_int_bit(2),
         P_TxD      => P_RN4020_RX,
         P_RxD      => P_RN4020_TX,
         P_CTS      => P_RN4020_RTS,
         P_RTS      => P_RN4020_CTS,
         P_SW       => P_RN4020_SW,
         P_CMD      => P_RN4020_CMD,
         P_HW       => P_RN4020_HW
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
         P_ACC      => P_ACC_LED
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
      P_DOUT        => i_dout_tmr0
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
      P_DOUT        => i_dout_tmr1
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

end Behavioral;
