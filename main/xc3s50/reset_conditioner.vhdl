library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--
-- the reset_conditioner module accepts the raw 'reset' signal and the clock. it outputs
-- 'conditioned_reset' which will be '1' while 'reset' has been '1' for at least 6 clock ticks
--

entity reset_conditioner is
  port(
    clk100            : in  std_logic;
    reset             : in  std_logic;
    conditioned_reset : out  std_logic
  );
end reset_conditioner;

architecture behavioral of reset_conditioner is

  signal sreg_i : std_logic_vector(5 downto 0) := (others => '0');
  signal conditioned_reset_i : std_logic := '0';

begin

  -- register the output
  
  conditioned_reset <= conditioned_reset_i;

  -- this process uses a shift register to keep a short history of consecutive
  -- reset states. when we've seen reset continually high for 6 cycles then
  -- we'll consider it done.
  
  conditioner : process(clk100) is
  begin

    if rising_edge(clk100) then
    
      if sreg_i = "111111" then
        conditioned_reset_i <= '1';
      else
        conditioned_reset_i <= '0';
      end if;
      
      -- shift in the new state on the right
      
      sreg_i <= sreg_i(4 downto 0) & reset;
    
    end if;

  end process conditioner;

end behavioral;
