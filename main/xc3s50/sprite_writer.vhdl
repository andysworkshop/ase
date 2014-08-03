library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

use work.constants.all;
use work.functions.all;


-- sprite_writer makes a pass through the BRAM sprite records and transfers each visible sprite
-- from flash to SRAM. SRAM is not cleared down so there should usually be enough sprites to fill
-- the background.

entity sprite_writer is

  port(
    
    -- inputs
    
    reset         : in  std_logic;              -- synchronous reset
    clk100        : in  std_logic;              -- 100MHz clock
    clk100_inv    : in  std_logic;              -- 100MHz clock phase inverted
    mode          : in  mode_t;                 -- sprite or passthrough mode
    frame_index   : in  std_logic;              -- current frame index (0/1)
    flash_io_in   : in  flash_io_bus_t;         -- data that we read from the flash
    bram_dout     : in  sprite_record_t;        -- data that we read from BRAM port B

    -- outputs
    
    sram_addr     : out sram_byte_addr_t;       -- the SRAM address we want to write to
    sram_data     : out sram_data_t;            -- the data we want to write to SRAM
    sram_nwr      : out std_logic;              -- the SRAM write flag
    flash_ncs     : out std_logic;              -- the flash chip select
    flash_io_out  : out flash_io_bus_t;         -- command data to write to flash
    flash_io_mode : out flash_io_mode_t;        -- how we're operating the flash
    flash_clk     : out std_logic;              -- the 100MHz flash clock
    bram_addr     : out sprite_number_t;        -- the BRAM address on port B
    bram_en_mcu_interface : out std_logic;      -- BRAM EN signal on port A
    bram_en_sprite_writer : out std_logic;      -- BRAM EN signal on port B
    busy          : out boolean;                -- our busy signal (goes out to a pin)
    debug         : out std_logic               -- debug signal (normally NC)

--pragma synthesis_off
    ;
    state_out_sim       : out sprite_writer_state_t;
    last_pixel_out_sim  : out pixel_t;
    sprite_size_out_sim : out sprite_size_t;
    sram_next_x_out_sim : out sram_byte_addr_t
--pragma synthesis_on
  );

end sprite_writer;

architecture behavioral of sprite_writer is

  --
  -- the adder that gets us the next sprite start in SRAM
  --

  component sram_addr_adder port (
    a   : in sram_byte_addr_t;
    b   : in byte_width_t;
    clk : in std_logic;
    s   : out sram_byte_addr_t
  );
  end component;

  --
  -- the adder that gets us the next sprite x start
  --

  component nextx_adder port (
    a   : in sprite_width_t;
    b   : in sprite_width_t;
    clk : in std_logic;
    s   : out sprite_width_t
  );
  end component;

  signal last_frame_index_i  : std_logic := '0';
  signal frame_index_i       : std_logic;
  signal flash_clk_ce_i      : std_logic := '0';
  signal state_i             : sprite_writer_state_t := undefined;
  signal flash_ncs_i         : std_logic := '1';
  signal flash_io_out_i      : flash_io_bus_t;
  signal flash_io_mode_i     : flash_io_mode_t := reading;
  signal sprite_number_i     : sprite_number_t := (others => '0');
  signal sprite_record_i     : sprite_record_t;
  
  signal sram_adder_a_i   : sram_byte_addr_t;
  signal sram_adder_b_i   : byte_width_t;
  signal sram_adder_sum_i : sram_byte_addr_t;
  signal sram_org_i       : sram_byte_addr_t;
  signal sram_next_x_i    : sram_byte_addr_t;
  signal sram_addr_i      : sram_byte_addr_t;
  signal sram_data_i      : sram_data_t;
  signal sram_nwr_i       : std_logic := SRAM_READ;

  signal sprite_width_i    : sprite_width_t;
  signal sprite_size_i     : sprite_size_t;
  signal sprite_repeat_y_i : sprite_height_t;
  signal last_pixel_i      : pixel_t;
  signal pixel_i           : std_logic_vector(15 downto 4);   -- last 4 bits transferred direct to last_pixel_i from flash bus
  signal first_in_column_i : boolean;

  signal xok_i,yok_i : boolean;
  signal xok_reset_i : boolean;
  signal x_i,xorg_i,nextx_i : sprite_width_t;
  signal y_i : sprite_height_t;
  signal nextx_adder_a_i : sprite_width_t;
  signal nextx_adder_b_i : sprite_width_t;
  signal nextx_adder_sum_i : sprite_width_t;

  signal bram_addr_i : sprite_number_t;
  signal bram_en_mcu_interface_i : std_logic;
  signal bram_en_sprite_writer_i : std_logic;

  signal busy_i : boolean;
  signal debug_i : std_logic := '0';

  attribute box_type : string;
  attribute box_type of sram_addr_adder : component is "black_box";
  attribute box_type of nextx_adder : component is "black_box";

