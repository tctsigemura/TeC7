--
-- TeC16 VHDL Source Code
--
-- Charactor Generator
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity CharGene is
  port (
    P_CLK  : in std_logic;
    P_CODE : in  std_logic_vector(7 downto 0); -- 文字コード
    P_HEIGHT : in  std_logic_vector(3 downto 0); -- 高さ
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end CharGene;

architecture Behavioral of CharGene is

-- ROM
component CGROM1
  port (
    P_CLK  : in std_logic;
    P_ADDR : in  std_logic_vector(10 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end component;

component CGROM2
  port (
    P_CLK  : in std_logic;
    P_ADDR : in  std_logic_vector(10 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end component;

-- メモリに入力するアドレス
signal addr : std_logic_vector(10 downto 0);
-- メモリからの出力
signal code1 : std_logic_vector(7 downto 0);
signal code2 : std_logic_vector(7 downto 0);

begin

	addr <= P_CODE(6 downto 0) & P_HEIGHT(3 downto 0);
	-- ROM
	rom1: CGROM1
		port map (
			P_CLK  => P_CLK,
			P_ADDR => addr,
			P_DOUT => code1
		);
	rom2: CGROM2
		port map (
			P_CLK  => P_CLK,
			P_ADDR => addr ,
			P_DOUT => code2
		);
	
	P_DOUT <= code1 when P_CODE(7) = '0' else code2;
	
end Behavioral;
