--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002 - 2020 by
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
--  TeC Panel
--
--
-- 2020.12.21 : エラー時にRUNを点滅させる機能の実装漏れを訂正
-- 2019.08.05 : パワーオン時に「ピ」音を鳴らすために，起動後にリセットし直す
-- 2019.07.30 : 外部インタフェースを残して，新しい設計に置き換え
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity TEC_PANEL is
  Port ( P_RESET_IN : in  std_logic;                     -- パワーオンリセット
         P_CLK      : in  std_logic;                     -- 2.4576MHz
         P_2_4kHz   : in  std_logic;                     -- 2.4KHz
         P_18_75Hz  : in  std_logic;                     -- 18.75Hz
         P_2_3Hz    : in  std_logic;                     -- 2.3Hz
         P_RESET    : out std_logic;                     -- Reset Out Put
         P_AIN      : in  std_logic_vector (7 downto 0); -- Addr BUS
         P_LI       : in  std_logic;                     -- Instruction Fetch
         P_HL       : in  std_logic;                     -- Halt
         P_ER       : in  std_logic;                     -- Error
         P_MR       : in  std_logic;                     -- Memory Request
         P_STOP     : out std_logic;                     -- Stop
         -- スイッチからの入力
         P_DATA_SW  : in  std_logic_vector (7 downto 0); -- Data  SW
         P_RESET_SW : in  std_logic;                     -- Reset SW
         P_SETA_SW  : in  std_logic;                     -- SETA  SW
         P_INCA_SW  : in  std_logic;                     -- INCA  SW
         P_DECA_SW  : in  std_logic;                     -- DECA  SW
         P_WRITE_SW : in  std_logic;                     -- WRITE SW
         P_STEP_SW  : in  std_logic;                     -- STEP  SW
         P_BREAK_SW : in  std_logic;                     -- BREAK SW
         P_STOP_SW  : in  std_logic;                     -- STOP  SW
         P_RUN_SW   : in  std_logic;                     -- RUN   SW
         P_RCW_Sw   : in  std_logic;                     -- 右回り「→」
         P_RCCW_SW  : in  std_logic;                     -- 左回り「←」
         -- 出力
         P_R_LED    : out std_logic;                     -- Run LED
         P_SPK      : out std_logic;                     -- 操作音の出力
         P_A_LED    : out std_logic_vector (7 downto 0); -- Address LED
         P_SEL      : out std_logic_vector (2 downto 0); -- ロータリSwの位置
         P_WRITE    : out std_logic;                     -- WRITE が押された
         P_INT      : out std_logic                      -- Interrupt
         );
end TEC_PANEL;

architecture RTL of TEC_PANEL is
-- クロック・パルス
  signal c18_75HzDly: std_logic;                  -- 18.75Hz（前回の値）
  signal p18_75Hz: std_logic;                     -- 18.75Hz（パルス）
-- Debounce
  signal BtnDly1: std_logic_vector(8 downto 0);   -- ９つの押しボタンで
  signal BtnDly2: std_logic_vector(8 downto 0);   --  まとめて Debounce を行う
  signal BtnDbnc: std_logic_vector(8 downto 0);
-- ボタンのリピート
  signal RptBtn : std_logic;                      -- ボタンが操作押された
  signal RptGo  : std_logic;                      -- リピート中
  signal RptCnt1: std_logic_vector(3 downto 0);   -- リピート開始タイマ
  signal RptCnt2: std_logic_vector(2 downto 0);   -- リピート間隔タイマ
-- 操作音
  signal Pi     : std_logic;                      -- 「ピ」を鳴らしている
  signal Slnt   : std_logic;                      -- 音を小さくする
-- コンソールの機能
  signal Addr   : std_logic_vector(7 downto 0);   -- メモリのアドレス
  signal Pos    : std_logic_vector(2 downto 0);   -- ロータリースイッチの位置
  signal G0     : std_logic;                      -- G0 選択中
  signal Mm     : std_logic;                      -- MM 選択中
  signal Run    : std_logic;                      -- CPU 実行/停止
  signal Err    : std_logic;                      -- 命令コードエラー
  signal Rst    : std_logic;                      -- リセットの内部配線
  signal IntDly1: std_logic;                      -- 割込ボタンの Debounce 用
  signal IntDly2: std_logic;                      -- 割込ボタンの Debounce 用
-- 命令フェッチ
  signal Fetch  : std_logic;                      -- 命令フェッチ中

