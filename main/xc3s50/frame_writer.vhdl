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


-- frame_writer transfers data from SRAM to the LCD. The setting of the display
-- window to full screen and the issue of the LCDs 'begin write data' command has
-- already happened when the mode was switched to 'sprite'

entity frame_writer is

  port(
  
  	-- inputs

  	reset       : in std_logic;      -- synchronous reset
  	clk100      : in std_logic;      -- 100MHz clock
  	mode        : in mode_t;         -- sprite/passthrough mode
  	frame_index : in std_logic;      -- 0/1 frame index
  	sram_data   : in sram_data_t;    -- data read out from SRAM

  	-- outputs

  	lcd_wr   : out std_logic;           -- write strobe
  	lcd_db   : out lcd_bus_t;           -- 8 bit data bus (latched)
  	lcd_ale  : out std_logic;           -- latch enable

  	sram_addr : out sram_byte_addr_t;   -- address of data to get from SRAM

    debug : out std_logic               -- internal debugging (usually NC)

  --pragma synthesis_off
  	;
  	state_out_sim : out frame_writer_state_t
  --pragma synthesis_on
  );

end frame_writer;

architecture behavioral of frame_writer is

  signal last_frame_index_i : std_logic := '0';
  signal state_i            : frame_writer_state_t := undefined;
  signal lcd_wr_i           : std_logic := '0';
  signal lcd_ale_i          : std_logic := '0';
  signal lcd_db_i           : lcd_bus_t;
  signal sram_addr_i        : sram_byte_addr_t := (others => '0');
  signal size_i             : sprite_size_t := (others => '0');
  signal pixel_b0_i         : sram_data_t := (others => '0');
  signal pixel_b1_i         : sram_data_t := (others => '0');
  signal debug_i            : std_logic := '0';

begin

  -- register the outputs

  lcd_db <= lcd_db_i;
  lcd_ale <= lcd_ale_i;
  lcd_wr <= lcd_wr_i;
  sram_addr <= sram_addr_i;
  debug <= debug_i;

--pragma synthesis_off
  state_out_sim <= state_i;
--pragma synthesis_on

  process(clk100,reset) is
  begin
  
  	if rising_edge(clk100) then

  	  reset_cond: if reset = '1' then
  		  state_i <= idle;
  	  else 
  	  
    		case state_i is
    		
    		  -- if we're in sprite mode and we're leaving the sprite writer phase then we can start
    		  
    		  when idle =>
    			
            -- keep SRAM address at zero ready for starting

            sram_addr_i <= (others => '0');

            -- move to the starting state when the frame index rolls over to zero
            -- and we're in sprite mode

      			if mode = mode_sprite and last_frame_index_i = '1' and frame_index = '0' then
              state_i <= pre_0;
      			end if;

          when pre_0 =>
            state_i <= pre_1;     -- hold addr for a cycle (probably OTT for this state)

          -- pre_* stage reads pixel #0 from SRAM. SRAM reading is one clock
          -- ahead of the writing

          when pre_1 =>

            -- the pixel data IOBs are arranged in an order on the package that makes PCB routing straightforward.

            pixel_b0_i(7) <= sram_data(0);
            pixel_b0_i(6) <= sram_data(2);
            pixel_b0_i(5) <= sram_data(4);
            pixel_b0_i(4) <= sram_data(6);
            pixel_b1_i(3) <= sram_data(7);
            pixel_b1_i(2) <= sram_data(5);
            pixel_b1_i(1) <= sram_data(3);
            pixel_b1_i(0) <= sram_data(1);

            -- move to the next address, which is always one

            sram_addr_i <= "0000000000000000001";
            state_i <= pre_2;

          when pre_2 =>
            state_i <= pre_3;         -- hold addr for a cycle

          when pre_3 =>
            
            -- get the other half of the pixel from SRAM

            pixel_b0_i(3) <= sram_data(0);
            pixel_b0_i(2) <= sram_data(2);
            pixel_b0_i(1) <= sram_data(4);
            pixel_b0_i(0) <= sram_data(6);
            pixel_b1_i(7) <= sram_data(7);
            pixel_b1_i(6) <= sram_data(5);
            pixel_b1_i(5) <= sram_data(3);
            pixel_b1_i(4) <= sram_data(1);

            -- start counting pixels as we're ready to go into the main loop

            size_i <= (others => '0');
            state_i <= state_0;

          -- now we're primed to go into the writing loop

          when state_0 =>
            
            -- write out the last pixel data byte(0) with the latch transparent

            lcd_db_i <= pixel_b0_i;
            lcd_wr_i <= '0';
            lcd_ale_i <= '1';

            -- move to reading the next SRAM address

            sram_addr_i <= sram_byte_addr_t(unsigned(sram_addr_i)+1);
            state_i <= state_10;

          when state_10 =>

            -- freeze the latch

            lcd_ale_i <= '0';
            state_i <= state_20;

          when state_20 =>

            -- write out the pixel data byte(1) around the latch

            lcd_db_i <= pixel_b1_i;

            -- get the next byte from SRAM

            pixel_b0_i(7) <= sram_data(0);
            pixel_b0_i(6) <= sram_data(2);
            pixel_b0_i(5) <= sram_data(4);
            pixel_b0_i(4) <= sram_data(6);
            pixel_b1_i(3) <= sram_data(7);
            pixel_b1_i(2) <= sram_data(5);
            pixel_b1_i(1) <= sram_data(3);
            pixel_b1_i(0) <= sram_data(1);

            -- advance SRAM to the next address

            sram_addr_i <= sram_byte_addr_t(unsigned(sram_addr_i)+1);
            state_i <= state_30;

          when state_30 =>

            -- pause for data to arrive on SRAM

            state_i <= state_40;

          when state_40 =>

            -- read out the next SRAM byte

            pixel_b0_i(3) <= sram_data(0);
            pixel_b0_i(2) <= sram_data(2);
            pixel_b0_i(1) <= sram_data(4);
            pixel_b0_i(0) <= sram_data(6);
            pixel_b1_i(7) <= sram_data(7);
            pixel_b1_i(6) <= sram_data(5);
            pixel_b1_i(5) <= sram_data(3);
            pixel_b1_i(4) <= sram_data(1);

            -- WR now goes high, triggering the LCD to read the data bus

            lcd_wr_i <= '1';
            state_i <= state_50;

          when state_50 =>

            -- increment the pixels counter

            size_i <= sprite_size_t(unsigned(size_i)+1);
            state_i <= state_60;

          when state_60 =>

            -- get out when all pixels are done or go back for the next one

            if size_i = NUM_PIXELS then
              state_i <= idle;
            else
              state_i <= state_0;
            end if;

    		  when others => 
            null;
    		
    		end case;
    	  
        -- always store the last frame index on the every clock tick
        
  		  last_frame_index_i <= frame_index;
  	  
  	  end if reset_cond;

  	end if;
    
  end process;

end behavioral;
