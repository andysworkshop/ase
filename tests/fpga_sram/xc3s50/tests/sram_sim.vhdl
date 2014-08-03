-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- simple simulator for asynchronous 8-bit static ram. doesn't attempt to model
-- the setup and hold parameters and assumes the read signal (noe) is always zero.
--

entity sram_sim is
  generic(
    addr_width : integer
  );
  port(
    addr : in std_logic_vector(addr_width-1 downto 0);     -- 19 bit address bus
    data : inout std_logic_vector(7 downto 0);   -- 8 bit data bus
    nwr  : in std_logic                          -- write enable
  );
end sram_sim;

architecture behavioural of sram_sim is
  type ram_type is array (0 to (2**addr_width)-1) of std_logic_vector(7 downto 0);
  signal ram : ram_type;
  signal data_out_i : std_logic_vector(7 downto 0);
begin

  -- arbitration for the tristate

  data <= data_out_i when (nwr = '1') else (others => 'Z');

  -- write process

  process(addr,data,nwr)
  begin
    if nwr = '0' then
      ram(to_integer(unsigned(addr))) <= data;
    end if;
  end process;

  -- read process

  process(addr,nwr,ram) 
  begin
    if nwr = '1' then
      data_out_i <= ram(to_integer(unsigned(addr)));
    end if;
  end process;

end behavioural;
