--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2011 - 2021 by
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
-- TaC/tac_spi.vhd : TaC SPI
--
-- 2021.11.18 : Idle を外部に引き出す
-- 2019.08.07 : レジスタ長が長すぎて使用していないビットの警告を消す
-- 2019.02.16 : 前回の変更箇所で P_CD をセンシビリティリストに追加忘れ訂正
-- 2019.02.09 : マイクロSDカードの挿入を検知できるようにする
-- 2016.01.10 : 予期しない割込が発生するバグを修正(エッジトリガーの処理追加)
-- 2016.01.08 : ior_blk_addr 削除(warning 対策)
-- 2014.02.24 : DMA機能作成(川部卒研)
-- 2012.01.22 : entity 名、見直し
-- 2011.12.20 : 新規作成
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

entity TAC_SPI is
  Port ( P_CLK    : in  std_logic;
         P_RESET  : in  std_logic;
         P_EN     : in  std_logic;
         P_IOR    : in  std_logic;
         P_IOW    : in  std_logic;
         P_INT    : out std_logic;
         P_ADDR   : in  std_logic_vector( 1 downto 0);
         P_DIN    : in  std_logic_vector(15 downto 0);  -- from CPU
         P_DOUT   : out std_logic_vector(15 downto 0);  -- to CPU

         -- DMA関連
         P_ADDR_DMA  : out std_logic_vector(14 downto 0);
         P_DIN_DMA   : in  std_logic_vector(15 downto 0);
         P_DOUT_DMA  : out std_logic_vector(15 downto 0);
         P_RW_DMA    : out std_logic;
         P_MR_DMA    : out std_logic;
         P_IDLE_DMA  : out std_logic;

         -- uSD端子
         P_SCLK    : out std_logic;
         P_DI      : in  std_logic;
         P_DO      : out std_logic;
         P_CS      : out std_logic;
         P_ACC     : out std_logic;
         P_CD      : in std_logic
      );
end TAC_SPI;

architecture Behavioral of TAC_SPI is

  -- 定数
  constant CMD0    : std_logic_vector(47 downto 0) := X"400000000095";
  constant CMD1    : std_logic_vector(47 downto 0) := X"410000000001";
  --constant CMD9    : std_logic_vector(47 downto 0) := X"490000000001";
  constant CMD16    : std_logic_vector(47 downto 0) := X"500000020001";
  constant CMD17    : std_logic_vector( 7 downto 0) := X"51";
  constant CMD24    : std_logic_vector( 7 downto 0) := X"58";
  constant START_BYTE  : std_logic_vector( 7 downto 0) := X"FE";
  constant CRC    : std_logic_vector( 7 downto 0) := X"01";

  -- 配線類
  signal i_init_cs  : std_logic;
  signal i_init_sclk  : std_logic;
  signal i_init_do  : std_logic;
  signal i_init_led  : std_logic;

  signal i_read_cs  : std_logic;
  signal i_read_sclk  : std_logic;
  signal i_read_do  : std_logic;
  signal i_read_led  : std_logic;

  signal i_write_cs  : std_logic;
  signal i_write_sclk  : std_logic;
  signal i_write_do  : std_logic;
  signal i_write_led  : std_logic;

  signal i_read_mr  : std_logic;  -- memory req(DMA用)
  signal i_write_mr  : std_logic;  -- memory req(DMA用)


  -- デコード結果
  signal IOW_SPI_Ctl  : std_logic;  -- コントロールの書き込み
  signal IOR_SPI_Sta  : std_logic;  -- ステータスの読み込み
  signal IOW_Mem_Addr : std_logic;  -- メモリアドレスの書き込み
  signal IOR_Mem_Addr : std_logic;  --       〃      の読み込み
  signal IOW_Blk_Addr : std_logic;  -- ブロックアドレスの書き込み