begin

  --
  -- DDR output buffer that generates the 100MHz flash clock from the
  -- rising edges of clk100 and clk100_inv
  --

  inst_ofddrsse : OFDDRRSE port map(
    Q  => flash_clk,
    C0 => clk100,
    C1 => clk100_inv,
    CE => flash_clk_ce_i,    -- we use this EN signal to switch the clock on and off 
    R  => '0',
    S  => '0',
    D0 => '1',
    D1 => '0'
  );

  --
  -- instantiate the pipelined adders declared above
  --

  inst_sram_addr_adder : sram_addr_adder
  port map (
    a   => sram_adder_a_i,
    b   => sram_adder_b_i,
    clk => clk100,
    s   => sram_adder_sum_i
  );

  inst_nextx_adder : nextx_adder
  port map (
    a   => nextx_adder_a_i,
    b   => nextx_adder_b_i,
    clk => clk100,
    s   => nextx_adder_sum_i
  );

  -- register the signals

  flash_ncs <= flash_ncs_i;
  flash_io_out <= flash_io_out_i;
  flash_io_mode <= flash_io_mode_i;
  frame_index_i <= frame_index;
  sram_data <= sram_data_i;
  sram_addr <= sram_addr_i;
  sram_nwr <= sram_nwr_i;
  debug <= debug_i;
  busy <= busy_i;
  bram_addr <= bram_addr_i;
  bram_en_mcu_interface <= bram_en_mcu_interface_i;
  bram_en_sprite_writer <= bram_en_sprite_writer_i;

--pragma synthesis_off
  state_out_sim <= state_i;
  last_pixel_out_sim <= last_pixel_i;
  sprite_size_out_sim <= sprite_size_i;
  sram_next_x_out_sim <= sram_next_x_i;
