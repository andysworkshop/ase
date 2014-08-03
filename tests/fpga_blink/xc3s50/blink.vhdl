-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
 
entity blink is
port(
  clk     : in  std_logic;
  led_out : out std_logic
);
end blink;

architecture behavioural of blink is
 constant clock_count : natural := 80000000;      -- 2x clock frequency in Hz
begin

  process(clk)
    variable count : natural range 0 to clock_count;
  begin

    -- for half the time led_out = 0 and 1 for the other half

    if rising_edge(clk) then
      if count < clock_count/2 then
        led_out <='1';
        count := count + 1;
      elsif count < clock_count then
        led_out <='0';
        count := count + 1;
      else
        count := 0;
        led_out <='1';
      end if;
    end if;
  end process; 

end behavioural;
