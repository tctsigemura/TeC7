--
-- TaC VHDL Source Code
--    Tokuyama kousen Educational Computer 16 bit Version
--
-- Copyright (C) 2002-2012 by
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
--  TaC/tac_sio.vhd : RS-232C(シリアルパラレル変換モジュール)
--
-- 2012.01.22           : entity 名、見直し
-- 2010.07.20           : Subversion による管理を開始
--
-- $Id
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TAC_SIO is
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
end TAC_SIO;

-- 49.1520MHz / 9600 = 5120(0001 0100 0000 0000b)

architecture RTL of TAC_SIO is

-- Address Decode
signal IOW_SIO_Dat: std_logic;
signal IOR_SIO_Dat: std_logic;
signal IOW_SIO_Ctl: std_logic;
signal IOR_SIO_Sta: std_logic;

-- Registers
signal Tx_D_Reg   : std_logic_vector(7  downto 0);
signal Tx_S_Reg   : std_logic_vector(7  downto 0);
signal Tx_Out     : std_logic;
signal Tx_Full    : std_logic;
signal Tx_Ena     : std_logic;
signal Tx_Cnt1    : std_logic_vector(12 downto 0);
signal Tx_Cnt2    : std_logic_vector(3  downto 0);
signal Tx_Int_Ena : std_logic;

signal Rx_D_Reg   : std_logic_vector(7  downto 0);
signal Rx_S_Reg   : std_logic_vector(7  downto 0);
signal Rx_Full    : std_logic;
signal Rx_Ena     : std_logic;
signal Rx_Cnt1    : std_logic_vector(12 downto 0);
signal Rx_Cnt2    : std_logic_vector(3  downto 0);
signal Rx_Int_Ena : std_logic;

signal I_RxD1     : std_logic;
signal I_RxD2     : std_logic;

begin
    IOW_SIO_Dat <= P_IOW and  P_EN and not P_ADDR;
    IOR_SIO_Dat <= P_IOR and  P_EN and not P_ADDR;
    IOW_SIO_Ctl <= P_IOW and  P_EN and     P_ADDR;
    IOR_SIO_Sta <= P_IOR and  P_EN and     P_ADDR;

    P_TXD       <= Tx_Out or (not Tx_Ena);
    P_INT_TxD   <= (not Tx_Full) and Tx_Int_Ena;
    P_INT_RxD   <=      Rx_Full  and Rx_Int_Ena;

    -- Data Bus
    process (IOR_SIO_Dat, IOR_SIO_Sta, Rx_D_Reg, Tx_Full, Rx_Full)
    begin
        if (IOR_SIO_Dat='1') then
            P_DOUT    <= Rx_D_Reg;
        else
            if (IOR_SIO_Sta='1') then
                P_DOUT(7) <= not Tx_Full;
                P_DOUT(6) <=     Rx_Full;
            else
                P_DOUT(7) <= '0';
                P_DOUT(6) <= '0';
            end if;
            P_DOUT(5 downto 0) <= "000000";
        end if;
    end process;

    -- Ctl
    process (P_CLK, P_RESET)
    begin
        if (P_RESET='0') then
            Tx_Int_Ena <= '0';
            Rx_Int_Ena <= '0';
        elsif (P_CLK'event and P_CLK='1') then
            if (IOW_SIO_Ctl='1') then
                Tx_Int_Ena <= P_DIN(7);
                Rx_Int_Ena <= P_DIN(6);
            end if;
        end if;
    end process;

    -- Tx
    process (P_CLK, P_RESET)
    begin
        if (P_RESET='0') then
            Tx_D_Reg   <= "00000000";
            Tx_Full    <= '0';
        elsif (P_CLK' event and P_CLK='1') then
            if (IOW_SIO_Dat='1') then
                Tx_D_Reg <= P_DIN;
                Tx_Full  <= '1';
            elsif (Tx_Ena='0') then
                Tx_Full  <= '0';
            end if;
        end if;
     end process;

     process (P_CLK, P_RESET)
     begin
         if (P_RESET='0') then
             Tx_S_Reg   <= "00000000";
             Tx_Out     <= '0';
             Tx_Ena     <= '0';
             Tx_Cnt1    <= "0000000000000";
             Tx_Cnt2    <= "0000";
         elsif (P_CLK' event and P_CLK='1') then
             if (Tx_Ena='1') then
                 if (Tx_Cnt1="1010000000000") then
                     Tx_OUT               <= Tx_S_Reg(0);
                     Tx_S_Reg(6 downto 0) <= Tx_S_Reg(7 downto 1);
                     Tx_S_Reg(7)          <= '1';
                     Tx_Cnt1              <= "0000000000000";
                     if (Tx_Cnt2="1001") then
                         Tx_Ena           <= '0';
                         Tx_Cnt2          <= "0000";
                     else
                         Tx_Cnt2          <= Tx_Cnt2 + 1;
                     end if;
                 else
                     Tx_Cnt1              <= Tx_Cnt1 + 1;
                 end if;
             elsif (Tx_Full='1') then
                 Tx_S_Reg <= Tx_D_Reg;
                 Tx_Out   <= '0';
                 Tx_Ena   <= '1';
                 Tx_Cnt1  <= "0000000000000";
             end if;
         end if;
     end process;

    -- Rx
     process (P_CLK, P_RESET)
     begin
         if (P_RESET='0') then
             Rx_Full  <= '0';
             I_RxD1   <= '0';
             I_RxD2   <= '0';
         elsif (P_CLK'event and P_CLK='1') then
             I_RxD1   <= P_RxD;
             I_RxD2   <= I_RxD1;

             if (Rx_Cnt1="0101000000000" and Rx_Cnt2="1001") then
                 Rx_Full <= '1';
             elsif (IOR_SIO_Dat='1') then
                 Rx_Full <= '0';
             end if;
         end if;
     end process;

     process (P_CLK, P_RESET)
     begin
         if (P_RESET='0') then
             Rx_D_Reg <= "00000000";
             Rx_S_Reg <= "00000000";
             Rx_Ena   <= '0';
             Rx_Cnt1  <= "0000000000000";
             Rx_Cnt2  <= "0000";
         elsif (P_CLK'event and P_CLK='1') then
             if (Rx_Ena='1') then
                 if (Rx_Cnt1="0101000000000") then
                     Rx_S_Reg(6 downto 0) <= Rx_S_Reg(7 downto 1);
                     Rx_S_Reg(7)          <= I_RxD2;
                     if (Rx_Cnt2="0000" and I_RxD2='1') then
                         Rx_Ena           <= '0';
                         Rx_Cnt2          <= "0000";
                     elsif (Rx_Cnt2="1001") then
                         Rx_Ena           <= '0';
                         Rx_D_Reg         <= Rx_S_Reg;
                         Rx_Cnt2          <= "0000";
                     else
                         Rx_Cnt2          <= Rx_Cnt2 + 1;
                     end if;
                 end if;
                 if (Rx_Cnt1="1010000000000") then
                   Rx_Cnt1 <= "0000000000000";
                 else
                   Rx_Cnt1 <= Rx_Cnt1 + 1;
                 end if;
             elsif (I_RxD1='0' and I_RxD2='1') then
                 Rx_Ena  <= '1';
                 Rx_Cnt1 <= "0000000000000";
             end if;
         end if;
     end process;

end RTL;