--pragma synthesis_on


  process(clk100,reset) is
  begin
  
    if rising_edge(clk100) then

      reset_cond : if reset = '1' then

        -- get back to idle state when reset is asserted

        state_i <= idle;

      else 

        case state_i is
        
          -- if we're in sprite mode and we're entering frame '1' then we can start
          
          when idle =>
            
            if mode = mode_sprite and last_frame_index_i = '0' and frame_index_i = '1' then
              state_i <= bram_0;
            end if;

            -- not busy, enable BRAM port on the mcu interface and disable ours

            busy_i <= false;
            bram_en_sprite_writer_i <= '0';
            bram_en_mcu_interface_i <= '1';
            
            -- reset other signals, switch off the flash etc.

            sprite_number_i <= (others => '0');
            sram_nwr_i <= SRAM_READ;
            flash_io_mode_i <= reading;
            flash_clk_ce_i <= '0';
            flash_ncs_i <= '1';

            last_frame_index_i <= frame_index_i;

          -- read out the sprite record from bram

          when bram_0 =>

            -- we are busy, enable our BRAM port and read the sprite

            busy_i <= true;
            bram_addr_i <= sprite_number_i;
            bram_en_sprite_writer_i <= '1';
            bram_en_mcu_interface_i <= '0';
            state_i <= bram_1;

          when bram_1 =>            -- hold for data out
            state_i <= bram_2;

          when bram_2 =>            -- if not visible then fast-forward to the next sprite
            if bram_dout.visible = '0' then
              state_i <= next_sprite;
            else
              sprite_record_i <= bram_dout;       -- get a copy of the sprite data record
              state_i <= outer_setup_0;
            end if;

          -- calculate the first origin and get the resettable y counter

          when outer_setup_0 =>
            sram_org_i <= sprite_record_i.sram_addr & "0";      -- pixel -> byte address
            sprite_repeat_y_i <= sprite_record_i.repeat_y;
            first_in_column_i <= true;
            yok_i <= false;               -- the *ok_i signals are true if current posn is within the partial ranges
            xok_i <= false;
            xok_reset_i <= false;         -- we'll reset x_ok to this on starting new column in repeat grid
            y_i <= (others => '0');
            xorg_i <= (others => '0');
            state_i <= outer_setup_1;

          -- start the addition to get the next sprite x position (2 clocks)

          when outer_setup_1 =>

            -- adder to get the next SRAM position

            sram_adder_a_i <= sram_org_i;
            sram_adder_b_i <= sprite_record_i.width & "0";      -- pixel -> byte width

            -- adder to get the next pixel offset within the sprite grid

            nextx_adder_a_i <= xorg_i;
            nextx_adder_b_i <= sprite_record_i.width;

            flash_ncs_i <= '0';             -- select the flash 
            state_i <= cmd_7;

          -- write the flash QUAD IO read command and concurrently do some other calculations
          -- that we'll need the results of later on.

          when cmd_7 =>
            sprite_width_i <= sprite_record_i.width;
            sprite_size_i <= sprite_record_i.size;
            sram_addr_i <= sram_org_i;

            x_i <= xorg_i;

            flash_clk_ce_i <= '1';            -- start flash clock
            flash_io_mode_i <= writing_1bit;  -- enable writing
            flash_io_out_i(0) <= '1';

            state_i <= cmd_6;

          when cmd_6 =>
            flash_io_out_i(0) <= '1';
            sprite_repeat_y_i <= sprite_height_t(unsigned(sprite_repeat_y_i)-1);    -- decrease repeat Y
            state_i <= cmd_5;

          when cmd_5 =>
            if first_in_column_i then
              sram_next_x_i <= sram_adder_sum_i;      -- addition is done by now
              nextx_i <= nextx_adder_sum_i;
            end if;

            flash_io_out_i(0) <= '1';
            state_i <= cmd_4;

          when cmd_4 =>
            first_in_column_i <= false;               -- will be set when y counter runs out

            flash_io_out_i(0) <= '0';
            state_i <= cmd_3;

          when cmd_3 =>
            flash_io_out_i(0) <= '1';
            state_i <= cmd_2;

          when cmd_2 =>
            flash_io_out_i(0) <= '0';
            state_i <= cmd_1;

          when cmd_1 =>
            flash_io_out_i(0) <= '1';
            state_i <= cmd_0;

          when cmd_0 =>
            flash_io_out_i(0) <= '1';
            state_i <= addr_5;

          -- flash 24 bit address follows and we're in quad mode now so the address
          -- goes out 4 bits at a time

          when addr_5 =>
            flash_io_mode_i <= writing_4bit;  -- enable writing
            flash_io_out_i <= sprite_record_i.flash_addr(23 downto 20);
            state_i <= addr_4;

          when addr_4 =>
            flash_io_out_i <= sprite_record_i.flash_addr(19 downto 16);
            state_i <= addr_3;

          when addr_3 =>
            flash_io_out_i <= sprite_record_i.flash_addr(15 downto 12);
            state_i <= addr_2;

          when addr_2 =>
            flash_io_out_i <= sprite_record_i.flash_addr(11 downto 8);
            state_i <= addr_1;

          when addr_1 =>
            flash_io_out_i <= sprite_record_i.flash_addr(7 downto 4);
            state_i <= addr_0;

          when addr_0 =>
            flash_io_out_i <= sprite_record_i.flash_addr(3 downto 0);
            state_i <= mode_1;

          -- mode 8 bits. we're not using the mode that allows fast address jumps, not yet anyway. 

          when mode_1 =>
            flash_io_out_i <= "0000";
            state_i <= mode_0;

          when mode_0 =>
            flash_io_out_i <= "0000";
            state_i <= dummy_4;

          -- 5 dummy clocks (speed = 100MHz, LC = 10)
          -- the flash_programmer utility wrote this field into the CR register

          when dummy_4 => 
            flash_io_out_i <= "0000";
            state_i <= dummy_3;

          when dummy_3 => 
            flash_io_out_i <= "0000";
            state_i <= dummy_2;

          -- writing's over, the datasheet recommends that we use this period to
          -- turn the bus around to Hi-Z ready for the data output

          when dummy_2 => 
            flash_io_mode_i <= reading;  -- bus turnaround
            state_i <= dummy_1;

          when dummy_1 => 
            state_i <= dummy_0;

          when dummy_0 => 
            sprite_size_i <= sprite_size_t(unsigned(sprite_size_i)-1);
            state_i <= data_out_pause0;

          when data_out_pause0 =>
            state_i <= data_out_pause1;

          when data_out_pause1 =>
            state_i <= first_pixel_read_0;

          -- read out the first pixel (2 x 8 bits). this primes last_pixel_i because the main loop will
          -- write out last_pixel_i to SRAM while concurrently reading the next pixel from flash.

          when first_pixel_read_0 =>
            last_pixel_i(15 downto 12) <= flash_io_in;
            state_i <= first_pixel_read_1;

          when first_pixel_read_1 =>
            last_pixel_i(11 downto 8) <= flash_io_in;
            state_i <= first_pixel_read_2;

          when first_pixel_read_2 =>
            last_pixel_i(7 downto 4) <= flash_io_in;
            state_i <= first_pixel_read_3;

          when first_pixel_read_3 =>
            last_pixel_i(3 downto 0) <= flash_io_in;
            
            -- first setting of xok, yok so they can be tested
            -- in the next state

            if x_i = sprite_record_i.firstx then
              xok_i <= true;
              xok_reset_i <= true;
            end if;

            state_i <= pixel_read_0;

          -- main read loop

          when pixel_read_0 =>

            if frame_index_i = '0' then
              state_i <= idle;          -- bail out if overrun
            else

              sram_adder_a_i <= sram_org_i;
              sram_adder_b_i <= "1011010000";     -- 360*2 = next row in SRAM 

              -- decrease the number of pixels remaining to be read

              sprite_size_i <= sprite_size_t(unsigned(sprite_size_i)-1);

              -- get the top 4 bits of the next pixel from flash

              pixel_i(15 downto 12) <= flash_io_in;

              -- update the ok-to-write flag for the Y direction

              if y_i = sprite_record_i.firsty then
                yok_i <= true;
              end if;

              -- if all clear at the current position then write out the last pixel we read in

              if last_pixel_i /= TRANSPARENT and xok_i and (yok_i or (y_i = sprite_record_i.firsty)) then
                sram_nwr_i <= SRAM_WRITE;
              end if;

              -- set the SRAM data to the last pixel

              sram_data_i <= last_pixel_i(15 downto 8);

              state_i <= pixel_read_1;
            end if;

          when pixel_read_1 =>
            
            -- get the second 4 bits from flash

            pixel_i(11 downto 8) <= flash_io_in;

            -- finish the SRAM write transaction, if there was one and update the address for
            -- the second lot of 8 bits

            sram_nwr_i <= SRAM_READ;
            sram_addr_i <= sram_byte_addr_t(unsigned(sram_addr_i)+1);
            
            -- decrease the number of pixels remaining on this row

            sprite_width_i <= sprite_width_t(unsigned(sprite_width_i)-1);

            state_i <= pixel_read_2;

          when pixel_read_2 =>
            
            -- get the third lot of 4 bits from the flash

            pixel_i(7 downto 4) <= flash_io_in;

            -- as before, if we're in a position to write data then do it

            if last_pixel_i /= TRANSPARENT and xok_i and yok_i then
              sram_nwr_i <= SRAM_WRITE;
            end if;

            -- the second half of the pixel

            sram_data_i <= last_pixel_i(7 downto 0);

            -- update the x position in this row

            if x_i = sprite_record_i.lastx then
              xok_i <= false;
            end if;

            x_i <= sprite_width_t(unsigned(x_i)+1);   -- may get reset in next state

            state_i <= pixel_read_3;

          when pixel_read_3 =>
            
            -- finish the SRAM write, if there was one

            sram_nwr_i <= SRAM_READ;
            
            -- set up the new 'last_pixel' with data previously read and the last 4 bits from flash

            last_pixel_i <= pixel_i & flash_io_in;

            if sprite_size_i = (sprite_size_i'range => '0') then
              
              -- loop done, but we've cached the last pixel and that needs to be written

              state_i <= last_pixel_write_0;
              sram_addr_i <= sram_byte_addr_t(unsigned(sram_addr_i)+1);
            
            elsif sprite_width_i = (sprite_width_i'range => '0') then

              -- end of just this row

              sram_addr_i <= sram_adder_sum_i;
              sram_org_i <= sram_adder_sum_i;
              sprite_width_i <= sprite_record_i.width;

              -- x resets back to row start state

              x_i <= xorg_i;
              xok_i <= xok_reset_i;

              -- y is tested for last y and then updated

              if y_i = sprite_record_i.lasty then
                yok_i <= false;
              end if;

              y_i <= sprite_height_t(unsigned(y_i)+1);

              state_i <= pixel_read_0;
            else
              
              -- loop still in progress, update the x state

              if x_i = sprite_record_i.firstx then
                xok_i <= true;
              end if;

              -- update to next pixel address on same row

              sram_addr_i <= sram_byte_addr_t(unsigned(sram_addr_i)+1);

              state_i <= pixel_read_0;
            end if;

          -- the loop's done but we've just read in the final pixel that
          -- now needs to go out to SRAM

          when last_pixel_write_0 =>
            
            -- if all the conditions are a-ok then the first half-pixel is written

            if last_pixel_i /= TRANSPARENT and xok_i and yok_i then
              sram_nwr_i <= SRAM_WRITE;
            end if;

            sram_data_i <= last_pixel_i(15 downto 8);
            state_i <= last_pixel_write_1;

          when last_pixel_write_1 =>
            
            -- finish the SRAM write and increase the address for next half

            sram_nwr_i <= SRAM_READ;
            sram_addr_i <= sram_byte_addr_t(unsigned(sram_addr_i)+1);
            state_i <= last_pixel_write_2;

          when last_pixel_write_2 =>
            
            -- as before, the pixel goes out if the conditions allow

            if last_pixel_i /= TRANSPARENT and xok_i and yok_i then
              sram_nwr_i <= SRAM_WRITE;
            end if;

            sram_data_i <= last_pixel_i(7 downto 0);
            state_i <= done_this_sprite_0;

          when done_this_sprite_0 =>
            
            -- the sprite output is complete, disable flash

            flash_clk_ce_i <= '0';          -- clock off
            flash_ncs_i <= '1';             -- deselect
            sram_nwr_i <= SRAM_READ;        -- SRAM to read mode
            state_i <= done_this_sprite_1;

          -- see if we're done with this column of sprites

          when done_this_sprite_1 =>
            if sprite_repeat_y_i = (sprite_repeat_y_i'range => '0') then
              
              -- if the repeat grid column is done move on

              sprite_record_i.repeat_x <= sprite_width_t(unsigned(sprite_record_i.repeat_x)-1);
              state_i <= done_this_sprite_2;
            
            else
              -- move down the column to the next sprite

              sram_org_i <= sram_adder_sum_i;

              x_i <= xorg_i;
              xok_i <= xok_reset_i;

              -- y is tested for last y and then updated

              if y_i = sprite_record_i.lasty then
                yok_i <= false;
              end if;

              y_i <= sprite_height_t(unsigned(y_i)+1);
              state_i <= outer_setup_1;
            end if;

          when done_this_sprite_2 =>

            if sprite_record_i.repeat_x = (sprite_record_i.repeat_x'range => '0')  then
              
              -- all rows are complete

              state_i <= next_sprite;
            
            else
            
              -- move to the next row

              sram_org_i <= sram_next_x_i;
              sprite_repeat_y_i <= sprite_record_i.repeat_y;
              first_in_column_i <= true;
              
              xok_reset_i <= xok_i;
              xorg_i <= nextx_i;
              y_i <= (others => '0');
              yok_i <= false;

              state_i <= outer_setup_1;
            end if;

          when next_sprite =>
            if sprite_number_i = LAST_SPRITE then

              -- if we've passed through all the sprites then back to idle

              state_i <= idle;
            else
              
              -- increase the sprite number by 1 and go back to reading from BRAM

              sprite_number_i <= sprite_number_t(unsigned(sprite_number_i)+1);
              state_i <= bram_0;
            
            end if;

          when others => null;

        end case;

      end if reset_cond;

    end if;
  
  end process;
  
end behavioral;
