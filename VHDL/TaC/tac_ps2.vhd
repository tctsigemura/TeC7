--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2012 by
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
-- TaC/tac_ps2.vhd : TaC PS/2 interface
--
-- 2012.01.22           : entity 名、見直し
-- 2012.01.20           : 野村君のコードを取り込み
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity TAC_PS2 is
    Port (
      P_CLK     : in std_logic;                       -- 50MHz
      P_RESET   : in std_logic;                       -- Reset    
      P_IOW     : in std_logic;                       -- I/O Write
      P_IOR     : in std_logic;                       -- I/O Read
      P_EN      : in std_logic;                       -- Enable
      P_ADDR    : in std_logic;                       -- Address
      P_DOUT    : out std_logic_vector(7 downto 0);   -- Data Output
      P_DIN     : in std_logic_vector(7 downto 0);    -- Data Input
      P_PS2D    : inout std_logic;                    -- PS/2 Data
      P_PS2C    : inout std_logic;                    -- PS/2 Clock
      P_INT_W   : out std_logic;                      -- PS/2 送信割り込み
      P_INT_R   : out std_logic                       -- PS/2 受信割り込み
    );
end TAC_PS2;

architecture Behavioral of TAC_PS2 is

signal PS2D_host : std_logic;

-- 50M Hz クロック と PS2C の 同期
signal PS2C_buf : std_logic_vector(1 downto 0);       -- 前回と今回のPS2Cの値

-- Address Decode
signal IOW_PS2_Dat  : std_logic;                      -- Write Data
signal IOR_PS2_Dat  : std_logic;                      -- Read Data
signal IOW_PS2_Ctl  : std_logic;                      -- Control (Write)
signal IOR_PS2_Sta  : std_logic;                      -- Status (Read)


-- デバイスからの受信用
signal R_D_Reg      : std_logic_vector(7 downto 0);
signal R_S_Reg      : std_logic_vector(7 downto 0);   -- シフトレジスタ
signal R_Full       : std_logic;                      -- 受信完了 = 1
signal R_Ena        : std_logic;                      -- Read Enable
signal R_Int_Ena    : std_logic;                      -- 割り込み許可
signal R_bitcnt     : std_logic_vector(3 downto 0);   -- 受信ビットカウンタ
signal R_WaitCnt    : std_logic_vector(12 downto 0);
signal R_Parity     : std_logic;

-- デバイスへの送信用
signal W_D_Reg      : std_logic_vector(7 downto 0);
signal W_S_Reg      : std_logic_vector(7 downto 0);   -- シフトレジスタ
signal W_Full       : std_logic;                      -- 送信完了 = 0
signal W_Ena        : std_logic;                      -- Write Enable
signal W_Int_Ena    : std_logic;                      -- 割り込み許可
signal W_bitcnt     : std_logic_vector(3 downto 0);   -- 送信ビットカウンタ
signal W_State      : std_logic_vector( 1 downto 0 );
signal W_Wait_Cnt   : std_logic_vector(12 downto 0);
signal W_Parity     : std_logic;

