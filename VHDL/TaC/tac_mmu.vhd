--
-- TeC7 VHDL Source Code
--    Tokuyama kousen Educational Computer Ver.7
--
-- Copyright (C) 2012-2018 by
--                      Dept. of Computer Science and Electronic Engineering,
--                      Tokuyama College of Technology, JAPAN
--
--   上記著作権而Free Software Foundation によって公開されてあ� GNU 一般公
-- 衈�用許諾契紛�バ�ジョン�に記述されてあ�条件を満たす場合に限り�本ソース
-- コー�本ソースコードを改変したものを含む�以下同�を使用・褣�・改変�再�
-- 币�ることを無償で許諾する
--
--   本ソースコード��く�無保証�で提供されるも�である。上記著作権老�よ�
-- 関連機関・個人は本ソースコードに関して�その適用可能性も含�て�いかなる保証
-- も行わなぼ�また，本ソースコード�利用により直接皁�た�間接皁�生じたいかな
-- る損害に関しても，その責任を�わなぼ
--
--

--
-- TaC/tac_mmu.vhd : TaC MMU
--
-- 2018.11.27           : 新規作�
--
-- $Id
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity tac_mmu is
  Port (
    P_CLK : in  STD_LOGIC;
    P_RESET : in  STD_LOGIC;
    P_EN : in  STD_LOGIC;
    P_IOR : in  STD_LOGIC;
    P_IOW : in  STD_LOGIC;
    P_INT : out  STD_LOGIC;
    P_IO_ADDR : in  STD_LOGIC;                           -- 仮想アドレス
    P_MMU_ADDR : out  STD_LOGIC_VECTOR (15 downto 0);    -- I/O用アドレス
    P_ADDR : in  STD_LOGIC_VECTOR (15 downto 0);         -- 
    P_DIN : in  STD_LOGIC_VECTOR (15 downto 0);          -- B,Lの値
    P_B : out  STD_LOGIC_VECTOR (15 downto 0);           -- Bレジスタへの出�
    P_L : out  STD_LOGIC_VECTOR (15 downto 0)            -- Lレジスタへの出�
  );
end tac_mmu;

architecture Behavioral of tac_mmu is
signal i_b : STD_LOGIC_VECTOR (15 downto 0);             -- 
signal i_l : STD_LOGIC_VECTOR (15 downto 0);             -- 
signal i_addr : STD_LOGIC_VECTOR (15 downto 0);          -- 

begin
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_b <= "0000000000000000";
      i_l <= "0000000000000000";
    elsif (P_CLK'event and P_CLK='1') then
      if (P_EN='1' and P_IOW='1') then
        if (P_IO_ADDR='0') then
          i_b <= P_DIN;
        else
          i_l <= P_DIN;
        end if;
      end if;
    end if;
  end process;

  P_B <= i_b;
  P_L <= i_l;
  i_addr <= P_ADDR;
  P_MMU_ADDR <= i_addr;
  P_INT <= '0'; -- 今�ところ未設�

end Behavioral;
