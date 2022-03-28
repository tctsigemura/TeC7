--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2022 by
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
-- 2022.03.28 : SETA, INCA, DECAをMD, MM以外を選択時も操作可能にする
-- 2021.11.19 : TaC-CPU V3 対応
-- 2019.08.30 : 命令フェッチだけでなくデータのアクセスでもBREAKする
-- 2019.08.30 : MA 選択時も WRITE ができるように変更
-- 2019.08.05 : パワーオン時に「プ」音を鳴らすために，起動後にリセットし直す
-- 2019.07.31 : CLK90 を削除，TRSW の使用中止
-- 2019.01.29 : MPCの変化タイミングを5ns早く(MROMが間に合わないので）
-- 2019.01.15 : RESETスイッチにもデバウンスを追加
-- 2016.01.10 : 電源投入時 "RUN" 状態から始まるようにする
-- 2016.01.07 : 未使用の出力 P_BUZ を '0' に接続
-- 2013.07.17 : STOPスイッチの誤動作対応
-- 2012.09.26 : TaC-CPU V2 対応完了
-- 2012.01.22 : entity 名、見直し
-- 2011.06.26 : 新規作成
--
-- $Id
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity TAC_PANEL is
  port ( P_CLK      : in  std_logic;                     -- clock
         P_RESET_IN : in  std_logic;                     -- reset signal
         P_1kHz     : in  std_logic;                     -- sampling timing

         -- CPU BUS
         P_AIN      : in  std_logic_vector(15 downto 0); -- address bus
         P_DIN      : in  std_logic_vector(15 downto 0); -- data in
         P_DOUT     : out std_logic_vector(15 downto 0); -- data out
         P_RW       : in  std_logic;                     -- read/write
         P_IR       : in  std_logic;                     -- i/o req.
         P_MR       : in  std_logic;                     -- memory req.
         P_HL       : in  std_logic;                     -- halt instruction
         P_IDLE     : in  std_logic;                     -- idle state
         P_CON      : in  std_logic_vector(1 downto 0);  -- Console access
         P_STOP     : out std_logic;                     -- stop the cpu
         P_RESET    : out std_logic;                     -- reset [OUTPUT]

         -- DMA BUS
         P_AOUT_DMA : out std_logic_vector(14 downto 0);
         P_DIN_DMA  : in  std_logic_vector(15 downto 0);
         P_DOUT_DMA : out std_logic_vector(15 downto 0);
         P_RW_DMA   : out std_logic;

         -- console switchs(inputs)
         P_DATA_SW  : in std_logic_vector(7 downto 0);   -- data sw.
         P_RESET_SW : in std_logic;                      -- reset sw.
         P_SETA_SW  : in std_logic;                      -- set address sw.
         P_INCA_SW  : in std_logic;                      -- increment addr sw.
         P_DECA_SW  : in std_logic;                      -- decrement addr sw.
         P_WRITE_SW : in std_logic;                      -- write data sw
         P_STEP_SW  : in std_logic;                      -- step exe.mode sw.
         P_BREAK_SW : in std_logic;                      -- break exe.mode sw.
         P_STOP_SW  : in std_logic;                      -- stop program
         P_RUN_SW   : in std_logic;                      -- run program
         P_RCW_SW   : in std_logic;                      -- rotate clock wise
         P_RCCW_SW  : in std_logic;                      -- rotate

         -- cosole leds(outputs)
         P_A_LED    : out std_logic_vector(7 downto 0);  -- address LED
         P_D_LED    : out std_logic_vector(7 downto 0);  -- data LED
         P_R_LED    : out std_logic;                     -- run CPU
         P_C_LED    : out std_logic;                     -- Carry LED
         P_S_LED    : out std_logic;                     -- Sing  LED
         P_Z_LED    : out std_logic;                     -- Zero  LED
         P_G0_LED   : out std_logic;                     -- G0 LED
         P_G1_LED   : out std_logic;                     -- G1 LED
         P_G2_LED   : out std_logic;                     -- G2 LED
         P_SP_LED   : out std_logic;                     -- SP LED
         P_PC_LED   : out std_logic;                     -- PC LED
         P_MM_LED   : out std_logic;                     -- MM LED
         P_BUZ      : out std_logic                      -- Buzzer
  );
end TAC_PANEL;

architecture RTL of TAC_PANEL is
  -- RESET
  signal Reset  : std_logic;                      -- inernal reset signal.
  -- register
  signal AdrReg : std_logic_vector(15 downto 0);  -- address register
  signal DatReg : std_logic_vector(15 downto 0);  -- data register
  signal Pos    : std_logic_vector( 4 downto 0);  -- rotary sw position
  signal G0     : std_logic;                      -- Pos=G0
  signal Md     : std_logic;                      -- Pos=MD
  signal Ma     : std_logic;                      -- Pos=MA
  signal Run    : std_logic;                      -- run Flip/Flop
  signal FncReg : std_logic_vector( 3 downto 0);  -- console function reg.
  signal WriteFF: std_logic;                      -- write Flip/Flop
  signal c500Hz : std_logic;                      -- 操作音用 500Hz
  signal Po     : std_logic;                      -- 操作音「ポ」出力中
  signal Slnt   : std_logic;                      -- 操作音を小さくする
  -- sampling timing
  signal Cnt    : std_logic_vector( 4 downto 0);  -- counter
  signal Cnt4D  : std_logic;                      -- delaied Cnt[4]
  signal p32ms  : std_logic;                      -- sampling timing
  -- Debounce
  signal BtnDly1: std_logic_vector(8 downto 0);   -- ９つの押しボタンで
  signal BtnDly2: std_logic_vector(8 downto 0);   --  まとめて Debounce を行う
  signal BtnDbnc: std_logic_vector(8 downto 0);
  -- ボタンのリピート
  signal RptBtn : std_logic;                      -- ボタンが操作押された
  signal RptGo  : std_logic;                      -- リピート中
  signal RptCnt1: std_logic_vector(3 downto 0);   -- リピート開始タイマ
  signal RptCnt2: std_logic_vector(2 downto 0);   -- リピート間隔タイマ
  -- ロータリースイッチの位置表示LEDの点灯パターン
  signal i_leds     : std_logic_vector( 8 downto 0); -- LED
  -- (address, data LED) に表示する内容
  signal i_disp     : std_logic_vector(15 downto 0); -- 16bitの表示内容
  -- CPUに送るレジスタ番号
  signal i_cpu_pos  : std_logic_vector(4 downto 0);

begin  -- RTL
  -- スイッチのサンプリング用 32ms 周期パルスと 500Hz 方形波を作る
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (P_1kHz='1') then
        Cnt <= Cnt + 1;
        c500Hz <= not c500Hz;
      end if;
      Cnt4D <= Cnt(4);
      p32ms <= Cnt(4) and not Cnt4D;              -- 32ms 周期のパルス
    end if;
  end process;

  -- 押しボタン９個分の Debounce 回路
  process(P_CLK, P_RESET_IN)
  begin
    if (P_RESET_IN='0') then                      -- パワーオンリセット
      BtnDly1 <= "100000000";                     -- RESET が押されたような
      BtnDly2 <= "000000000";                     --  状態を作る
      BtnDbnc <= "000000000";
    elsif (P_CLK'event and P_CLK='1') then
      if (p32ms='1') then                         -- 32ms に1回
        if (RptGo='0' or RptCnt2/="000") then     --  リピートの瞬間以外
          BtnDly2 <= BtnDly1;                     --   押しボタンの状態を読取る
        else                                      --  リピートの瞬間
          BtnDly2 <= "000000000";                 --   一旦，ボタンを戻す
        end if;
        BtnDbnc <= (not BtnDly2) and BtnDly1 and
                   ('1'                           -- (Rst)
                    & (not Run and not G0)        -- (<-)
                    & (not Run and not Ma)        -- (->)
                    & (not Run)                   -- (Run)
                    & Run                         -- (Stop)
                    & (not Run)                   -- (SetA)
                    & (not Run)                   -- (IncA)
                    & (not Run)                   -- (DecA)
                    & (not Run));                 -- (Write)
        BtnDly1 <= P_RESET_SW & P_RCCW_SW         -- 押しボタンの入力を
                   & P_RCW_SW & P_RUN_SW          --  クロックに
                   & P_STOP_SW & P_SETA_SW        --   同期しておく
                   & P_INCA_SW & P_DECA_SW
                   & P_WRITE_SW;
      else
        BtnDbnc <= "000000000";
      end if;
    end if;
  end process;

-- リピートする押しボタンが押されているか
  RptBtn <= '1' when (BtnDly1 and
                      ('0'                        -- (Rst)
                       & '1'                      -- (<-)
                       & '1'                      -- (->)
                       & P_STEP_SW                -- (Run)
                       & '0'                      -- (Stop)
                       & '0'                      -- (SetA)
                       & '1'                      -- (IncA)
                       & '1'                      -- (DecA)
                       & '0')                     -- (Write)
                     )/="000000000" else '0';

-- リピート継続中
  RptGo <= '1' when RptCnt1="1111" else '0';      -- 480ms 経過したら開始

-- 押しボタンのリピート
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (p32ms='1') then                         -- 32ms に1回
        if (RptBtn='1') then                      -- 操作されている
          if (RptGo='0') then                     --   リピート開始になってない
            RptCnt1 <= RptCnt1 + 1;               --     継続時間を測定
          elsif (RptCnt2/="100") then             --   リピート間隔は 128ms
            RptCnt2 <= RptCnt2 + 1;
          else
            RptCnt2 <= "000";
          end if;
        else                                      -- 操作されていない
          RptCnt1 <= "0000";                      --   タイマリセット
          RptCnt2 <= "000";
        end if;
      end if;
    end if;
  end process;

-- 操作音
  P_BUZ <= (Slnt or c500Hz) and Po;              -- 音が継続中は 500Hz

  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (BtnDbnc/="000000000") then              -- どれかボタンが操作された
        Po <= '1';                                --   「ピ」開始
      elsif (p32ms='1') then                      -- 32ms 後に
        Po <= '0';                                --   「ピ」終了
      end if;
    end if;
  end process;

  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(8)='1') then                    -- Btn8(Reset) が押された
        Slnt <= Slnt xor P_STOP_SW;               -- 「ピ」を「ポツ」にする
      end if;
    end if;
  end process;

  -- reset sw
  P_RESET <= Reset;
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='0') then           -- 非同期リセットは逆相を使用
      Reset <= not (BtnDbnc(8) or not P_RESET_IN);-- Btn8(Reset)
    end if;
  end process;

  -- rotary sw
  G0 <= '1' when (Pos="00000") else '0';
  Md <= '1' when (Pos="10000") else '0';
  Ma <= '1' when (Pos="10001") else '0';
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(6)='1' and Ma='0') then         -- Btn6( -> )
        Pos <= Pos + 1;
      elsif (BtnDbnc(7)='1' and G0='0') then      -- Btn7( <- )
        Pos <= Pos - 1;
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
  with Pos select i_leds <=
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
  process(Reset, P_CLK)
  begin
    if (Reset='0') then
      WriteFF <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(0)='1') then              -- Btn0(WRITE)
        WriteFF <= '1';
      elsif (P_AIN(7 downto 1)="1111111" and P_IR='1' and P_RW='0') then
        WriteFF <= '0';                     -- 実行中に i/o read FEH でクリア
      elsif (P_CON="01") then
        WriteFF <= '0';                     -- 停止中にIRに渡したらクリア
      end if;
    end if;
  end process;

  -- FncReg decoder (F_DEC)
  FncReg(3 downto 0) <=
    "0000" when (Pos(4)='0' and WriteFF='0') else                -- Reg Read
    "0001" when (Pos(4)='0' and WriteFF='1') else                -- Reg Write
    "1101" when (Pos(4)='1' and Pos(0)='0' and WriteFF='0') else -- MD Read
    "1110" when (Pos(4)='1' and WriteFF='1') else                -- MD,MA Write
    "1111";                                                      -- MA Read

  -- Address Register
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(3)='1') then                                 -- Btn3(SETA)
        AdrReg <= AdrReg(7 downto 0) & P_DATA_SW(7 downto 0);  -- 8bit shift
      elsif (BtnDbnc(2)='1') then                              -- Btn2(INCA)
        AdrReg <= AdrReg + 2;                                  -- increment
      elsif (BtnDbnc(1)='1') then                              -- Btn2(DECA)
        AdrReg <= AdrReg - 2;                                  -- decrement
      end if;
    end if;
  end process;

  -- run Flip/Flop
  P_R_LED <= Run;
  P_STOP  <= not Run;
  process(Reset, P_CLK, P_STOP_SW)
  begin
    if (Reset='0' and P_STOP_SW='0') then
      Run <= '1';
    elsif (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(4)='1' or                             -- Btn4(STOP)
          P_HL='1' or                                   -- halt instruction
          (P_MR='1' and P_IDLE='0'  and                 -- step/break
           (P_STEP_SW='1' or
            (P_BREAK_SW='1' and
             P_AIN(15 downto 1)=AdrReg(15 downto 1))))) then
        Run <= '0';
      elsif (BtnDbnc(5)='1') then                       -- Btn5(RUN)
        Run <= '1';
      end if;
    end if;
  end process;

  -- (address, data) LED
  i_disp  <= AdrReg(15 downto 1) & '0'  when Pos="10001" else   -- MA  選択時
             P_DIN_DMA when Pos="10000" else                    -- MD  選択時
             DatReg;                           -- 他を選択時，または，実行中
  P_A_LED <= i_disp(15 downto 8);
  P_D_LED <= i_disp( 7 downto 0);

  -- DatReg
  process(Reset, P_CLK)
  begin
    if (Reset='0') then
      DatReg <= "0000000000000000";
    elsif (P_CLK'event and P_CLK='1') then
      if ((P_AIN(7 downto 0)="11111000" and P_IR='1' and P_RW='1') -- 実行中
          or (P_CON="10" and (Pos<="01101" or Pos="01111"))        -- GR[Pos]
          or (P_CON="11" and Pos="01110"))  then                   -- PC
        DatReg <= P_DIN;
      end if;
    end if;
  end process;

  -- DOUT
  i_cpu_pos <= "10000" when Pos="01110" else     -- PC
                Pos;                             -- G0..FLAG

  P_DOUT <=
    ("000010" & (WriteFF and not Pos(4)) & i_cpu_pos & "0000")
                                         when (P_CON="01")             else
    (P_DIN(7 downto 0) & P_DATA_SW)      when (P_CON(1)='1')           else
    ("000000000000" & FncReg         )   when (P_AIN(2 downto 1)="11") else
    ("000000000000" & Pos(3 downto 0))   when (P_AIN(2 downto 1)="10") else
    ( AdrReg(15 downto 1) & '0'      )   when (P_AIN(2 downto 1)="01") else
    ("00000000" & P_DATA_SW          );    -- (P_AIN(2 downto 1)="00")

  -- DMA
  P_AOUT_DMA <= AdrReg(15 downto 1);
  P_DOUT_DMA <= P_DIN_DMA(7 downto 0) & P_DATA_SW;
  P_RW_DMA   <= '1' when P_CON="01" and Pos(4)='1' and WriteFF='1' else '0';

end RTL;

