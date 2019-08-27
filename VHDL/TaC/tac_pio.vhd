--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2012-2019 by
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
-- TaC/tac_pio.vhd : TaC PIO
--
-- 2019.08.27 : PIO からの割込み機能追加
-- 2019.08.22 : SPI 機能を追加
-- 2019.08.19 : ADC_REF の初期値を 0x00 から 0x80 に変更（適切な閾値）
-- 2019.07.30 : P_IOR に関する警告を消す
-- 2018.12.09 : PIOの出力を最大 12 ビット化
-- 2018.07.13 : モードを3ビットに変更
-- 2012.01.10 : 新規作成
--
--

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;

entity TAC_PIO is
    Port ( P_CLK      : in  std_logic;
           P_RESET    : in  std_logic;
           P_EN       : in  std_logic;
--         P_IOR      : in  std_logic;
           P_IOW      : in  std_logic;
           P_INT      : out  std_logic;
           P_ADDR     : in  std_logic_vector (2 downto 0);
           P_DIN      : in  std_logic_vector (7 downto 0);
           P_DOUT     : out  std_logic_vector (7 downto 0);

           P_ADC_REF  : out  std_logic_vector(7 downto 0);
           P_EXT_IN   : in   std_logic_vector(7 downto 0);
           P_EXT_OUT  : out  std_logic_vector(11 downto 0);
           P_EXT_MODE : out  std_logic;
           P_MODE     : in   std_logic_vector(2 downto 0)
         );
end TAC_PIO;

architecture Behavioral of TAC_PIO is
  signal i_ext_out    : std_logic_vector(11 downto 0);
  signal i_ext_mode   : std_logic;
  signal i_adc        : std_logic_vector(7 downto 0);

  signal int_msk      : std_logic_vector(7 downto 0);  -- 割込みマスク
  signal int_xor      : std_logic_vector(7 downto 0);  -- 割込みの極性

  signal spi_cnt8     : std_logic_vector(7 downto 0);  -- 分周用カウンタ
  signal spi_reg8     : std_logic_vector(7 downto 0);  -- コンペア用レジスタ
  signal spi_match    : std_logic;                     -- コンペアマッチ
  signal spi_sreg     : std_logic_vector(7 downto 0);  -- シフトレジスタ
  signal spi_cnt3     : std_logic_vector(2 downto 0);  -- 8ビットカウント用
  signal spi_run      : std_logic;                     -- 動作中
  signal spi_ld       : std_logic;                     -- sreg の LD 信号
  signal spi_sclk     : std_logic;                     -- クロック出力
  signal spi_so       : std_logic;                     -- シリアル出力

begin
  -- PIO 関係
  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        i_ext_mode <= '0';
        i_ext_out <= "000000000000";
        i_adc <= "10000000";
        int_msk <= "00000000";
        int_xor <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (P_EN='1' and P_IOW='1') then
          if (P_ADDR="100") then                       -- 18h
            i_ext_out(7 downto 0) <= P_DIN;
          elsif (P_ADDR="101") then
            i_adc <= P_DIN;                            -- 1Ah
          elsif (P_ADDR="110") then
            i_ext_mode <= P_DIN(7);                    -- 1Ch
            i_ext_out(11 downto 8) <= P_DIN(3 downto 0);
          elsif (P_ADDR="010") then
            int_msk <= P_DIN;                          -- 24h
          elsif (P_ADDR="011") then
            int_xor <= P_DIN;                          -- 26h
          end if;
        end if;
      end if;
    end process;

  -- SPI 関係
  spi_match <= '1' when spi_cnt8=spi_reg8 else '0';
  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        spi_cnt8 <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (spi_run='0' or spi_match='1') then
          spi_cnt8 <= "00000000";
        else
          spi_cnt8 <= spi_cnt8 + 1;
        end if;
      end if;
    end process;

  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        spi_sclk <= '0';
      elsif (P_CLK'event and P_CLK='1') then
        if (spi_ld='1') then
          spi_sclk <= '0';
        elsif (spi_run='1' and spi_match='1') then
          spi_sclk <= not spi_sclk;
        end if;
      end if;
    end process;

  spi_ld <= P_EN and P_IOW when P_ADDR="000" else  '0';          -- 20h write
  spi_so <= spi_sreg(7) and spi_run;
  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        spi_run <= '0';
        spi_sreg <= "00000000";
        spi_cnt3 <= "000";
      elsif (P_CLK'event and P_CLK='1') then
        if (spi_ld='1') then
          spi_run <= '1';
          spi_sreg <= P_DIN;
          spi_cnt3 <= "111";
        elsif (spi_match='1' and spi_sclk='1') then
          if (spi_cnt3="000") then
            spi_run <= '0';
          else
            spi_cnt3 <= spi_cnt3 - 1;
          end if;
          spi_sreg(7 downto 1) <= spi_sreg(6 downto 0);
          spi_sreg(0) <= P_EXT_IN(6);
        end if;
      end if;
    end process;

  process(P_RESET, P_CLK)
    begin
      if (P_RESET='0') then
        spi_reg8 <= "00000000";
      elsif (P_CLK'event and P_CLK='1') then
        if (P_EN='1' and P_IOW='1' and P_ADDR="001") then        -- 22h write
          spi_reg8 <= P_DIN;
        end if;
      end if;
    end process;

  P_DOUT <= (P_EXT_IN)            when (P_ADDR(2 downto 0)="100") else -- 18h
            ("00000" & P_MODE)    when (P_ADDR(2 downto 0)="111") else -- 1Eh
            (spi_sreg)            when (P_ADDR(2 downto 0)="000") else -- 20h
            ("0000000" & spi_run);                                     -- 22h

  P_ADC_REF <= i_adc;
  P_EXT_OUT(11 downto 2) <= i_ext_out(11 downto 2);
  P_EXT_OUT(1) <= i_ext_out(1) xor spi_sclk;
  P_EXT_OUT(0) <= i_ext_out(0) xor spi_so;
  P_EXT_MODE <= i_ext_mode;
  P_INT <= '1' when ((P_EXT_IN xor int_xor) and int_msk)/= "00000000" else '0';
end Behavioral;