begin
    P_PS2C <= '0' when ( W_Ena = '1' and W_State = "00" ) else 'Z' ;
    P_PS2D <= '0' when ( PS2D_host = '0' and W_Ena = '1' and
                            W_State = "01" and W_bitcnt<10 ) else 'Z' ;
    
    IOW_PS2_Dat <= P_IOW    and P_EN and not P_ADDR;
    IOR_PS2_Dat <= P_IOR    and P_EN and not P_ADDR;
    IOW_PS2_Ctl <= P_IOW    and P_EN and     P_ADDR;
    IOR_PS2_Sta <= P_IOR    and P_EN and     P_ADDR;

    P_INT_W <= (not W_Full) and W_Int_Ena;
    P_INT_R <=      R_Full  and R_Int_Ena;

    -- Data Bus
    process(IOR_PS2_Dat , IOR_PS2_Sta , R_D_Reg , W_Full , R_Full )
    begin
        if( IOR_PS2_Dat = '1' ) then
            P_DOUT <= R_D_Reg;
        else
            if( IOR_PS2_Sta = '1' ) then
                P_DOUT(7) <= not W_Full;
                P_DOUT(6) <=     R_Full;
            else
                P_DOUT(7) <= '0';
                P_DOUT(6) <= '0';
            end if;
            P_DOUT(5 downto 0) <= "000000";
        end if;
    end process;
    
    -- Ctl
    process(P_CLK, P_RESET)
    begin
        if(P_RESET = '0' ) then
            W_Int_Ena <= '0';
            R_Int_Ena <= '0';
        elsif(P_CLK'event and P_CLK = '1') then
            if( IOW_PS2_Ctl = '1' ) then    
                W_Int_Ena <= P_DIN(7);  
                R_Int_Ena <= P_DIN(6);
            end if;
        end if;
    end process;
    
    -- 2つのクロック間で同期をとる
    process(P_CLK , P_RESET)
    begin
        if(P_RESET = '0' ) then
            PS2C_buf <= "11";
        elsif(P_CLK'event and P_CLK = '1') then
            PS2C_buf <=  P_PS2C & PS2C_buf(1);
        end if;
    end process;
    
    
    -- Write (送信)
    process(P_CLK, P_RESET)
    begin
        if( P_RESET = '0' ) then
            W_Full  <= '0';
            W_D_Reg <= "00000000";
        elsif( P_CLK'event and P_CLK='1' ) then
            if( IOW_PS2_Dat = '1' ) then
                W_D_Reg <= P_DIN;
                W_Full <= '1';
            elsif( W_Ena = '0' ) then
                W_Full <= '0';
            end if;
        end if;
    end process;
    
    process(P_CLK, P_RESET)
    begin
        if( P_RESET = '0' ) then
            W_State <= "00";
            W_Ena       <= '0';
            W_Wait_Cnt <= "0000000000000";
            W_bitcnt <= "0000";
            PS2D_host <= '0';
            W_S_Reg <= "00000000";
            W_Parity <= '1';
        elsif( P_CLK'event and P_CLK = '1' ) then
            if( W_Ena = '1' ) then
                -- 出力
                case W_State is
                    when "00" =>
                        if( W_Wait_Cnt = 5010 ) then
                            -- 100usec以上待った後
                            -- 送信 要求
                            W_State <= "01";
                        else
                            W_Wait_Cnt <= W_Wait_Cnt + '1';
                        end if;
                    when "01" =>
                        if( PS2C_buf = "01" ) then  -- ネガティブエッジ
                            if( W_bitcnt < 8 ) then
                                PS2D_host <= W_S_Reg(0); -- データ出力
                                -- パリティ計算
                                W_Parity <= W_Parity xor W_S_Reg(0);
                                W_S_Reg <= '0' & W_S_Reg(7 downto 1);
                            elsif( W_bitcnt = 8 ) then
                                -- パリティ ビット 送信
                                PS2D_host <= W_Parity;
                            elsif( W_bitcnt = 9 ) then
                                PS2D_host <= 'Z';
                            else
                                if( P_PS2D = '0' ) then
                                    -- ACK
                                    W_State <= "10";
                                end if;
                            end if;
                            W_bitcnt <= W_bitcnt + '1';
                        end if;
                    when others =>
                        if( P_PS2D = '1' ) then
                            -- 送信 終了
                            W_Ena <= '0';
                        end if;
                    end case;
            elsif( W_Full = '1' ) then
                W_Ena <= '1';
                W_State <= "00";
                W_S_Reg <= W_D_Reg;
                W_Parity <= '1';
                W_Wait_Cnt <= "0000000000000";
                W_bitcnt <= "0000";
                PS2D_host <= '0';
            end if;
        end if;
    end process;
    
    -- Read (受信)
    process(P_CLK, P_RESET)
    begin
        if( P_RESET = '0' ) then
            R_Full      <= '0';
            R_D_Reg <= "00000000";
            R_WaitCnt <= "0000000000000";
        elsif( P_CLK'event and P_CLK = '1' ) then
            if( PS2C_buf = "01" and R_bitcnt = "1000" and
                R_WaitCnt > 5009 and R_Parity = P_PS2D ) then
                -- パリティ が 正しい
                R_Full <= '1';
                R_D_Reg <= R_S_Reg;
                R_WaitCnt <= "0000000000000";
            elsif( IOR_PS2_Dat = '1' ) then
                R_Full <= '0';
            elsif( R_WaitCnt < 5010 ) then
                R_WaitCnt <= R_WaitCnt + '1';
            end if;
        end if;
    end process;
        
    process(P_RESET, P_CLK)
    begin
        if( P_RESET = '0' ) then
            R_S_Reg <= "00000000";
            R_Ena <= '0';
            R_bitcnt <= "0000";
        elsif( P_CLK = '1' and P_CLK'event ) then
            if( W_Ena = '1' ) then
                R_Ena <= '0';
                R_bitcnt <= "0000";
            elsif( PS2C_buf = "01" ) then   -- ネガティブ エッジ
                -- 受信 処理
                if( R_Ena = '1' ) then
                    if( R_bitcnt < 8 ) then
                        -- シフトレジスタにデータ入力
                        R_S_Reg(7 downto 0) <= P_PS2D & R_S_Reg(7 downto 1);
                        R_Parity <= R_Parity xor P_PS2D; -- パリティ計算
                        R_bitcnt <= R_bitcnt + '1';
                    else
                        -- 受信 終了
                        R_Ena <= '0';
                        R_bitcnt <= "0000";
                    end if;
                elsif( P_PS2D = '0') then
                    -- 受信 開始
                    R_Ena <= '1';
                    R_bitcnt <= "0000";
                    R_Parity <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;
