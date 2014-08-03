-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;


-- mcu_interface is a state machine used to sample a sequence of inputs from the
-- connected MCU. A command is a single byte followed by a command-dependent sequence
-- of data bytes. The protocol follows the popular 8080 interface where a normally
-- high WR line is pulsed low then high to trigger a transfer. Commands are
-- executed asynchronously to the bus reader via a 64-entry FIFO.

entity mcu_interface is

  port(
    
    -- inputs
    
    clk100          : in std_logic;           -- 100Mhz clock
    reset           : in std_logic;           -- synchronous reset
    mcu_data        : in mcu_bus_t;           -- 10-bit MCU data bus
    mcu_wr          : in std_logic;           -- MCU write signal
    bram_dout       : in sprite_record_t;     -- data output from the BRAM
    lcd_sender_busy : in boolean;
    
    -- outputs
    
    lcd_rs          : out std_logic;          -- desired RS state when passthrough
    lcd_sender_go   : out std_logic;          -- trigger for starting lcd_sender
    lcd_sender_data : out lcd_data_t;         -- desired data when in passthrough
    bram_wr         : out std_logic;          -- WR line for BRAM writing
    bram_addr       : out sprite_number_t;    -- address to read/write in BRAM
    bram_din        : out sprite_record_t;    -- data to write to BRAM
    mode            : out mode_t;             -- the current mode selection (default passthrough)

    debug           : out std_logic           -- internal debug flag (normally NC)
    
--pragma synthesis_off
    ;
    state_out_sim : out mcu_interface_state_t
--pragma synthesis_on
  );

end mcu_interface;

architecture behavioral of mcu_interface is

  --
  -- FIFO for incoming MCU data
  --

  component command_fifo
    port (
      clk   : in std_logic;
      srst  : in std_logic;
      din   : in std_logic_vector(9 downto 0);
      wr_en : in std_logic;
      rd_en : in std_logic;
      dout  : out std_logic_vector(9 downto 0);
      full  : out std_logic;
      empty : out std_logic
    );
  end component;

  signal state_i : mcu_interface_state_t := undefined;
  signal mode_i : mode_t := mode_passthrough;
  signal mcu_wr_sreg_i : std_logic_vector(1 to 3) := (others => '1');
  signal mcu_wr_last_state_i : std_logic := '1';
  signal lcd_sender_data_i : std_logic_vector(15 downto 0);
  signal lcd_sender_go_i : std_logic := '0';
  signal lcd_rs_i : std_logic := '0';
  signal cmd_flag_i : std_logic;
  signal bram_addr_i : sprite_number_t := (others => '0');
  signal bram_din_i : sprite_record_t;
  signal bram_wr_i : std_logic := '0';
  signal firstx_i,lastx_i : sprite_width_t;
  signal firsty_i,lasty_i : sprite_height_t;
  signal sprite_number_i : sprite_number_t;
  signal sram_start_i : sram_pixel_addr_t;
  signal visible_i : std_logic;
  signal data_ready_i : boolean := false;
  signal move_partial_i : boolean := false;

  signal fifo_write_state_i : fifo_writer_state_t := idle;
  signal fifo_read_state_i : fifo_reader_state_t := idle;
  signal fifo_din_i : mcu_bus_t;
  signal fifo_dout_i : mcu_bus_t;
  signal fifo_data_i : mcu_bus_t;
  signal fifo_wr_i : std_logic := '0';
  signal fifo_rd_i : std_logic := '0';
  signal fifo_empty_i : std_logic;
  signal fifo_full_i : std_logic;

  signal debug_i : std_logic := '0';
  
begin

  -- register the outputs
  
  lcd_rs <= lcd_rs_i;
  lcd_sender_data <= lcd_sender_data_i;
  lcd_sender_go <= lcd_sender_go_i;
  bram_wr <= bram_wr_i;
  bram_addr <= bram_addr_i;
  bram_din <= bram_din_i;
  mode <= mode_i;

  debug <= debug_i;

--pragma synthesis_off

  state_out_sim <= state_i;

