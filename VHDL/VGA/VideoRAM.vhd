--
-- TeC16 VHDL Source Code
--
-- VideoRAM
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity VideoRAM is
    Port (	   P_CLKA   : in std_logic;
		   P_EN : in std_logic;
		   P_ADDRA : in std_logic_vector(10 downto 0);
		   P_DOUTA : out std_logic_vector(7 downto 0);
		   
		   P_CLKB : in std_logic;
		   P_WE : in std_logic;
		   P_ADDRB : in std_logic_vector(10 downto 0);
		   P_DIN : in std_logic_vector(7 downto 0);
		   P_DOUTB : out std_logic_vector(7 downto 0)
	   );
end VideoRAM;


architecture Behavioral of VideoRAM is


-- VRAM
component RAMB16_S9_S9
-- pragma translate_off
generic(
	WRITE_MODE : string := "READ_FIRST";
);
-- pragma translate_on
port (
	 WEA   : in  std_logic;
	 ENA   : in  std_logic;
	 SSRA  : in  std_logic;
	 CLKA  : in  std_logic;
	 ADDRA : in  std_logic_vector(10 downto 0);
	 DIA   : in  std_logic_vector(7  downto 0);
	 DIPA  : in  std_logic_vector(0  downto 0);
	 DOA   : out std_logic_vector(7  downto 0);
	 DOPA  : out std_logic_vector(0  downto 0);
	 
	 WEB   : in  std_logic;
	 ENB   : in  std_logic;
	 SSRB  : in  std_logic;
	 CLKB  : in  std_logic;
	 ADDRB : in  std_logic_vector(10 downto 0);
	 DIB   : in  std_logic_vector(7  downto 0);
	 DIPB  : in  std_logic_vector(0  downto 0);
	 DOB   : out std_logic_vector(7  downto 0);
	 DOPB  : out std_logic_vector(0  downto 0)
);
end component;

attribute WRITE_MODE : string;
-- attribute WRITE_MODE of ram : label is "READ_FIRST";
 
  attribute INIT_00 : string;
  attribute INIT_01 : string;
  attribute INIT_02 : string;
  attribute INIT_03 : string;
  attribute INIT_04 : string;
  attribute INIT_05 : string;
  attribute INIT_06 : string;
  attribute INIT_07 : string;
  attribute INIT_08 : string;
  attribute INIT_09 : string;
  attribute INIT_0a : string;
  attribute INIT_0b : string;
  attribute INIT_0c : string;
  attribute INIT_0d : string;
  attribute INIT_0e : string;
  attribute INIT_0f : string;
  
  attribute INIT_10 : string;
  attribute INIT_11 : string;
  attribute INIT_12 : string;
  attribute INIT_13 : string;
  attribute INIT_14 : string;
  attribute INIT_15 : string;
  attribute INIT_16 : string;
  attribute INIT_17 : string;
  attribute INIT_18 : string;
  attribute INIT_19 : string;
  attribute INIT_1a : string;
  attribute INIT_1b : string;
  attribute INIT_1c : string;
  attribute INIT_1d : string;
  attribute INIT_1e : string;
  attribute INIT_1f : string;
  
  attribute INIT_20 : string;
  attribute INIT_21 : string;
  attribute INIT_22 : string;
  attribute INIT_23 : string;
  attribute INIT_24 : string;
  attribute INIT_25 : string;
  attribute INIT_26 : string;
  attribute INIT_27 : string;
  attribute INIT_28 : string;
  attribute INIT_29 : string;
  attribute INIT_2a : string;
  attribute INIT_2b : string;
  attribute INIT_2c : string;
  attribute INIT_2d : string;
  attribute INIT_2e : string;
  attribute INIT_2f : string;
  
  attribute INIT_30 : string;
  attribute INIT_31 : string;
  attribute INIT_32 : string;
  attribute INIT_33 : string;
  attribute INIT_34 : string;
  attribute INIT_35 : string;
  attribute INIT_36 : string;
  attribute INIT_37 : string;
  attribute INIT_38 : string;
  attribute INIT_39 : string;
  attribute INIT_3a : string;
  attribute INIT_3b : string;
  attribute INIT_3c : string;
  attribute INIT_3d : string;
  attribute INIT_3e : string;
  attribute INIT_3f : string;
  

  attribute INIT_00 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "1f1e1d1c1b1a191817161514131211100f0e0d0c0b0a09080706050403020100";
  attribute INIT_01 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "3f3e3d3c3b3a393837363534333231302f2e2d2c2b2a29282726252423222120";
  attribute INIT_02 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "5f5e5d5c5b5a595857565554535251504f4e4d4c4b4a49484746454443424140";
  attribute INIT_03 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "7f7e7d7c7b7a797877767574737271706f6e6d6c6b6a69686766656463626160";
  attribute INIT_04 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "9f9e9d9c9b9a999897969594939291908f8e8d8c8b8a89888786858483828180";
  attribute INIT_05 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "bfbebdbcbbbab9b8b7b6b5b4b3b2b1b0afaeadacabaaa9a8a7a6a5a4a3a2a1a0";
  attribute INIT_06 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "dfdedddcdbdad9d8d7d6d5d4d3d2d1d0cfcecdcccbcac9c8c7c6c5c4c3c2c1c0";
  attribute INIT_07 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "fffefdfcfbfaf9f8f7f6f5f4f3f2f1f0efeeedecebeae9e8e7e6e5e4e3e2e1e0";
  attribute INIT_08 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_09 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0a of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0b of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0c of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0d of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0e of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0f of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
 
  attribute INIT_10 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_11 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_12 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_13 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_14 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_15 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_16 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_17 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_18 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_19 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_1a of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_1b of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_1c of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_1d of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_1e of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_1f of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
    
  attribute INIT_20 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_21 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_22 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_23 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_24 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_25 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_26 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_27 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_28 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_29 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_2a of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_2b of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_2c of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_2d of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_2e of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_2f of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
 
  attribute INIT_30 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_31 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_32 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_33 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_34 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_35 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_36 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_37 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_38 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_39 of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3a of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3b of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3c of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3d of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3e of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3f of ram : label is
    "0000000000000000000000000000000000000000000000000000000000000000";

signal logic0, logic1 : std_logic;

  
begin
    logic0 <= '0';
    logic1 <= '1';

	-- VRAM
    ram : RAMB16_S9_S9
    port map (
      DIA  => "00000000",
      DIPA => "0",
      ADDRA => P_ADDRA,
      ENA   => P_EN,
      WEA   => logic0,
      SSRA  => logic0,
      CLKA  => P_CLKA,
      DOA   => P_DOUTA,
      DOPA => open,
	 
      DIB  => P_DIN,
      DIPB => "0",
      ADDRB => P_ADDRB,
      ENB   => logic1,
      WEB   => P_WE,
      SSRB  => logic0,
      CLKB  => P_CLKB,
      DOB   => P_DOUTB,
      DOPB => open
    );
end Behavioral;

