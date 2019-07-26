--
-- TeC7 VHDL Source Code
--
-- VGA interface
--
-- 2016. 1. 8 process のセンシビリティーリスト修正（warning 対策), 重村
-- 2011. 2. 7 エムズエンジニアリング株式会社

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity VGA is
    Port ( P_CLK   : in std_logic; -- VGA 動作用
           P_CLK_CPU : in std_logic; -- CPU bus 用 VideoRAM Access clock
			  P_RESET : in std_logic;  -- RESET
           P_WE : in std_logic;
           P_ADDR : in std_logic_vector(10 downto 0);
           P_DIN : in std_logic_vector(7 downto 0);
           P_DOUT : out std_logic_vector(7 downto 0);
           R,G,B : out std_logic;
           HS,VS : out std_logic
    );
end VGA;

architecture Behavioral of VGA is

-- 同期信号用バッファ
signal S_HS : std_logic;
signal S_VS : std_logic;
-- 映像信号用バッファ
signal r_buf : std_logic;
signal g_buf : std_logic;
signal b_buf : std_logic;
-- カウンタ
signal CNT_P : std_logic_vector(9 downto 0);    -- 水平 pixel カウンタ
signal CNT_L : std_logic_vector(9 downto 0);    -- 垂直 line カウンタ
signal CNT_PC : std_logic_vector(3 downto 0);   -- 文字 pixel カウンタ
signal CNT_LC : std_logic_vector(4 downto 0);   -- 文字 line カウンタ
signal CNT_VA : std_logic_vector(10 downto 0);  -- VRAM address カウンタ
signal CNT_CU : std_logic_vector(25 downto 0);  -- カーソルのブリンク用
-- レジスタ
signal CNT_VA_prev : std_logic_vector(10 downto 0); -- 行頭の VRAM address 
signal outbuf : std_logic_vector(7 downto 0);   -- フォント1列分シフトレジスタ
signal COLOR : std_logic_vector(7 downto 0) := "00001111";  -- 文字色設定
signal CX    : std_logic_vector(6 downto 0) := "0000000";   -- カーソルX座標
signal CY    : std_logic_vector(4 downto 0) := "00000";     -- カーソルy座標
signal CXV   : std_logic_vector(6 downto 0) := "0000000";   -- カーソルX座標
signal CYV   : std_logic_vector(4 downto 0) := "00000";     -- カーソルy座標
signal CA    : std_logic_vector(10 downto 0);
signal CAY   : std_logic_vector(10 downto 0);
-- イネーブル
signal vram_en : std_logic; -- VRAM enable
signal font_ld : std_logic; -- FONT ROM output load
signal h_act_work : std_logic; -- 水平表示エリア
signal h_act : std_logic_vector(3 downto 0); -- 水平表示エリア遅延分
signal v_act : std_logic; -- 垂直表示エリア
signal v_vact : std_logic; -- 垂直文字表示エリア
signal h_end : std_logic; -- 水平表示エリア立ち下がり
signal v_up : std_logic; -- CNT_L カウントアップ
-- その他信号線
signal CODE : std_logic_vector(7 downto 0); -- 文字 code
signal LINE : std_logic_vector(7 downto 0); -- ひと文字１列分 FONT data
signal cur  : std_logic;                    -- カーソルを表示するタイミング

-- 動作設定値
constant CX_ADDR : integer := 2045; -- 0x7FD
constant CY_ADDR : integer := 2046; -- 0x7FE
constant COLOR_ADDR : integer := 2047; -- 0x7FF
constant H_WIDTH : integer := 798;
constant H_ACTIVE : integer := 640;
constant H_SYNC_START : integer := H_ACTIVE + 5 + 15;
-- "+5" は Active エリアの遅延時間分
constant H_SYNC_END : integer := H_SYNC_START + 96;
constant CNT_PC_MAX : integer := 8;
constant CNT_PC_EN : integer := 1;
constant CNT_PC_LD : integer := CNT_PC_EN + 2;
constant V_WIDTH : integer := 525;
constant V_ACTIVE : integer := 475;
constant V_SYNC_START : integer := V_ACTIVE + 2 + 10;
-- "+2" は Active エリアが 480 に対して 5 [line] 不足のための調整
-- 画面上部に 3 [line] 下部に 2[line] 挿入で調整
constant V_SYNC_END : integer := V_SYNC_START + 2;
constant V_SYNC_P : integer := H_SYNC_START;
constant V_VACTIVE : integer := 16;
constant CNT_LC_MAX : integer := 19;