--pragma synthesis_on

  --
  -- declare the command fifo
  --

  inst_command_fifo : command_fifo port map (
    clk   => clk100,
    srst  => reset,
    din   => fifo_din_i,
    wr_en => fifo_wr_i,
    rd_en => fifo_rd_i,
    dout  => fifo_dout_i,
    full  => fifo_full_i,
    empty => fifo_empty_i
  );


  --
  -- take data from the MCU bus and write to the FIFO
  --

  process(clk100,reset)
  begin

    if rising_edge(clk100) then

      if reset = '1' then

        -- reset the status of the WR shift register

        mcu_wr_sreg_i <= (others => '0');
        mcu_wr_last_state_i <= '1';

      else

        case fifo_write_state_i is

          when idle =>
            
            if mcu_wr_sreg_i(2) = '1' and mcu_wr_sreg_i(3) = '0' then
              
              -- rising edge of WR
            
              mcu_wr_last_state_i <= '1';

              if fifo_full_i = '0' and mcu_wr_last_state_i='0' then
              
                -- falling -> rising and there is space in the FIFO
                
                fifo_din_i <= mcu_data;
                fifo_write_state_i <= write_0;
              
              end if;

            elsif mcu_wr_sreg_i(3) = '1' and mcu_wr_sreg_i(2) = '0' then

              -- falling edge of WR
              
              mcu_wr_last_state_i <= '0';

            end if;

          when write_0 =>

            -- trigger a FIFO write

            fifo_wr_i <= '1';
            fifo_write_state_i <= write_1;

          when write_1 =>

            -- reset the FIFO write flag and go back to waiting for more data

            fifo_wr_i <= '0';
            fifo_write_state_i <= idle;

        end case;

        -- shift in the current state of the strobe
        
        mcu_wr_sreg_i <= mcu_wr & mcu_wr_sreg_i(1 to 2);

      end if;
        
    end if;

  end process;

  --
  -- handle the interaction with data coming from the mcu via the fifo
  --
  
  process(clk100,reset)
  begin
  
    if rising_edge(clk100) then

      if reset = '1' then
      
        -- reset the state machine

        state_i <= passthrough_0;
        mode_i <= mode_passthrough;
        
      else

        -- default values
        
        bram_wr_i <= '0';

        -- process the execute states
        
        case state_i is

          -- hold here until the lcd sender has finished
          
          when passthrough_2 =>
            
            if lcd_sender_busy = false then
              state_i <= passthrough_0;
            end if;

          -- show(sprite) and hide(sprite) command
          -- hold for one cycle

          when execute_showhide_0 =>
            state_i <= execute_showhide_1;

          -- flip to writing and set the data

          when execute_showhide_1 =>    
            bram_din_i <= bram_dout;
            bram_din_i.visible <= cmd_flag_i;
            bram_wr_i <= '1';
            state_i <= execute_showhide_2;

          -- hold the write for another cycle
          
          when execute_showhide_2 =>    
            bram_wr_i <= '1';
            state_i <= reading_cmd;
  --pragma synthesis_off
            REPORT "CMD_SHOW/HIDE: sprite = " & hstr(bram_addr_i) & " visible = " & std_logic'image(cmd_flag_i);
  --pragma synthesis_on

          when execute_load_sprite_0 =>
            bram_wr_i <= '1';
            state_i <= execute_load_sprite_1;

          when execute_load_sprite_1 =>         -- hold the write for this clock and we're done
            bram_wr_i <= '1';
            state_i <= reading_cmd;
  --pragma synthesis_off
            REPORT "CMD_LOAD: sprite = " & hstr(sprite_number_i) &
                   " flash_addr = " & hstr(bram_din_i.flash_addr) &
                   " sram_start = " & hstr(bram_din_i.sram_addr) &
                   " px size = " & hstr(bram_din_i.size) & 
                   " width = " & hstr(bram_din_i.width) &
                   " rep_x = " & hstr(bram_din_i.repeat_x) &
                   " rep_y = " & hstr(bram_din_i.repeat_y) &
                   " visible = " & std_logic'image(bram_din_i.visible) &
                   " firstx = " & hstr(bram_din_i.firstx) &
                   " lastx = " & hstr(bram_din_i.lastx) &
                   " firsty = " & hstr(bram_din_i.firsty) &
                   " lasty = " & hstr(bram_din_i.lasty);
  --pragma synthesis_on
                   
          when execute_move_0 =>          -- need to hold for a cycle
            bram_addr_i <= sprite_number_i;
            state_i <= execute_move_1;
            
          when execute_move_1 =>          -- flip to writing and set the data
            bram_din_i <= bram_dout;
            bram_din_i.sram_addr <= sram_start_i;
            bram_din_i.visible <= '1';
            bram_wr_i <= '1';
            state_i <= execute_move_2;

          when execute_move_2 =>          -- hold the write for another cycle
             bram_wr_i <= '1';
             state_i <= reading_cmd;

  -- pragma synthesis_off
            REPORT "CMD_MOVE: sprite = " & hstr(sprite_number_i) &
                   " sram_start = " & hstr(sram_start_i);
  -- pragma synthesis_on

          when execute_move_partial_0 =>          -- need to hold for a cycle
            bram_addr_i <= sprite_number_i;
            state_i <= execute_move_partial_1;
            
          when execute_move_partial_1 =>          -- flip to writing and set the data
            bram_din_i <= bram_dout;
            bram_din_i.sram_addr <= sram_start_i;
            bram_din_i.visible <= '1';
            bram_din_i.firstx <= firstx_i;
            bram_din_i.lastx <= lastx_i;
            bram_din_i.firsty <= firsty_i;
            bram_din_i.lasty <= lasty_i;
            bram_wr_i <= '1';
            state_i <= execute_move_2;

  -- pragma synthesis_off
            REPORT "CMD_MOVE (partial): " &
                   " firstx = " & hstr(firstx_i) &
                   " lastx = " & hstr(lastx_i) &
                   " firsty = " & hstr(firsty_i) &
                   " lasty = " & hstr(lasty_i);
  -- pragma synthesis_on
            
          when others =>

            -- all the other states rely data being made ready

            if data_ready_i then

              -- clear for next tick

              data_ready_i <= false;

              -- process the data we got on this tick

              case state_i is

                -- reading first 8 bits or the escape to sprite mode
                
                when passthrough_0 =>
                  
                  if fifo_data_i(fifo_data_i'left) = '1' then
                    mode_i <= mode_sprite;
                    state_i <= reading_cmd;
                  else
                    lcd_sender_data_i(7 downto 0) <= fifo_data_i(7 downto 0);
                    state_i <= passthrough_1;
                  end if;

                -- reading last 8 bits and RS and trigger the command
                
                when passthrough_1 =>         
      
                  lcd_rs_i <= fifo_data_i(fifo_data_i'left);
                  lcd_sender_data_i(15 downto 8) <= fifo_data_i(7 downto 0);
                  lcd_sender_go_i <= not lcd_sender_go_i;
                  state_i <= passthrough_2;
              
                -- move the state to act on the command received
              
                when reading_cmd =>

                  case fifo_data_i(7 downto 0) is

                    -- switch to passthrough mode
                    
                    when CMD_PASSTHROUGH =>
                      mode_i <= mode_passthrough;
                      state_i <= passthrough_0;
                  
                    -- show a sprite (1 read)
                    -- params: sprite(9)
                    
                    when CMD_SHOW =>
                      cmd_flag_i <= '1';
                      state_i <= reading_showhide_sprite;
                    
                    -- hide a sprite (1 read)
                    -- params: sprite(9)
                    
                    when CMD_HIDE =>
                      cmd_flag_i <= '0';
                      state_i <= reading_showhide_sprite;

                    -- load a full sprite (11 reads)
                    -- params: sprite(9),x(9),y(10),width(9),pixel_size(18),flash_start(24),rep_x(9),rep_y(10),flags(1)
                    
                    when CMD_LOAD =>
                      state_i <= reading_load_sprite_number;
                    
                    -- move a sprite and make it visible
                    -- params: sprite(9), x(9), y(10)
                    
                    when CMD_MOVE =>
                      move_partial_i <= to_boolean(fifo_data_i(fifo_data_i'left));
                      state_i <= reading_move_sprite;

                    when others =>
                      null;

                  end case;

                -- read the sprite number for the show command
                  
                when reading_showhide_sprite =>
                  bram_addr_i <= fifo_data_i(bram_addr_i'left downto 0);
                  state_i <= execute_showhide_0;

                -- read the parameters for the move command
                
                when reading_move_sprite =>
                  sprite_number_i <= fifo_data_i(sprite_number_i'left downto 0);
                  state_i <= reading_move_addr_low;
                  
                when reading_move_addr_low =>              -- lower 10 bits
                  sram_start_i(9 downto 0) <= fifo_data_i;
                  bram_addr_i <= sprite_number_i;          -- start the read out
                  state_i <= reading_move_addr_high;
                  
                when reading_move_addr_high =>
                  sram_start_i(17 downto 10) <= fifo_data_i(7 downto 0);

                  -- flag that says the partial information is present

                  if move_partial_i then
                    state_i <= reading_move_first_x;
                  else
                    state_i <= execute_move_0;
                  end if;

                -- read the parameters for the move partial command
                
                when reading_move_first_x =>
                  firstx_i <= fifo_data_i(firstx_i'left downto 0);
                  state_i <= reading_move_last_x;

                when reading_move_last_x =>
                  lastx_i <= fifo_data_i(lastx_i'left downto 0);
                  state_i <= reading_move_first_y;

                when reading_move_first_y =>
                  firsty_i <= fifo_data_i(firsty_i'left downto 0);
                  state_i <= reading_move_last_y;

                when reading_move_last_y =>
                  lasty_i <= fifo_data_i(lasty_i'left downto 0);
                  state_i <= execute_move_partial_0;

                -- read all the parameters for the load command
                
                when reading_load_sprite_number =>     -- read the sprite number
                  bram_addr_i <= fifo_data_i(sprite_number_i'left downto 0);
                  state_i <= reading_load_sprite_addr_low;
                  
                when reading_load_sprite_addr_low => 
                  bram_din_i.sram_addr(9 downto 0) <= fifo_data_i;
                  state_i <= reading_load_sprite_addr_high;
                  
                when reading_load_sprite_addr_high =>
                  bram_din_i.sram_addr(17 downto 10) <= fifo_data_i(7 downto 0);
                  state_i <= reading_load_sprite_width;
                  
                when reading_load_sprite_width =>
                  bram_din_i.width <= fifo_data_i(bram_din_i.width'left downto 0);
                  state_i <= reading_load_sprite_pixel_size_low;
                  
                when reading_load_sprite_pixel_size_low =>      
                  bram_din_i.size(fifo_data_i'left downto 0) <= fifo_data_i;
                  state_i <= reading_load_sprite_pixel_size_high;
                  
                when reading_load_sprite_pixel_size_high =>
                  bram_din_i.size(bram_din_i.size'left downto fifo_data_i'left+1) <= fifo_data_i(bram_din_i.size'left-fifo_data_i'left-1 downto 0);
                  state_i <= reading_load_sprite_flash_addr_low;
                  
                when reading_load_sprite_flash_addr_low =>
                  bram_din_i.flash_addr(7 downto 0) <= fifo_data_i(7 downto 0);
                  state_i <= reading_load_sprite_flash_addr_mid;

                when reading_load_sprite_flash_addr_mid =>
                  bram_din_i.flash_addr(15 downto 8) <= fifo_data_i(7 downto 0);
                  state_i <= reading_load_sprite_flash_addr_high;

                when reading_load_sprite_flash_addr_high =>
                  bram_din_i.flash_addr(23 downto 16) <= fifo_data_i(7 downto 0);
                  state_i <= reading_load_sprite_repeat_x;
                
                when reading_load_sprite_repeat_x =>
                  bram_din_i.repeat_x <= fifo_data_i(bram_din_i.repeat_x'left downto 0);
                  state_i <= reading_load_sprite_repeat_y;

                when reading_load_sprite_repeat_y =>
                  bram_din_i.repeat_y <= fifo_data_i(bram_din_i.repeat_y'left downto 0);
                  state_i <= reading_load_sprite_visible;
                
                when reading_load_sprite_visible =>
                  bram_din_i.visible <= fifo_data_i(0);
                  state_i <= reading_load_sprite_first_x;

                when reading_load_sprite_first_x =>
                  bram_din_i.firstx <= fifo_data_i(bram_din_i.firstx'left downto 0);
                  state_i <= reading_load_sprite_last_x;

                when reading_load_sprite_last_x =>
                  bram_din_i.lastx <= fifo_data_i(bram_din_i.lastx'left downto 0);
                  state_i <= reading_load_sprite_first_y;

                when reading_load_sprite_first_y =>
                  bram_din_i.firsty <= fifo_data_i(bram_din_i.firsty'left downto 0);
                  state_i <= reading_load_sprite_last_y;

                when reading_load_sprite_last_y =>
                  bram_din_i.lasty <= fifo_data_i(bram_din_i.lasty'left downto 0);
                  state_i <= execute_load_sprite_0;

                when others =>
                  null;
                  
              end case;
              
            else
              
              -- data is not ready, monitor the state of the FIFO

              case fifo_read_state_i is

                when idle =>

                  -- if the FIFO is not empty the set its read flag

                  if fifo_empty_i = '0' then
                    fifo_rd_i <= '1';
                    fifo_read_state_i <= read_0;
                  end if;

                when read_0 =>

                  -- reset the read flag

                  fifo_rd_i <= '0';
                  fifo_read_state_i <= read_1;

                when read_1 =>

                  -- capture the data read from the FIFO and set the data_ready flag so we can
                  -- start processing it on the next clock
                  
                  fifo_data_i <= fifo_dout_i;
                  data_ready_i <= true;          
                  fifo_read_state_i <= idle;

                end case;

            end if;
                
        end case;

      end if;

    end if;
      
  end process;
  
end architecture behavioral;

