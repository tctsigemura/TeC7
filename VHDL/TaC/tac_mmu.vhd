library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

--use IEEE.NUMERIC_STD.ALL;
--library UNISIM;
--use UNISIM.VComponents.all;

entity TAC_MMU is
  Port (
    P_CLK : in  STD_LOGIC;
    P_RESET : in  STD_LOGIC;
    P_EN : in  STD_LOGIC;
    P_IOW : in  STD_LOGIC;
    P_MMU_MR : in  STD_LOGIC;
    P_PR : in  STD_LOGIC;                          -- Execution mode (0:user, 1:privilege)
    P_INT : out  STD_LOGIC;
    P_MR : out  STD_LOGIC;
    P_ADDR : out  STD_LOGIC_VECTOR (15 downto 0);        -- Physical address
    P_MMU_ADDR : in  STD_LOGIC_VECTOR (15 downto 0);     -- Virtual address, P_MMU_ADDR(1):I/O address
    P_DIN : in  STD_LOGIC_VECTOR (15 downto 0)           -- B,L register (input)
  );
end TAC_MMU;

architecture Behavioral of TAC_MMU is
signal i_mr   : STD_LOGIC ;
signal i_intr : STD_LOGIC ;
signal i_b    : STD_LOGIC_VECTOR (15 downto 0);    -- B register
signal i_l    : STD_LOGIC_VECTOR (15 downto 0);    -- L register
signal i_addr : STD_LOGIC_VECTOR (15 downto 0);    -- for Physical address　calculation

begin
  process(P_RESET, P_CLK)
  begin
    if (P_RESET='0') then
      i_b <= "0000000000000000";
      i_l <= "0000000000000000";
    elsif (P_CLK'event and P_CLK='1') then
      if (P_EN='1' and P_IOW='1') then
        if (P_MMU_ADDR(1)='0') then
          i_b <= P_DIN;
        else
          i_l <= P_DIN;
        end if;
      end if;
    end if;
  end process;
  
  i_addr <= (P_MMU_ADDR + i_b) when (P_PR = '1') and (P_MMU_MR = '1')            -- 加算機能
            else P_MMU_ADDR ;                                              
  i_intr <= '1' when ((P_MMU_ADDR >= i_l) and (P_PR = '0') and (P_MMU_MR = '1')) -- 比較機能
            else '0' ;
  i_mr <= P_MMU_MR and (not i_intr);
  P_ADDR <= i_addr;
  P_INT <= i_intr;
  P_MR <= i_mr;
  
end Behavioral;
