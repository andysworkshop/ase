-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

use work.constants.all;
use work.functions.all;


--
-- manage ownership of the LCD bi-directional data bus. mode_passthrough
-- grants ownership to lcd_sender and mode_sprite grants access to frame_writer
--

entity lcd_arbiter is

  port(
  
  	-- inputs

  	clk100 : in std_logic;               -- 100MHz clock
  	mode   : in mode_t;                  -- mode_sprite or mode_passthrough

    lcd_sender_db  : in lcd_bus_t;       -- lcd_sender's desired data bus
    lcd_sender_wr  : in std_logic;       -- lcd_sender's desired WR flag
    lcd_sender_ale : in std_logic;       -- lcd_sender's ALE flag
    lcd_sender_rs  : in std_logic;       -- lcd_sender's RS signal

    frame_writer_db  : in lcd_bus_t;      -- frame_writer's desired data bus
    frame_writer_wr  : in std_logic;      -- frame_writer's WR flag
    frame_writer_ale : in std_logic;      -- frame_writer's ALE flag

    -- outputs

    lcd_db  : out lcd_bus_t;            -- the selected data for the LCD bus
    lcd_wr  : out std_logic;            -- the selected LCD WR signal
    lcd_ale : out std_logic;            -- the selected ALE signal  
    lcd_rs  : out std_logic             -- the selected RS signal
  );

end lcd_arbiter;

architecture behavioral of lcd_arbiter is

begin

  process(clk100) is
  begin
    
  	if rising_edge(clk100) then
    
      -- make the output selection based on the current mode

      if mode = mode_passthrough then
 
        lcd_db <= lcd_sender_db;
        lcd_wr <= lcd_sender_wr;
        lcd_ale <= lcd_sender_ale;
        lcd_rs <= lcd_sender_rs;
 
      else
 
        lcd_db <= frame_writer_db;
        lcd_wr <= frame_writer_wr;
        lcd_ale <= frame_writer_ale;
        lcd_rs <= '1';                    -- frame_writer is always sending data

      end if;

    end if;

  end process;

end behavioral;
