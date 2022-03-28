--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2002-2011 by
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
-- TeC Microcode
--
library IEEE;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_textio.all;

entity TEC_DROM is
  port (
    P_CLK  : in std_logic;
    P_RESET: in std_logic;
    P_ADDR : in  std_logic_vector(7 downto 0);
    P_DOUT : out std_logic_vector(7 downto 0)
  );
end TEC_DROM;

architecture BEHAVE of TEC_DROM is
  subtype word is std_logic_vector(7 downto 0);
  type memory is array(0 to 255) of word;
  function read_file (fname : in string) return memory is
    file data_in : text is in fname;
    variable line_in: line;
    variable ram : memory;
    begin
      for i in 0 to 255 loop
        readline (data_in, line_in);
		  read(line_in, ram(i));
      end loop;
      return ram;
    end function;
  signal mem : memory := read_file("tec_drom.txt");

  begin		
	 process(P_CLK, P_RESET)
	   begin
		  if (P_RESET='0') then
		    P_DOUT <= "00000000";
		  elsif (P_CLK'event and P_CLK='0') then
	       P_DOUT <= mem( conv_integer(P_ADDR) );
		  end if;
		end process;
  end BEHAVE;