begin
-- 53ms 間隔のパルスを作る
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (P_18_75Hz='1' and c18_75HzDly='0') then -- エッジを検出する
        p18_75Hz <= '1';                          -- 18.75Hz のパルスを作る
      else
        p18_75Hz <= '0';
      end if;
      c18_75HzDly <= P_18_75Hz;                   -- エッジ検出用
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
      if (p18_75Hz='1') then                      -- 1/18.75秒(53ms)に1回
        if (RptGo='0' or RptCnt2/="000") then     --  リピートの瞬間以外
          BtnDly2 <= BtnDly1;                     --   押しボタンの状態を読取る
        else                                      --  リピートの瞬間
          BtnDly2 <= "000000000";                 --   一旦，ボタンを戻す
        end if;
        BtnDbnc <= (not BtnDly2) and BtnDly1 and
                   ('1' & not G0 & not Mm         -- (Rst)  (<-)   (->)
                    & not Run & Run & Mm          -- (Run)  (Stop) (SetA)
                    & Mm  & Mm  & not Run);       -- (IncA) (DecA) (Write)
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
            ('0'  & '1'  & '1' & '0'  & '0'       -- (Rst)(<-)(->)(Run)(Stop)
             & '0'  & '1'  & '1'  & Mm))          -- (SetA)(IncA)(DecA)(Write)
            /="000000000" else '0';

-- リピート継続中
  RptGo <= '1' when RptCnt1="1001" else '0';      -- 477ms 経過したら開始

-- 押しボタンのリピート
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (p18_75Hz='1') then                      -- 1/18.75秒(53ms)に1回
        if (RptBtn='1') then                      -- 操作されている
          if (RptGo='0') then                     --   リピート開始になってない
            RptCnt1 <= RptCnt1 + 1;               --     継続時間を測定
          elsif (RptCnt2/="100") then             --   リピート間隔は 212ms
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
  P_SPK <= (Slnt or P_2_4kHz) and Pi;             -- 音が継続中は 2.4kHz

  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (BtnDbnc/="000000000") then              -- どれかボタンが操作された
        Pi <= '1';                                --   「ピ」開始
      elsif (p18_75Hz='1') then                   -- 53ms 後に
        Pi <= '0';                                --   「ピ」終了
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

-- RESET
  Rst <= BtnDbnc(8) or not P_RESET_IN;            -- Btn8(Reset)
  P_RESET <= not Rst;                             -- 外部では負論理

-- WRITE
  P_WRITE  <= (not Run) and BtnDbnc(0);           -- Btn0(Write) 停止中は書込み

-- ロータリースイッチの位置
  P_SEL <= Pos;                                   -- 外部端子に接続
  G0 <= '1' when Pos="000" else '0';              -- G0 表示中
  Mm <= '1' when Pos="101" else '0';              -- メモリ表示中

  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(7)='1') then                    -- Btn7(CcwSw)
        Pos <= Pos - 1;
      elsif (BtnDbnc(6)='1') then                 -- Btn6(CwSw)
        Pos <= Pos + 1;
      end if;
    end if;
  end process;

-- CPU の RUN/STOP/ERROR
  P_STOP <= not Run;                              -- 外部端子に接続
  P_R_LED <= Run or (P_2_3Hz and Err);            -- 外部端子に接続
  Fetch <= P_LI and P_MR;                         -- CPUが命令をフェッチする

  process(P_CLK, Rst)                             -- Start/Stop/Error の制御
  begin
    if (Rst='1') then
      Run  <= '0';
      Err  <= '0';
    elsif (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(5)='1') then                    -- Btn5(RUN)が押された
        Run  <= '1';                              --  Startする
      elsif (P_HL='1' or BtnDbnc(4)='1' or        -- Halt 命令または Btn4(STOP)
             (Fetch='1' and P_STEP_SW='1') or     -- STEP 実行時
             (Fetch='1' and P_BREAK_SW='1' and    -- BREAK 実行時
              P_DATA_SW=P_AIN)) then
        Run  <= '0';                              --  Stopする
      end if;
      if (BtnDbnc(5)='1') then                    -- Btn5(RUN)が押された
        Err <= '0';                               --  Errはクリア
      elsif (P_ER='1') then                       -- 命令コードエラー発生
        Err <= '1';                               --  Errに記憶
      end if;
    end if;
  end process;

-- アドレス LED 関連
  P_A_LED <= Addr when Mm='1' else "00000000";    -- 外部端子に接続

  process(P_CLK, Rst)
  begin
    if (Rst='1') then
      Addr <= "00000000";
    elsif (P_CLK'event and P_CLK='1') then
      if (BtnDbnc(1)='1') then                    -- Btn1(DECA)
        Addr <= Addr - 1;
      elsif (BtnDbnc(2)='1' or                    -- Btn2(INCA)
             (BtnDbnc(0)='1' and Mm='1')) then    -- Btn0(WRITE)
        Addr <= Addr + 1;
      elsif (BtnDbnc(3)='1') then                 -- Btn3(SETA)
        Addr <= P_DATA_SW;
      end if;
    end if;
  end process;

-- コンソール割り込み
  process(P_CLK)
  begin
    if (P_CLK'event and P_CLK='1') then
      if (p18_75Hz='1') then                      -- 53ms 毎に
        if (IntDly2='0' and IntDly1='1') then     --  エッジを検出する
          P_INT <= Run;                           --   実行中なら割込み発生
        end if;
        IntDly2 <= IntDly1;                       -- 53ms 毎にサンプリング
        IntDly1 <= P_WRITE_SW;
      else
        P_INT <= '0';                             -- パルスをクリア
      end if;
    end if;
  end process;

end RTL;