--signal IOR_Blk_Addr : std_logic;  --        〃       の読み込み
                    -- (上位16bitか下位16bitかは、P_ADDR(0)で区別)

  -- レジスタ
  signal Memory_Addr : std_logic_vector(15 downto 0);   -- メモリアドレス
  signal Block_Addr  : std_logic_vector(31 downto 0);   -- ブロックアドレス
  signal Data_Addr   : std_logic_vector(31 downto 0);   -- データアドレス
  signal Int_Ena     : std_logic;                       -- 割り込み許可
  signal Processing  : std_logic := '0';                -- 処理中(uSDと通信中)
  signal ProcessingD : std_logic := '0';                -- 1クロック遅れの信号
  signal Error       : std_logic := '0';                -- エラーが発生した
  signal Idle        : std_logic := '0';
  signal Interrupt   : std_logic := '0';                -- 割込み

  -- Init
  signal Init_Req     : std_logic;                     -- 初期化リクエスト
  signal Initializing : std_logic;                     -- 初期化中FF
  signal Init_State   : std_logic_vector( 3 downto 0); -- ステート
  signal Init_Counter : std_logic_vector( 6 downto 0); -- 汎用カウンタ
  signal Init_Clk_Cnt : std_logic_vector( 7 downto 0); -- 400kHz生成用カウンタ
  signal Init_Byte_Buffer : std_logic_vector( 6 downto 0); -- バイトバッファ
  signal Init_Error       : std_logic;                     -- エラー発生FF

  -- Read
  signal Read_Req     : std_logic;                     -- 読み込みリクエスト
  signal Reading      : std_logic;                     -- 読み込み中FF
  signal Read_State   : std_logic_vector( 2 downto 0); -- ステート
  signal Read_Counter : std_logic_vector( 4 downto 0); -- 汎用カウンタ
  signal Read_Clk_Cnt : std_logic;                     -- 25MHz生成用カウンタ
  signal Read_Byte_Buffer : std_logic_vector( 6 downto 0); -- バイトバッファ
  signal Read_Error       : std_logic;            -- エラー発生FF

  signal Read_Counter256 : std_logic_vector( 7 downto 0); -- データ受信カウンタ
  signal Read_Word_Buffer : std_logic_vector(14 downto 0);  -- ワードバッファ

  -- Write
  signal Write_Req     : std_logic;            -- 書き込みリクエスト
  signal Writing       : std_logic;            -- 書き込み中FF
  signal Write_State   : std_logic_vector( 3 downto 0);  -- ステート
  signal Write_Counter : std_logic_vector( 4 downto 0);  -- 汎用カウンタ
  signal Write_Clk_Cnt : std_logic;                      -- 25MHz生成用カウンタ
  signal Write_Byte_Buffer : std_logic_vector( 6 downto 0);  -- バイトバッファ
  signal Write_Error       : std_logic;            -- エラー発生FF

  signal Write_Counter256 : std_logic_vector( 7 downto 0); -- データ送信カウンタ
  signal Write_Word_Buffer  : std_logic_vector(15 downto 0);  -- ワードバッファ

  -- DMA
  signal Read_Addr_DMA  : std_logic_vector(14 downto 0);
  signal Write_Addr_DMA  : std_logic_vector(14 downto 0);

begin

  -- アドレスデコーダ
  IOW_SPI_Ctl <=                                                         -- 10h
    '1' when (P_IOW='1' and P_EN='1' and P_ADDR(1 downto 0)="00") else '0';
  IOR_SPI_Sta <=                                                         -- 10h
    '1' when (P_IOR='1' and P_EN='1' and P_ADDR(1 downto 0)="00") else '0';
  IOW_Mem_Addr <=                                                        -- 12h
    '1' when (P_IOW='1' and P_EN='1' and P_ADDR(1 downto 0)="01") else '0';
  IOR_Mem_Addr <=                                                        -- 12h
    '1' when (P_IOR='1' and P_EN='1' and P_ADDR(1 downto 0)="01") else '0';
  IOW_Blk_Addr <=                                                   -- 14hと16h
    '1' when (P_IOW='1' and P_EN='1' and P_ADDR(1)='1') else '0';
--IOR_Blk_Addr <=                                                   -- 14hと16h
--  '1' when (P_IOR='1' and P_EN='1' and P_ADDR(1)='1') else '0';

  -- 処理中
  Processing <= Initializing or Reading or Writing;

  -- エラー
  Error <= Init_Error or Read_Error or Write_Error;

  -- アイドル
  Idle <= (not Processing) and (not Error);
  P_IDLE_DMA <= Idle;                                -- DMA を使用していない

  -- 割込み(エッジトリガー、１パルス出力)
