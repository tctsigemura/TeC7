--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2018 by
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
-- TaC/tac_fifo.vhd : FIFO
--
-- 2018.07.13           : 一応の完成
-- 2018.04.02           : 初期バージョン
--
-- $Id
--

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;
--use ieee.numeric_std.all;
use ieee.math_real.all;

entity TAC_FIFO is
  generic (
    width     : integer :=8;
    depth     : integer :=15;
    threshold : integer :=7
    );
  port (
    P_CLK   : in  std_logic;
    P_RESET : in  std_logic;

    P_FULL  : out std_logic;
    P_WRITE : in  std_logic;
    P_DIN   : in  std_logic_vector(width-1 downto 0);

    P_EMPTY : out std_logic;
    P_READ  : in  std_logic;
    P_DOUT  : out std_logic_vector(width-1 downto 0)
  );
end TAC_FIFO;

architecture BEHAVE of TAC_FIFO is
  constant ptrW : integer := integer(ceil(log2(real(depth))));
  constant cntW : integer := integer(ceil(log2(real(depth+1))));

  subtype Word is std_logic_vector(width-1 downto 0);
  type Fifo is array(0 to depth-1) of Word;
  signal i_buf   : Fifo;

  signal i_cnt   : std_logic_vector(cntW-1 downto 0);
  signal i_wPtr  : std_logic_vector(ptrW-1 downto 0);
  signal i_rPtr  : std_logic_vector(ptrW-1 downto 0);
  signal i_empty : std_logic;
  signal i_write : std_logic;
  signal i_read  : std_logic;

begin
  i_empty <= '1' when (i_cnt = 0) else '0';
  P_EMPTY <= i_empty;
  P_FULL  <= '1' when (i_cnt >= threshold) else '0';
  P_DOUT  <= i_buf(conv_integer(i_rPtr));
  i_write <= P_WRITE when (i_cnt /= depth) else '0';
  i_read  <= P_READ  and not i_empty;

  -- i_cnt
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_cnt  <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      if (i_read='1' and i_write='0') then
        i_cnt <= i_cnt - 1;
      elsif (i_read='0' and i_write='1') then
        i_cnt <= i_cnt + 1;
      end if;
    end if;
  end process;

  -- i_wPtr
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_wPtr <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      if (i_write='1') then
        i_buf(conv_integer(i_wPtr)) <= P_DIN;
        if (i_wPtr /= depth-1) then
          i_wPtr <= i_wPtr + 1;
        else
          i_wPtr <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  -- i_rPtr
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_rPtr <= (others => '0');
    elsif (P_CLK'event and P_CLK='1') then
      if (i_read='1') then
        if (i_rPtr /= depth-1) then
          i_rPtr <= i_rPtr + 1;
        else
          i_rPtr <= (others => '0');
        end if;
      end if;
    end if;
  end process;

end BEHAVE;
