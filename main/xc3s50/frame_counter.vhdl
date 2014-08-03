-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;


--
-- frame_counter toggles a 0/1 counter each time the TE signal is positively asserted high
--

entity frame_counter is
  port(
    
    -- inputs
      
    clk100 : in std_logic;        -- 100MHz clock
    reset  : in std_logic;        -- synchronous reset
    lcd_te : in std_logic;        -- TE signal from the LCD
      
    -- outputs
    
    frame_index : out std_logic   -- 0/1 frame index
  );
end entity frame_counter;

architecture behavioural of frame_counter is

  signal frame_index_i : std_logic := '0';
  signal lcd_te_sreg_i : std_logic_vector(1 to 3) := (others => '0');  
  
begin

  -- register the output

  frame_index <= frame_index_i;

  process(clk100,reset) is
  begin
  
    if rising_edge(clk100) then
    
      if reset = '1' then

        -- set the frame index back to zero and clear the shift register

        frame_index_i <= '0';
        lcd_te_sreg_i <= (others => '0');
      
      else
        
        -- if TE is definitely asserted then advance a frame
        
        if lcd_te_sreg_i(2) = '1' and lcd_te_sreg_i(3) = '0' then
          frame_index_i <= not frame_index_i;
        end if;

        -- shift the register to the left and shift in the current state
        
        lcd_te_sreg_i <= lcd_te & lcd_te_sreg_i(1 to 2);
    
      end if;
    
    end if;
    
  end process;

end architecture behavioural;