--P_INT <= (Idle or Error) and Int_Ena;
  P_INT <= Interrupt and Int_Ena;
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      ProcessingD <= '0';
      Interrupt   <= '0';
    elsif (P_CLK' event and P_CLK = '1') then
      ProcessingD <= Processing;
      if (ProcessingD='1' and Processing='0') then   -- 処理完了
        Interrupt <= '1';                            -- 割込み発生
      else
        Interrupt <= '0';                            -- 次回割込みの準備
      end if;
    end if;
   end process;

  -- メモリアドレス
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      Memory_Addr <= (others => '0');
    elsif (P_CLK' event and P_CLK = '1') then
      if (IOW_Mem_Addr = '1') then
        Memory_Addr <= P_DIN;
      end if;
    end if;
  end process;

  -- ブロックアドレス(データアドレス)
  -- 注：データアドレスはブロックアドレスを9bit左シフト
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      Block_Addr <= (others => '0');
      Data_Addr  <= (others => '0');
    elsif (P_CLK' event and P_CLK = '1') then
      if (IOW_Blk_Addr = '1') then
        -- ブロックアドレス上位16bit(I/O 14h)
        if (P_ADDR(0) = '0') then
          Block_Addr(31 downto 16) <= P_DIN;
          Data_Addr(31 downto 25) <= P_DIN(6 downto 0);
        -- ブロックアドレス下位16bit(I/O 16h)
        else
          Block_Addr(15 downto 0) <= P_DIN;
          Data_Addr(24 downto 9) <= P_DIN;
        end if;
      end if;
    end if;
  end process;

  -- データバス
  --
  -- 【ステータス仕様】
  --
  --   0000 0000 IE00 0000
  --
  --   I(Idle)…初期化、読み込み、書き込みのいずれも正常に実行可能である
  --    I <= (not Processing) and (not Error)
  --   E(Error)…処理中にエラーが発生した
  --     E <= Error
  --
  --   IE = 00  ->  処理中
  --   IE = 01  ->  エラーが発生した(初期化が必要)
  --   IE = 10  ->  暇だよ
  --   IE = 11  ->  ありえない
  --
  process(IOR_SPI_Sta,IOR_Mem_Addr,Idle,
          Error,Memory_Addr,Block_Addr,P_ADDR,P_CD)
  begin
    if (IOR_SPI_Sta = '1') then
      P_DOUT <= "00000000" & Idle & Error & "00000" & P_CD; -- ステータスを出力
    elsif (IOR_Mem_Addr = '1') then
      P_DOUT <= Memory_Addr;                            -- メモリアドレスを出力
    elsif (P_ADDR(0) = '0') then
      P_DOUT <= Block_Addr(31 downto 16);    -- ブロックアドレス上位16bitを出力
    else
      P_DOUT <= Block_Addr(15 downto 0);     -- ブロックアドレス下位16bitを出力
    end if;
  end process;

  -- コントロール
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      Int_Ena   <= '0';
      Init_Req  <= '0';
      Read_Req  <= '0';
      Write_Req <= '0';
    elsif (P_CLK'event and P_CLK = '1') then
      -- 割込み設定、処理開始をラッチ
      if (IOW_SPI_Ctl = '1') then
        Int_Ena   <= P_DIN(7);
        Init_Req  <= P_DIN(2);
        Read_Req  <= P_DIN(1);
        Write_Req <= P_DIN(0);
      -- 処理開始リクエストは次のタイミングで取り下げる
      else
        if (Initializing = '0') then
          Init_Req <= '0';
        end if;
        if (Reading = '0') then
          Read_Req <= '0';
        end if;
        if (Writing = '0') then
          Write_Req <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Init
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      Init_Clk_Cnt     <= "00000000";
      Init_Counter     <= "0000000";
      Init_State       <= "0000";
      Initializing     <= '0';
      Init_Byte_Buffer <= "1111111";
      i_init_cs        <= '1';
      i_init_sclk      <= '1';
      i_init_do        <= '1';
      i_init_led       <= '0';
    elsif (P_CLK' event and P_CLK = '1') then
      if (Initializing = '1') then
        if (Init_Clk_Cnt = 61) then -- このif文の中は400kHz毎(ネガティブエッジ)
          Init_Clk_Cnt <= Init_Clk_Cnt + 1;
          i_init_sclk <= '0';       -- uSDのクロックを立ち下げる

          case Init_State is
          -- 80回のダミークロック
          when "0000" =>

          -- CMD0の送信
          when "0001" =>
            i_init_cs <= '0';
            i_init_do <= CMD0(conv_integer(Init_Counter));
          -- R1レスポンス(0x01)待ち
          when "0010" =>

          -- 8回のダミークロック
          when "0011" =>
            i_init_cs <= '1';
          -- CMD1の送信
          when "0100" =>
            i_init_cs <= '0';
            i_init_do <= CMD1(conv_integer(Init_Counter));
          -- R1レスポンス(0x00)の受信
          when "0101" =>
            i_init_do <= '1';
          -- 8回のダミークロック
          when "0110" =>
            i_init_cs <= '1';

          -- ここからブロック長の変更
          -- CMD16の送信
          when "0111" =>
            i_init_cs <= '0';
            i_init_do <= CMD16(conv_integer(Init_Counter));
          -- R1レスポンス(0x00)の受信
          when "1000" =>
            i_init_do <= '1';
          when others =>
          end case;

        elsif (Init_Clk_Cnt = 123) then -- 400kHz毎(ポジティブエッジ)
          Init_Clk_Cnt <= "00000000";
          i_init_sclk <= '1';           -- uSDのクロックを立ち上げる

          case Init_State is
          -- 80回のダミークロック
          when "0000" =>
            if (Init_Counter = 0) then
              Init_Counter <= conv_std_logic_vector(47, 7);
              Init_State <= "0001";
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- CMD0の送信
          when "0001" =>
            if (Init_Counter = 0) then
              Init_Counter <= conv_std_logic_vector(7, 7);
              Init_State <= "0010";
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- R1レスポンス(0x01)の受信
          when "0010" =>
            Init_Byte_Buffer(6 downto 0) <= Init_Byte_Buffer(5 downto 0) & P_DI;
            if (Init_Counter = 0) then
              if (Init_Byte_Buffer(6 downto 0) & P_DI = X"01") then
                Init_Counter <= conv_std_logic_vector(7, 7);
                Init_State <= "0011";
              elsif (Init_Byte_Buffer(6 downto 0) & P_DI = X"FF") then
                Init_Counter <= conv_std_logic_vector(7, 7);
              else
                Init_Error   <= '1';
                Initializing <= '0';
                i_init_cs   <= '1';
                i_init_sclk   <= '1';
                i_init_do   <= '1';
                i_init_led   <= '0';
              end if;
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- 8回のダミークロック
          when "0011" =>
            if (Init_Counter = 0) then
              Init_Counter <= conv_std_logic_vector(47, 7);
              Init_State <= "0100";
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- CMD1の送信
          when "0100" =>
            if (Init_Counter = 0) then
              Init_Counter <= conv_std_logic_vector(7, 7);
              Init_State <= "0101";
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- R1レスポンス(0x00)の受信
          when "0101" =>
            Init_Byte_Buffer(6 downto 0) <= Init_Byte_Buffer(5 downto 0) & P_DI;
            if (Init_Counter = 0) then
              if (Init_Byte_Buffer(6 downto 0) & P_DI = X"00") then
                Init_Counter <= conv_std_logic_vector(7, 7);
                Init_State <= "0110";
              elsif (Init_Byte_Buffer(6 downto 0) & P_DI = X"FF") then
                Init_Counter <= conv_std_logic_vector(7, 7);
              elsif (Init_Byte_Buffer(6 downto 0) & P_DI = X"01") then
                Init_Counter <= conv_std_logic_vector(7, 7);
                Init_State <= "0011";
              else
                Init_Error   <= '1';
                Initializing <= '0';
                i_init_cs   <= '1';
                i_init_sclk   <= '1';
                i_init_do   <= '1';
                i_init_led   <= '0';
              end if;
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- 8回のダミークロック
          when "0110" =>
            if (Init_Counter = 0) then
              Init_Counter <= conv_std_logic_vector(47, 7);
              Init_State <= "0111";
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- ここからブロック長の変更
          -- CMD16の送信
          when "0111" =>
            if (Init_Counter = 0) then
              Init_Counter <= conv_std_logic_vector(7, 7);
              Init_State <= "1000";
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          -- R1レスポンス(0x00)待ち
          when "1000" =>
            Init_Byte_Buffer(6 downto 0) <= Init_Byte_Buffer(5 downto 0) & P_DI;
            if (Init_Counter = 0) then
              if (Init_Byte_Buffer(6 downto 0) & P_DI = X"00") then
                Initializing <= '0';
                i_init_cs   <= '1';
                i_init_sclk   <= '1';
                i_init_do   <= '1';
                i_init_led   <= '0';
              elsif (Init_Byte_Buffer(6 downto 0) & P_DI = X"FF") then
                Init_Counter <= conv_std_logic_vector(7, 7);
              else
                Init_Error   <= '1';
                Initializing <= '0';
                i_init_cs   <= '1';
                i_init_sclk   <= '1';
                i_init_do   <= '1';
                i_init_led   <= '0';
              end if;
            else
              Init_Counter <= Init_Counter - 1;
            end if;
          when others =>
          end case;

        else
          Init_Clk_Cnt <= Init_Clk_Cnt + 1;
        end if;
      elsif (Init_Req = '1') then        -- 初期化リクエストがあったら
        Initializing   <= '1';           -- 初期化中FFをセット
        Init_Clk_Cnt   <= "00000000";
        Init_Counter   <= conv_std_logic_vector(79, 7);  -- 80回のダミークロック
        Init_State     <= "0000";
        Init_Byte_Buffer <= "1111111";
        i_init_cs     <= '1';
        i_init_sclk     <= '1';
        i_init_do     <= '1';
        i_init_led     <= '1';
      end if;

      if (Init_Req = '1') then
        Init_Error <= '0';
      end if;

    end if;
  end process;

  -- Read
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      Read_Clk_Cnt   <= '0';
      Read_Counter   <= "00000";
      Read_Counter256   <= "00000000";
      Read_State     <= "000";
      Reading       <= '0';
      Read_Byte_Buffer <= "1111111";
      Read_Word_Buffer <= "111111111111111";
      Read_Addr_DMA   <= "000000000000000";
      i_read_cs     <= '1';
      i_read_sclk     <= '1';
      i_read_do     <= '1';
      i_read_led     <= '0';
      i_read_mr     <= '0';
    elsif (P_CLK' event and P_CLK = '1') then
      if (Reading = '1') then
        if (Read_Clk_Cnt = '0') then -- このif文の中は25MHz毎(ネガティブエッジ)
          Read_Clk_Cnt <= '1';
          i_read_sclk <= '0';        -- uSDのクロックを立ち下げる

          case Read_State is
          -- CMD17の送信
          -- CMD17
          when "000" =>
            i_read_cs <= '0';
            i_read_do <= CMD17(conv_integer(Read_Counter));
          -- 引数(バイトアドレス)
          when "001" =>
            i_read_do <= Data_Addr(conv_integer(Read_Counter));
          -- CRC
          when "010" =>
            i_read_do <= CRC(conv_integer(Read_Counter));
          -- R1レスポンス(0x00)の受信
          when "011" =>

          -- スタートバイト(0xFE)の受信
          when "100" =>

          -- データブロックの受信
          when "101" =>

          -- 24回のダミークロック
          when "110" =>
            i_read_cs <= '1';
          when others =>
          end case;

        elsif (Read_Clk_Cnt='1') then --このif文の中は25MHz毎(ポジティブエッジ)
          Read_Clk_Cnt <= '0';
          i_read_sclk <= '1';         -- uSDのクロックを立ち上げる

          case Read_State is
          -- CMD17の送信
          -- CMD17
          when "000" =>
            if (Read_Counter = 0) then
              Read_Counter <= conv_std_logic_vector(31, 5);
              Read_State <= "001";
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          -- 引数(バイトアドレス)
          when "001" =>
            if (Read_Counter = 0) then
              Read_Counter <= conv_std_logic_vector(7, 5);
              Read_State <= "010";
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          -- CRC
          when "010" =>
            if (Read_Counter = 0) then
              Read_Counter <= conv_std_logic_vector(7, 5);
              Read_State <= "011";
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          -- R1レスポンス(0x00)の受信
          when "011" =>
            Read_Byte_Buffer <= Read_Byte_Buffer(5 downto 0) & P_DI;
            if (Read_Counter = 0) then
              if (Read_Byte_Buffer & P_DI = X"00") then
                Read_Counter <= conv_std_logic_vector(7, 5);
                Read_State <= "100";
              elsif (Read_Byte_Buffer & P_DI = X"FF") then
                Read_Counter <= conv_std_logic_vector(7, 5);
              else
                Read_Error  <= '1';
                Reading    <= '0';
                i_read_cs  <= '1';
                i_read_sclk  <= '1';
                i_read_do  <= '1';
                i_read_led  <= '0';
                Read_Addr_DMA <= "000000000000000";
              end if;
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          -- スタートバイト(0xFE)の受信
          when "100" =>
            Read_Byte_Buffer <= Read_Byte_Buffer(5 downto 0) & P_DI;
            if (Read_Counter = 0) then
              if (Read_Byte_Buffer & P_DI = X"FE") then
                Read_Counter <= conv_std_logic_vector(15, 5);
                Read_Counter256 <= conv_std_logic_vector(255, 8);
                Read_State <= "101";
              elsif (Read_Byte_Buffer & P_DI = X"FF") then
                Read_Counter <= conv_std_logic_vector(7, 5);
              else
                -- カード範囲外の可能性
                Read_Error  <= '1';
                Reading    <= '0';
                i_read_cs  <= '1';
                i_read_sclk  <= '1';
                i_read_do  <= '1';
                i_read_led  <= '0';
                Read_Addr_DMA <= "000000000000000";
              end if;
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          -- データブロックの受信
          when "101" =>
            Read_Word_Buffer(14 downto 0) <= Read_Word_Buffer(13 downto 0)&P_DI;
            -- 2バイト(1ワード)受信したか(ワード受信判定)
            if (Read_Counter = 0) then
              Read_Counter <= conv_std_logic_vector(15, 5);
              -- DMA開始
              P_DOUT_DMA <= Read_Word_Buffer(14 downto 0) & P_DI;
              if (not (Read_Counter256 = 255)) then
                Read_Addr_DMA <= Read_Addr_DMA + 1;
              end if;
              P_RW_DMA <= '1';
              i_read_mr <= '1';
              -- 512バイト(256ワード)受信したか(ブロック受信判定)
              if (Read_Counter256 = 0) then
                Read_Counter <= conv_std_logic_vector(24, 5);
                Read_State <= "110";
              else
                Read_Counter256 <= Read_Counter256 - 1;
              end if;
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          -- 24回のダミークロック
          when "110" =>
            if (Read_Counter = 0) then
              Reading    <= '0';
              i_read_cs  <= '1';
              i_read_sclk  <= '1';
              i_read_do  <= '1';
              i_read_led  <= '0';
              Read_Addr_DMA <= "000000000000000";
            else
              Read_Counter <= Read_Counter - 1;
            end if;
          when others =>
          end case;

        else
          Read_Clk_Cnt <= '1';
        end if;

        -- DMA(Buffer -> TaC RAM)
        if (i_read_mr = '1') then
          P_RW_DMA <= '0';
          i_read_mr <= '0';
        end if;

      elsif (Read_Req = '1') then        -- 読み込みリクエストがあったら
        Reading       <= '1';      -- 読み込み中FFをセット
        Read_Clk_Cnt   <= '0';
        Read_Counter   <= conv_std_logic_vector(7, 5);
        Read_State     <= "000";
        Read_Byte_Buffer <= "1111111";
        Read_Word_Buffer <= "111111111111111";
        i_read_cs     <= '1';
        i_read_sclk     <= '1';
        i_read_do     <= '1';
        i_read_led     <= '1';
        Read_Addr_DMA   <= Memory_Addr(15 downto 1);
        i_read_mr     <= '0';
      end if;

      if (Init_Req = '1') then
        Read_Error <= '0';
      end if;

    end if;
  end process;

  -- Write
  process (P_CLK, P_RESET)
  begin
    if (P_RESET = '0') then
      Write_Clk_Cnt     <= '0';
      Write_Counter     <= "00000";
      Write_Counter256  <= "00000000";
      Write_State      <= "0000";
      Writing        <= '0';
      Write_Byte_Buffer <= "1111111";
      Write_Word_Buffer <= "0000000000000000";
      Write_Addr_DMA    <= "000000000000000";
      i_write_cs      <= '1';
      i_write_sclk    <= '1';
      i_write_do      <= '1';
      i_write_led      <= '0';
      i_write_mr      <= '0';
    elsif (P_CLK' event and P_CLK = '1') then
      if (Writing = '1') then
        if (Write_Clk_Cnt='0') then -- このif文の中は25MHz毎(ネガティブエッジ)
          Write_Clk_Cnt <= '1';
          i_write_sclk <= '0';      -- uSDのクロックを立ち下げる

          case Write_State is
          -- CMD24の送信
          -- CMD24
          when "0000" =>
            i_write_cs <= '0';
            i_write_do <= CMD24(conv_integer(Write_Counter));
          -- 引数(バイトアドレス)
          when "0001" =>
            i_write_do <= Data_Addr(conv_integer(Write_Counter));
          -- CRC
          when "0010" =>
            i_write_do <= CRC(conv_integer(Write_Counter));
          -- R1レスポンス(0x00)の受信
          when "0011" =>
            i_write_do <= '1';
          -- スタートバイト(0xFE)の送信
          when "0100" =>
            i_write_do <= START_BYTE(conv_integer(Write_Counter));
          -- データの送信
          when "0101" =>
            i_write_do <= Write_Word_Buffer(conv_integer(Write_Counter));
            -- DMA開始
            if (Write_Counter = 0) then
              i_write_mr <= '1';
              Write_Addr_DMA <= Write_Addr_DMA + 1;
            end if;
          -- CRC(ダミークロック2byte)の送信
          when "0110" =>
            i_write_do <= '0';
          -- データレスポンス(0x5)の受信
          when "0111" =>
            i_write_do <= '1';
          -- BUSYの間待つ
          when "1000" =>

          -- 8回のダミークロック
          when "1001" =>
            i_write_cs <= '1';

          when others =>
          end case;

        elsif (Write_Clk_Cnt='1') then -- 25MHz毎(ポジティブエッジ)
          Write_Clk_Cnt <= '0';
          i_write_sclk <= '1';      -- uSDのクロックを立ち上げる

          case Write_State is
          -- CMD24の送信
          -- CMD24
          when "0000" =>
            if (Write_Counter = 0) then
              Write_Counter <= conv_std_logic_vector(31, 5);
              Write_State <= "0001";
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- 引数(バイトアドレス)
          when "0001" =>
            if (Write_Counter = 0) then
              Write_Counter <= conv_std_logic_vector(7, 5);
              Write_State <= "0010";
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- CRC
          when "0010" =>
            if (Write_Counter = 0) then
              Write_Counter <= conv_std_logic_vector(7, 5);
              Write_State <= "0011";
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- R1レスポンス(0x00)の受信
          when "0011" =>
            Write_Byte_Buffer <= Write_Byte_Buffer(5 downto 0)&P_DI;
            if (Write_Counter = 0) then
              if (Write_Byte_Buffer & P_DI = X"00") then
                Write_Counter <= conv_std_logic_vector(7, 5);
                Write_State <= "0100";
              elsif (Write_Byte_Buffer & P_DI = X"FF") then
                Write_Counter <= conv_std_logic_vector(7, 5);
              else
                Write_Error   <= '1';
                Writing     <= '0';
                i_write_cs   <= '1';
                i_write_sclk <= '1';
                i_write_do   <= '1';
                i_write_led   <= '0';
                Write_Addr_DMA <= "000000000000000";
              end if;
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- スタートバイト(0xFE)の送信
          when "0100" =>
            if (Write_Counter = 0) then
              Write_Counter <= conv_std_logic_vector(15, 5);
              Write_Counter256 <= conv_std_logic_vector(255, 8);
              Write_State <= "0101";
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- データの送信
          when "0101" =>
            if (Write_Counter = 0) then
              Write_Counter <= conv_std_logic_vector(15, 5);
              if (Write_Counter256 = 0) then
                Write_Counter <= conv_std_logic_vector(15, 5);
                Write_State <= "0110";
              else
                Write_Counter256 <= Write_Counter256 - 1;
              end if;
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- CRC(ダミークロック2byte)の送信
          when "0110" =>
            if (Write_Counter = 0) then
              Write_Counter <= conv_std_logic_vector(7, 5);
              Write_State <= "0111";
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- データレスポンス(0x5)の受信
          when "0111" =>
            Write_Byte_Buffer <= Write_Byte_Buffer(5 downto 0)&P_DI;
            if (Write_Counter = 0) then
              if (Write_Byte_Buffer & P_DI = X"FF") then
                Write_Counter <= conv_std_logic_vector(7, 5);
              elsif (Write_Byte_Buffer(3 downto 0) & P_DI = X"5") then
                Write_Counter <= conv_std_logic_vector(7, 5);
                Write_State <= "1000";
              else
                -- カード範囲外の可能性
                Write_Error   <= '1';
                Writing     <= '0';
                i_write_cs   <= '1';
                i_write_sclk <= '1';
                i_write_do   <= '1';
                i_write_led   <= '0';
                Write_Addr_DMA <= "000000000000000";
              end if;
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- busyの間待つ
          when "1000" =>
            Write_Byte_Buffer <= Write_Byte_Buffer(5 downto 0)&P_DI;
            if (Write_Counter = 0) then
              if (Write_Byte_Buffer & P_DI = X"00") then
                Write_Counter <= conv_std_logic_vector(7, 5);
              else
                Write_Counter <= conv_std_logic_vector(7, 5);
                Write_State <= "1001";
              end if;
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          -- 8回のダミークロック
          when "1001" =>
            if (Write_Counter = 0) then
              Writing     <= '0';
              i_write_cs   <= '1';
              i_write_sclk <= '1';
              i_write_do   <= '1';
              i_write_led   <= '0';
              Write_Addr_DMA <= "000000000000000";
            else
              Write_Counter <= Write_Counter - 1;
            end if;
          when others =>
          end case;

        else
          Write_Clk_Cnt <= '1';
        end if;

        -- DMA(TaC RAM -> Buffer)
        if (i_write_mr = '1') then
          i_write_mr <= '0';
          Write_Word_Buffer <= P_DIN_DMA;
        end if;

      elsif (Write_Req = '1') then      -- 書き込みリクエストがあったら
        Writing        <= '1';      -- 書き込み中FFをセット
        Write_Clk_Cnt    <= '0';
        Write_Counter    <= conv_std_logic_vector(7, 5);
        Write_State     <= "0000";
        Write_Byte_Buffer <= "1111111";
        Write_Word_Buffer <= "0000000000000000";
        i_write_cs       <= '1';
        i_write_sclk    <= '1';
        i_write_do      <= '1';
        i_write_led      <= '1';

        -- 次のクロックで、最初に書き込むワードをバッファに取り込んでおく
        Write_Addr_DMA <= Memory_Addr(15 downto 1);
        i_write_mr <= '1';
      end if;

      if (Init_Req = '1') then
        Write_Error <= '0';
      end if;

    end if;
  end process;

  -- 各プロセスの配線をuSD端子へ集約
  P_CS   <= i_init_cs and i_read_cs and i_write_cs;
  P_DO   <= i_init_do and i_read_do and i_write_do;
  P_SCLK <= i_init_sclk and i_read_sclk and i_write_sclk;
  P_ACC  <= not (i_init_led or i_read_led or i_write_led);

  -- 各プロセスの配線をDMA用端子へ集約
  P_ADDR_DMA <= Read_Addr_DMA or Write_Addr_DMA;
  P_MR_DMA <= i_read_mr or i_write_mr;

end Behavioral;