signal logic0, logic1 : std_logic;

---- 使用するコンポーネントの宣言 ---
-- VideoRAM
component VideoRAM
    Port ( P_CLKA : in std_logic;
           P_EN : in std_logic;
           P_ADDRA : in std_logic_vector(10 downto 0);
           P_DOUTA : out std_logic_vector(7 downto 0);
   
           P_CLKB : in std_logic;
           P_WE : in std_logic;
           P_ADDRB : in std_logic_vector(10 downto 0);
           P_DIN : in std_logic_vector(7 downto 0);
           P_DOUTB : out std_logic_vector(7 downto 0)
   );
end component;
-- CharaGeneROM
component CharGene
  port (
    P_CLK  : in std_logic;
    P_CODE : in std_logic_vector(7 downto 0);
    P_HEIGHT : in  std_logic_vector(3 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end component;

begin
    logic0 <= '0';
    logic1 <= '1';

    -- 各コンポーネントと接続  
    -- VideoRAM
    vram : VideoRAM
        port map (
            P_CLKA => P_CLK,
            P_EN => vram_en,
            P_ADDRA => CNT_VA,
            P_DOUTA => CODE,
            
            P_CLKB => P_CLK_CPU,
            P_WE => P_WE,
            P_ADDRB => P_ADDR,
            P_DIN => P_DIN,
            P_DOUTB => P_DOUT
        );
    
    -- CharGeneROM”；
    cgrom: CharGene
        port map (
            P_CLK  => P_CLK,
            P_CODE => CODE,
            P_HEIGHT => CNT_LC(3 downto 0),
            P_DOUT => LINE
        );

    -- 色設定レジスタ (COLOR: bit7/4=-, bit6/2=R, bit5/1=G, bit4/0=B)
    --  upper = 背景色 ("0000"=黒(Default), "0111"=白)
    --  lower = 文字色 ("0000"=黒         , "0111"=白(Default))
    process(P_RESET, P_CLK_CPU)
    begin
        if (P_RESET = '0') then
            COLOR <= "00000111";
        elsif (P_CLK_CPU = '1' and P_CLK_CPU'event) then
            if (P_WE = logic1 and P_ADDR = COLOR_ADDR) then
                COLOR <= P_DIN;
            end if;
        end if;
    end process;

    -- カーソルアドレス
    process(P_RESET, P_CLK_CPU)
    begin
        if (P_RESET = '0') then
            CX <= "0000000";
            CY <= "00000";
        elsif (P_CLK_CPU = '1' and P_CLK_CPU'event) then
            if (P_WE = logic1 and P_ADDR = CX_ADDR) then
                CX <= P_DIN(6 downto 0);
            elsif (P_WE = logic1 and P_ADDR = CY_ADDR) then
                CY <= P_DIN(4 downto 0);
            end if;
        end if;
    end process;

    -- 水平 pixel カウンタ (CNT_P)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (CNT_P = (H_WIDTH - 1)) then
                CNT_P <= (others => '0');
            else
                CNT_P <= CNT_P + '1';
            end if;
        end if;
    end process;

    -- 水平同期信号 (S_HS)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (CNT_P = (H_SYNC_START - 1)) then
                S_HS <= logic1;
            elsif (CNT_P = (H_SYNC_END - 1)) then
                S_HS <= logic0;
            else
                S_HS <= S_HS;
            end if;
        end if;
    end process;

    HS <= not S_HS;
    h_act_work <= logic1 when (CNT_P <= (H_ACTIVE - 1)) else logic0;
    v_up <= logic1 when (CNT_P = (H_WIDTH - 1)) else logic0;

    -- 水平表示有効エリア
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            h_act <= h_act(2 downto 0) & h_act_work;
        end if;
    end process;
    
    h_end <= not h_act_work and h_act(0); 

    -- 文字 pixel カウンタ (CNT_PC)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (h_act_work = logic1 and v_vact = logic1) then
                if (CNT_PC = (CNT_PC_MAX - 1)) then
                    CNT_PC <= (others => '0');
                else
                    CNT_PC <= CNT_PC + '1';
                end if;
            else
                CNT_PC <= (others => '0');
            end if;
        end if;
    end process;

    vram_en <= logic1 when (CNT_PC = CNT_PC_EN) else logic0;
    font_ld <= logic1 when (CNT_PC = CNT_PC_LD) else logic0;

    -- カーソル表示
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
          if (CNT_CU=50000000) then                 -- カーソルブリンク周期
            CNT_CU <= (others => '0');
          else
            CNT_CU <= CNT_CU + 1;
          end if;
        end if;
    end process;

    -- カーソルアドレス
    CA  <= (CYV & "000000")+("00" & CYV & "0000") + ("0000" & CXV);

    process(P_CLK)
    begin
        if (P_CLK='1' and P_CLK'event) then
          CXV <= CX;   -- CPU クロックからVGA クロックに橋渡し
          CYV <= CY;   -- (この部分はタイミング制約が満たされないので、
                       --  UCFファイルにTIG(タイミング無視)を書いておく)

          if (vram_en=logic1) then
            if (CNT_VA=CA and CNT_CU(25 downto 23)>="011") then
              cur <= logic1;                        -- カーソルを表示するべき
            else
              cur <= logic0;
            end if;
          end if;
        end if;
    end process;

    -- FONT データ出力 並列→直列変換
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (font_ld = logic1) then
              if (cur=logic0) then
                outbuf <= LINE;
              else
                outbuf <= not LINE;                 -- リーバースでカーソル表現
              end if;
            else
                outbuf <= outbuf(6 downto 0) & '0';
            end if;
        end if;
    end process;

    -- VGA 出力 (R/G/B) 色設定＆出力
    --process(P_CLK)
    process(h_act, v_act, outbuf, color, logic0, logic1)
    begin
        --if (P_CLK = '1' and P_CLK'event) then
            if (h_act(3) = logic1 and v_act = logic1) then
                if (outbuf(7) = logic1) then -- FONT 色設定
                    r_buf <= COLOR(2);
                    g_buf <= COLOR(1);
                    b_buf <= COLOR(0);
                else                         -- 背景色設定
                    r_buf <= COLOR(6);
                    g_buf <= COLOR(5);
                    b_buf <= COLOR(4);
                end if;
            else                             -- それ以外は黒 (R/G/B = "0")
                r_buf <= logic0;
                g_buf <= logic0;
                b_buf <= logic0;
            end if; 
        --end if;
    end process;

    R <= r_buf;
    G <= g_buf;
    B <= b_buf;

    -- VRAM address カウンタ (CNT_VA)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_act = logic0) then
                CNT_VA <= (others => '0');
            elsif (h_end = logic1 and CNT_LC /= (V_VACTIVE - 1)) then
                CNT_VA <= CNT_VA_prev;
            elsif (vram_en =logic1) then
                CNT_VA <= CNT_VA + '1';
            else
                CNT_VA <= CNT_VA;
            end if;
        end if;
    end process;

    -- VRAM address カウンタ 初期値 (CNT_VA_prev)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_act = logic0) then
                CNT_VA_prev <= (others => '0');
            elsif (h_end = logic1 and CNT_LC = (V_VACTIVE - 1)) then
                CNT_VA_prev <= CNT_VA;
            else
                CNT_VA_prev <= CNT_VA_prev;
            end if;
        end if;
    end process;

    -- 垂直 line カウンタ (CNT_L)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_up = logic1) then
                if (CNT_L = (V_WIDTH - 1)) then
                    CNT_L <= (others => '0');
                else
                    CNT_L <= CNT_L + '1';
                end if;
            else
                CNT_L <= CNT_L;
            end if;
        end if;
    end process;

    -- 垂直同期信号 (S_VS)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (CNT_L = (V_SYNC_START - 1) and  CNT_P = (V_SYNC_P - 1)) then
                S_VS <= logic1;
            elsif (CNT_L = (V_SYNC_END - 1) and  CNT_P = (V_SYNC_P - 1)) then
                S_VS <= logic0;
            else
                S_VS <= S_VS;
            end if;
        end if;
    end process;

    VS <= not S_VS;
    v_act <= logic1 when (CNT_L <= (V_ACTIVE - 1)) else logic0;

    -- 文字 line カウンタ (CNT_LC)
    process(P_CLK)
    begin
        if (P_CLK = '1' and P_CLK'event) then
            if (v_act = logic1) then
                if (v_up = logic1) then
                    if (CNT_LC = (CNT_LC_MAX - 1)) then
                        CNT_LC <= (others => '0');
                    else
                        CNT_LC <= CNT_LC + '1';
                    end if;
                else
                    CNT_LC <= CNT_LC;
                end if;
            else
                CNT_LC <= (others => '0');
            end if;
        end if;
    end process;

    v_vact <= logic1 when (CNT_LC <= (V_VACTIVE - 1) and v_act = logic1) else logic0;

end Behavioral;
