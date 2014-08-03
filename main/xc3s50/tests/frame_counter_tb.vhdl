library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;


entity frame_counter_tb is
end frame_counter_tb;

architecture behavior of frame_counter_tb is 

  component frame_counter is
  port(
    -- inputs
      
    clk100 : in std_logic;
    reset  : in std_logic;
    lcd_te : in std_logic;
      
    -- outputs
    
    frame_index : out std_logic
  );
  end component;

  -- inputs
  
  signal clk100 : std_logic := '0';
  signal reset : std_logic := '0';
  signal lcd_te : std_logic := '0';
  
  -- outputs
    
  signal frame_index : std_logic := '0';
  
  -- constants
  
  constant clk100_period : time := 10ns;
  
begin

  uut : frame_counter port map (
    
    clk100 => clk100,
    reset => reset,
    lcd_te => lcd_te,
    
    frame_index => frame_index
  );

  clk_process : process
  begin
    clk100 <= '0';
    wait for clk100_period/2;
    clk100 <= '1';
    wait for clk100_period/2;
  end process;
  
  stim_proc : process
  begin

    -- reset the unit
    
    reset <= '1';
    wait for 20ns;
    reset <= '0';
    wait for 20ns;
    
    assert frame_index = '0' report "expected frame index to be set to zero after reset";
    
    -- a single spike on TE that lasts for one clock should not update the counter
    
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '0';

    assert frame_index ='0' report "expected frame_index to remain at zero during spike";
    
    -- now generate a signal that is long enough to trigger it

    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '0';
    wait until clk100 = '0'; wait until clk100 = '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '0';
    
    wait until clk100 = '0'; wait until clk100 = '1';
    wait until clk100 = '0';
    
    assert frame_index = '1' report "expected frame index to increase based on acceptable TE signal";
    
    wait for 50ns;
    
    -- now generate another acceptable signal and check that frame_index goes back to zero
    
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '0';
    wait until clk100 = '0'; wait until clk100 = '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    wait until clk100 = '0'; wait until clk100 = '1';
    lcd_te <= '0';
    
    wait until clk100 = '0'; wait until clk100 = '1';
    wait until clk100 = '0';
    
    assert frame_index = '0' report "expected frame index to zero based on acceptable TE signal";

    wait;
    
  end process;

end architecture;

