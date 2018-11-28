----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    15:18:28 11/27/2018
-- Design Name:
-- Module Name:    tac_mmu - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tac_mmu is
    Port ( P_CLK : in  STD_LOGIC;
           P_RESET : in  STD_LOGIC;
           P_EN : in  STD_LOGIC;
           P_IOR : in  STD_LOGIC;
           P_IOW : in  STD_LOGIC;
           P_INT : out  STD_LOGIC;
           P_ADDR : in  STD_LOGIC;                              -- 仮想アドレス
	   P_MMU_ADDR : in  STD_LOGIC_VECTOR (15 downto 0);     -- I/O用アドレス
           P_DIN : in  STD_LOGIC_VECTOR (15 downto 0);          -- B,Lの値
           P_DOUT : out  STD_LOGIC_VECTOR (15 downto 0);        -- 物理アドレス
           P_B : out  STD_LOGIC_VECTOR (15 downto 0);           -- Bレジスタへの出力
           P_L : out  STD_LOGIC_VECTOR (15 downto 0));          -- Lレジスタへの出力
end tac_mmu;

architecture Behavioral of tac_mmu is
	signal i_b : STD_LOGIC_VECTOR (15 downto 0);
	signal i_l : STD_LOGIC_VECTOR (15 downto 0);

begin
	process(P_RESET, P_CLK)
		begin
			if (P_RESET='0') then
				i_b <= "0000000000000000";
				i_l <= "0000000000000000";
			elsif (P_CLK'event and P_CLK='1') then
				if (P_EN='1' and P_IOW='1') then
					if (P_ADDR='0') then
						i_b <= P_DIN;
					else
						i_l <= P_DIN;
					end if;
				end if;
			end if;
		end process;

	P_DOUT <= "0000000000000000"; -- 今のところ未設定
	P_B <= i_b;
	P_L <= i_l;
	P_INT <= '0'; -- 今のところ未設定

end Behavioral;
