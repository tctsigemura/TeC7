--
-- 8x16rk¥8x16rk.bin
--
-- フォントの著作権
-- Copyright 1989 by Sony Corp.
--
--
-- TeC16 VHDL Source Code
-- CharacterGeneratorROM
-- 00 〜 7F
--
library IEEE;
use IEEE.std_logic_1164.all;

entity CGROM1 is
  port (
    P_CLK  : in std_logic;
    P_ADDR : in  std_logic_vector(10 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end CGROM1;

architecture BEHAVE of CGROM1 is

  component RAMB16_S9
    -- pragma translate_off
    generic(
      WRITE_MODE : string := "READ_FIRST";
    );
    -- pragma translate_on
    port (
      WE   : in  std_logic;
      EN   : in  std_logic;
      SSR  : in  std_logic;
      CLK  : in  std_logic;
      ADDR : in  std_logic_vector(10 downto 0);
      DI   : in  std_logic_vector(7  downto 0);
      DIP  : in  std_logic_vector(0  downto 0);
      DO   : out std_logic_vector(7  downto 0);
      DOP  : out std_logic_vector(0  downto 0)
    );
  end component;

  attribute WRITE_MODE : string;
  attribute WRITE_MODE of rom0 : label is "READ_FIRST";

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
  
  attribute INIT_00 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "0000101038387c7cfefe7c7c3838101000000000000000000000000000000000";
  attribute INIT_01 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "0808080808083e00888888f88888880000009292444492924444929244449292";
  attribute INIT_02 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "2224283c22223c007088808080887000002020203c20203e808080f08080f800";
  attribute INIT_03 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "000000000000000000384444443800002020203c20203e00f880808080808000";
  attribute INIT_04 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "3e202020202020848c9494a4a4c48400000000fe0010101010fe101010100000";
  attribute INIT_05 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "00000000000000f010101010101010100008080808083e002050508888880000";
  attribute INIT_06 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "101010101010101f000000000000000010101010101010f00000000000000000";
  attribute INIT_07 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "10101010101010ff1010101010101010000000000000001f1010101010101010";
  attribute INIT_08 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "00000000000000000000ff000000000000000000000000000000000000ff0000";
  attribute INIT_09 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "00000000ff000000000000000000000000000000000000ff0000000000000000";
  attribute INIT_0a of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "101010101010101f101010101010101000ff0000000000000000000000000000";
  attribute INIT_0b of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "00000000000000ff101010101010101010101010101010f01010101010101010";
  attribute INIT_0c of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "1010101010101010101010101010101010101010101010ff0000000000000000";
  attribute INIT_0d of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "0000fe00fe80601806186080000000000000fe00fe020c30c0300c0200000000";
  attribute INIT_0e of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "000000804020fe10fe080402000000000000844424242424fe00000000000000";
  attribute INIT_0f of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
--    "000000000000001000000000000000000020523c10107c101010120c00000000";
 
  attribute INIT_10 of rom0 : label is
    "1038100000101010103838383838380000000000000000000000000000000000";
  attribute INIT_11 of rom0 : label is
    "0048484848fe24242424247f1212120000000000000000000000004824246c6c";
  attribute INIT_12 of rom0 : label is
    "808c525252322c1010689894949462021010789492d212143850909692543810";
  attribute INIT_13 of rom0 : label is
    "0000000000000000000000c02020e0e00000728c889454542e20504848483000";
  attribute INIT_14 of rom0 : label is
    "8040202010101010101010102020408002040808101010101010101008080402";
  attribute INIT_15 of rom0 : label is
    "0000000010101010fe1010101000000000000000103892d638d6923810000000";
  attribute INIT_16 of rom0 : label is
    "0000000000000000fe00000000000000c02020e0e00000000000000000000000";
  attribute INIT_17 of rom0 : label is
    "808040402020101010080808040402020040e0e0400000000000000000000000";
  attribute INIT_18 of rom0 : label is
    "00007c1010101010101010101070100000182424424242424242424224241800";
  attribute INIT_19 of rom0 : label is
    "0000384482820204380402828244380000007e42222010080804026242241800";
  attribute INIT_1a of rom0 : label is
    "0000384482c2020282c4b8808080fc0000003c080808fe888848482828180800";
  attribute INIT_1b of rom0 : label is
    "0010101010080808080404048282fe000000384482828282c4b8808046423c00";
  attribute INIT_1c of rom0 : label is
    "000038448202023a468282828244380000003844828282443844828282443800";
  attribute INIT_1d of rom0 : label is
    "3010183838000000003838000000000000003838000000000038380000000000";
  attribute INIT_1e of rom0 : label is
    "000000000000fe000000fe000000000002040408081010202010100808040402";
  attribute INIT_1f of rom0 : label is
    "1038100000101008040402c28244380080404020201010080810102020404080";
    
  attribute INIT_20 of rom0 : label is
    "0000c68282827c44444444282828100000003c42809aa6a2a2a2a69a82423c00";
  attribute INIT_21 of rom0 : label is
    "00003c42428280808080808042463a000000fc4242424244784442424244f800";
  attribute INIT_22 of rom0 : label is
    "0000fe4242424848784848404242fe000000f84444424242424242424444f800";
  attribute INIT_23 of rom0 : label is
    "00001a66428282828f80804042261a000000f04040404848784848404242fe00";
  attribute INIT_24 of rom0 : label is
    "0000fe1010101010101010101010fe000000e74242424242427e42424242e700";
  attribute INIT_25 of rom0 : label is
    "0000e34244444848507048484444e60000003844828282020202020202021f00";
  attribute INIT_26 of rom0 : label is
    "0000c682828282929292aaaaaac682000000fe4242424040404040404040f000";
  attribute INIT_27 of rom0 : label is
    "000038448282828282828282824438000000c2868a8a8a929292a2a2a2c28700";
  attribute INIT_28 of rom0 : label is
    "0608384444ba828282828282444438000000f04040404078444242424244f800";
  attribute INIT_29 of rom0 : label is
    "0000b8c48282820418608080844c34000000e34244444448784442424244f800";
  attribute INIT_2a of rom0 : label is
    "00003c4242424242424242424242e70000007c1010101010101010109292fe00";
  attribute INIT_2b of rom0 : label is
    "0000444444aaaaaa929292828282c6000000101028284444444482828282c600";
  attribute INIT_2c of rom0 : label is
    "00007c1010101010282844444482c6000000c68244442828281028284444ee00";
  attribute INIT_2d of rom0 : label is
    "1e10101010101010101010101010101e0000fe8242422020101010088884fe00";
  attribute INIT_2e of rom0 : label is
    "f01010101010101010101010101010f00000381010101010fe1028fe44448282";
  attribute INIT_2f of rom0 : label is
    "fe00000000000000000000000000000000000000000000000000000082442810";
 
  attribute INIT_30 of rom0 : label is
    "00007b868282423e02423c000000000000000000000000000000001020203030";
  attribute INIT_31 of rom0 : label is
    "00003c428280808082463a00000000000000784442424242424478404040c000";
  attribute INIT_32 of rom0 : label is
    "00003c42828080fe824438000000000000003e448484848484443c0404040600";
  attribute INIT_33 of rom0 : label is
    "7c8282847840384444443b000000000000007c10101010101010fe1010110e00";
  attribute INIT_34 of rom0 : label is
    "0000ff080808080808087800000018180000e7424242424242625c404040c000";
  attribute INIT_35 of rom0 : label is
    "0000e34242446458484442404040c000384482820202020202023e0000000606";
  attribute INIT_36 of rom0 : label is
    "0000db929292929292926c00000000000000ff08080808080808080808087800";
  attribute INIT_37 of rom0 : label is
    "000038448282828282443800000000000000e742424242424262dc0000000000";
  attribute INIT_38 of rom0 : label is
    "1e04043c4484848484443e0000000000f0404078444242424244f80000000000";
  attribute INIT_39 of rom0 : label is
    "0000bcc282023c4042463a00000000000000fc20202020202232ec0000000000";
  attribute INIT_3a of rom0 : label is
    "00003946424242424242c6000000000000001c22222020202020fc2020200000";
  attribute INIT_3b of rom0 : label is
    "0000444444aaaa92929292000000000000001028284444448282c60000000000";
  attribute INIT_3c of rom0 : label is
    "40a09010080814242242e700000000000000ee44282810282844ee0000000000";
  attribute INIT_3d of rom0 : label is
    "060808080808081020100808080808060000fe422210100808447e0000000000";
  attribute INIT_3e of rom0 : label is
    "c02020202020201008102020202020c010101010101010101010101010101010";
  attribute INIT_3f of rom0 : label is
    "00000000000000000000000000000000000000000000000000000000000c9260";
 
 
  signal logic0, logic1 : std_logic;
  signal addr11 : std_logic_vector(10 downto 0);
  signal data8  : std_logic_vector(7 downto 0);

  begin
    logic0 <= '0';
    logic1 <= '1';
    addr11 <= P_ADDR;
    data8  <= "00000000";

    rom0 : RAMB16_S9
    port map (
      DI  => data8,
      DIP => "0",
      ADDR => addr11,
      EN   => logic1,
      WE   => logic0,
      SSR  => logic0,
      CLK  => P_CLK,
      DO   => P_DOUT
    );
  end BEHAVE;
  
--
-- TeC16 VHDL Source Code
--
-- TeC16 CharacterGeneratorROM
-- 80 〜 FF
--

library IEEE;
use IEEE.std_logic_1164.all;

entity CGROM2 is
  port (
    P_CLK  : in std_logic;
    P_ADDR : in  std_logic_vector(10 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end CGROM2;

architecture BEHAVE of CGROM2 is

  component RAMB16_S9
    -- pragma translate_off
    generic(
      WRITE_MODE : string := "READ_FIRST";
    );
    -- pragma translate_on
    port (
      WE   : in  std_logic;
      EN   : in  std_logic;
      SSR  : in  std_logic;
      CLK  : in  std_logic;
      ADDR : in  std_logic_vector(10 downto 0);
      DI   : in  std_logic_vector(7  downto 0);
      DIP  : in  std_logic_vector(0  downto 0);
      DO   : out std_logic_vector(7  downto 0);
      DOP  : out std_logic_vector(0  downto 0)
    );
  end component;

  attribute WRITE_MODE : string;
  attribute WRITE_MODE of rom0 : label is "READ_FIRST";

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
  
  attribute INIT_00 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_01 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_02 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_03 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_04 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_05 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_06 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_07 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_08 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_09 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0a of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0b of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0c of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0d of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0e of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_0f of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
 
  attribute INIT_10 of rom0 : label is
    "2050502000000000000000000000000000000000000000000000000000000000";
  attribute INIT_11 of rom0 : label is
    "3c0404040404040404040404000000000000000010101010101010101010101e";
  attribute INIT_12 of rom0 : label is
    "0000000000000018180000000000000020204000000000000000000000000000";
  attribute INIT_13 of rom0 : label is
    "2030101010101416027e00000000000000003018080c0406027e0202027e0000";
  attribute INIT_14 of rom0 : label is
    "20100804040242427e1010000000000008080808086818080404020000000000";
  attribute INIT_15 of rom0 : label is
    "180848282818187e0808080000000000007e1010101010107c00000000000000";
  attribute INIT_16 of rom0 : label is
    "007e0808080808083800000000000000040404080848321a1622200000000000";
  attribute INIT_17 of rom0 : label is
    "201008080404224a5210000000000000003c0404043c0404043c000000000000";
  attribute INIT_18 of rom0 : label is
    "00402020101010101014141201ff000000000000000000003c00000000000000";
  attribute INIT_19 of rom0 : label is
    "0020100804040202424242427e10101000080808080808c82818080404020200";
  attribute INIT_1a of rom0 : label is
    "0018088848482828181808ff08080808000000ff10101010101010107e000000";
  attribute INIT_1b of rom0 : label is
    "040404040868380c13d0301816202020004e4222222212121212127e10101010";
  attribute INIT_1c of rom0 : label is
    "00201010080808048444443f202020200040201008080404442222121e101010";
  attribute INIT_1d of rom0 : label is
    "0020100808040424242424ff2424240000007e0202020202020202027e000000";
  attribute INIT_1e of rom0 : label is
    "008142222414180808040404047c000000402010080402226141001030200000";
  attribute INIT_1f of rom0 : label is
    "0020100808040404022222424242000000003e202020202024e2322e20202000";
    
  attribute INIT_20 of rom0 : label is
    "0040201010100808ff0808087804020000402010080804044a3222121e101010";
  attribute INIT_21 of rom0 : label is
    "004020101010080808ff0000007e0000002010080804040242525191a1200000";
  attribute INIT_22 of rom0 : label is
    "00402010101008080808ff080808080000101010101010121418101010101000";
  attribute INIT_23 of rom0 : label is
    "004020221214081828240402027e0000000000ff000000000000007e00000000";
  attribute INIT_24 of rom0 : label is
    "004020201010080808040404020200000010101010915234180804027e101010";
  attribute INIT_25 of rom0 : label is
    "00001e2040404040407048464040400000008141414222222222242424000000";
  attribute INIT_26 of rom0 : label is
    "00000001020284444848303020000000000040201008080404040202027e0000";
  attribute INIT_27 of rom0 : label is
    "000004040808181028040201ff0000000030109191525252541010ff10101000";
  attribute INIT_28 of rom0 : label is
    "000081724e2224242420101010101000000408102000000c1020000004182000";
  attribute INIT_29 of rom0 : label is
    "00001e1010101010fe101010107e00000080402022141c081824240402020200";
  attribute INIT_2a of rom0 : label is
    "000000ff04040404040404047c000000000808080808081012d2312d23202000";
  attribute INIT_2b of rom0 : label is
    "0020100804040202027e0000007e000000007e02020202027e020202027e0000";
  attribute INIT_2c of rom0 : label is
    "0000884c4a2a2929292828282828080000100804040402222222222222222200";
  attribute INIT_2d of rom0 : label is
    "0000007e42424242424242427e00000000003028242222212120202020200000";
  attribute INIT_2e of rom0 : label is
    "00004020100804040202011020400000000020100804040202024242427e0000";
  attribute INIT_2f of rom0 : label is
    "0000000000000000000000001028281000000000000000000000000000282828";
 
  attribute INIT_30 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_31 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_32 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_33 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_34 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_35 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_36 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_37 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_38 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_39 of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3a of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3b of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3c of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3d of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3e of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
  attribute INIT_3f of rom0 : label is
    "0000000000000000000000000000000000000000000000000000000000000000";
 
 
  signal logic0, logic1 : std_logic;
  signal addr11 : std_logic_vector(10 downto 0);
  signal data8  : std_logic_vector(7 downto 0);

  begin
    logic0 <= '0';
    logic1 <= '1';
    addr11 <= P_ADDR;
    data8  <= "00000000";

    rom0 : RAMB16_S9
    port map (
      DI  => data8,
      DIP => "0",
      ADDR => addr11,
      EN   => logic1,
      WE   => logic0,
      SSR  => logic0,
      CLK  => P_CLK,
      DO   => P_DOUT
    );
  end BEHAVE;
