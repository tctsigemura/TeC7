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
    P_MMU_RW : in  STD_LOGIC;
    P_EXE_MODE : in  STD_LOGIC;
    P_INT : out  STD_LOGIC;
    P_RW : out  STD_LOGIC;
    P_IO_ADDR : in  STD_LOGIC;                           -- I/O address (i_addr(1))
    P_ADDR : out  STD_LOGIC_VECTOR (15 downto 0);         -- Virtual address
    P_MMU_ADDR : in  STD_LOGIC_VECTOR (15 downto 0);     -- Physical address
    P_DIN : in  STD_LOGIC_VECTOR (15 downto 0)           -- B,L register (input)
  );
end tac_mmu;

architecture Behavioral of tac_mmu is
signal i_rw : STD_LOGIC ;
signal i_intr : STD_LOGIC ;
signal i_b : STD_LOGIC_VECTOR (15 downto 0);             -- B register
signal i_l : STD_LOGIC_VECTOR (15 downto 0);             -- L register
signal i_addr : STD_LOGIC_VECTOR (15 downto 0);          -- Calculation register

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
  
  i_intr <= '0' when (P_MMU_ADDR >= i_l)
            else '1' ;
  i_addr <= P_MMU_ADDR;
  P_ADDR <= i_addr; -- not yet undefined
  P_INT <= '0'; -- not yet undefined

end Behavioral;
