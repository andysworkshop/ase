library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;


entity sprite_writer_tb is
end sprite_writer_tb;

architecture behavior of sprite_writer_tb is 

  component sprite_writer is
  port(
    
    -- inputs
    
    reset         : in  std_logic;
    clk100        : in  std_logic;
    clk100_inv    : in  std_logic;
    mode          : in  mode_t;
    frame_index   : in  std_logic;
    flash_io_in   : in  flash_io_bus_t;
    bram_dout     : in  sprite_record_t;
    
    -- outputs
    
    sram_addr     : out sram_byte_addr_t;
    sram_data     : out sram_data_t;
    sram_nwr      : out std_logic;
    flash_ncs     : out std_logic;
    flash_io_out  : out flash_io_bus_t;
    flash_clk     : out std_logic;
    bram_addr     : out sprite_number_t;
    busy          : out boolean;

    -- simulation outputs

    state_out_sim       : out sprite_writer_state_t;
    last_pixel_out_sim  : out pixel_t;
    sprite_size_out_sim : out sprite_size_t;
    sram_next_x_out_sim : out sram_byte_addr_t
  );
  end component;

  -- inputs
  
  signal reset : std_logic := '0';
  signal clk100 : std_logic := '0';
  signal clk100_inv : std_logic := '1';
  signal mode : mode_t := mode_sprite;
  signal frame_index : std_logic := '0';
  signal flash_io_in : flash_io_bus_t := (others => '1');
  signal bram_dout : sprite_record_t := unpack_sprite_record(null_sprite_record);
  
  -- outputs

  signal sram_addr : sram_byte_addr_t;
  signal sram_data : sram_data_t;
  signal sram_nwr : std_logic;
  signal flash_ncs : std_logic;
  signal flash_io_out : flash_io_bus_t;
  signal flash_clk : std_logic;
  signal bram_addr : sprite_number_t;
  signal busy : boolean;
  
  -- simulation outputs
  
  signal state : sprite_writer_state_t;
  signal last_pixel : pixel_t;
  signal sprite_size : sprite_size_t;
  signal next_x : sram_byte_addr_t;

  -- locals

  signal i,j : unsigned(255 downto 0);

  -- constants
  
  constant clk100_period : time := 10ns;
  
begin

  uut : sprite_writer port map (
    
    reset => reset,
    clk100 => clk100,
    clk100_inv => clk100_inv,
    mode => mode,
    frame_index => frame_index,
    flash_io_in => flash_io_in,
    bram_dout => bram_dout,

    sram_addr => sram_addr,
    sram_data => sram_data,
    sram_nwr => sram_nwr,
    flash_ncs => flash_ncs,
    flash_io_out => flash_io_out,
    flash_clk => flash_clk,
    bram_addr => bram_addr,    
    busy => busy,
    
    state_out_sim => state,
    last_pixel_out_sim => last_pixel,
    sprite_size_out_sim => sprite_size,
    sram_next_x_out_sim => next_x
  );

  clk_process : process
  begin
    clk100 <= '0';
    clk100_inv <= '1';
    wait for clk100_period/2;
    clk100 <= '1';
    clk100_inv <= '0';
    wait for clk100_period/2;
  end process;
  
  stim_proc : process
  begin
  
    reset <= '1';
    wait for 20ns;
    reset <= '0';
    wait for 20ns;

    -- trigger the start

    wait until clk100_inv='0'; wait until clk100_inv='1'; 
    mode <= mode_sprite;
    frame_index <= '0';
    wait until clk100_inv='0'; wait until clk100_inv='1'; 
    mode <= mode_sprite;
    frame_index <= '1';

    -- set up a sprite

    wait until bram_addr <= "000000001";
    bram_dout.flash_addr <= X"123456";
    bram_dout.sram_addr <= "00" & X"4567";
    bram_dout.size <= "00" & X"0010";       -- 16 pixels
    bram_dout.width <= "0" & X"04";         -- w=4, h=4
    bram_dout.repeat_x <= "0" & X"03";      -- repeat X = 3
    bram_dout.repeat_y <= "00" & X"02";     -- repeat Y = 2
    bram_dout.visible <= '1';

--    bram_dout.firstx <= (others => '0');        -- make it completely visible
--    bram_dout.lastx <= "101100111";       -- 359
--    bram_dout.firsty <= (others => '0');
 --   bram_dout.lasty <= "1001111111";      -- 639

 --   bram_dout.firstx <= "000000010";      -- start at column 2 (off the left)
   -- bram_dout.lastx <= "101100111";       -- 359
 --   bram_dout.firsty <= (others => '0');
 --   bram_dout.lasty <= "1001111111";      -- 639

--    bram_dout.firstx <= (others => '0');      -- end at column 2 (off the right)
 --   bram_dout.lastx <= "000000010";       -- 359
 --   bram_dout.firsty <= (others => '0');
 --   bram_dout.lasty <= "1001111111";      -- 639

--    bram_dout.sram_addr <= "111111110100110000";
--    bram_dout.firstx <= (others => '0');      -- start at row 2 (off the top)
--    bram_dout.lastx <= "101100111";       -- 359
--    bram_dout.firsty <= "0000000010";
--    bram_dout.lasty <= "1001111111";      -- 639

--    bram_dout.firstx <= (others => '0');      -- end at row 2 (off the bottom)
  --  bram_dout.lastx <= "101100111";       -- 359
  --  bram_dout.firsty <= (others => '0');
 --   bram_dout.lasty <= "0000000010";      -- 2

--    bram_dout.firstx <= (others => '0');      -- start and end at row 0 (really off the bottom)
 --   bram_dout.lastx <= "101100111";       -- 359
  --  bram_dout.firsty <= (others => '0');
  --  bram_dout.lasty <= (others => '0');

--    bram_dout.firstx <= (others => '0');      -- start and end at row 7 (just peeking on to the top)
 --   bram_dout.lastx <= "101100111";       -- 359
  --  bram_dout.firsty <= "0000000111";     -- 7
 --   bram_dout.lasty <= "0000000111";      -- 7

--    bram_dout.firstx <= (others => '0');      -- start and end at column 0 (very off the right)
--    bram_dout.lastx <=  (others => '0');
 --   bram_dout.firsty <= (others => '0');
--    bram_dout.lasty <= "1001111111";      -- 639

    bram_dout.firstx <= "000001011";      -- start and end at column 11 (only just on the left)
    bram_dout.lastx <=  "000001011";       -- 11      
    bram_dout.firsty <= (others => '0');
    bram_dout.lasty <= "1001111111";      -- 639

    for j in 1 to 6 loop

      -- wait for the data out state

      wait until state = first_pixel_read_0;
      wait until flash_clk = '0';
      
      -- write out 16 pixels

      for i in 1 to 64 loop

        if flash_io_in = "1111" then
          flash_io_in <= "0000";
        else 
          flash_io_in <= flash_io_bus_t(unsigned(flash_io_in)+1);
        end if;

        wait until flash_clk = '1';
        wait until flash_clk = '0';

      end loop;
    end loop;

    wait until state = next_sprite;
    bram_dout <= unpack_sprite_record(null_sprite_record);

    wait;
  end process;

end architecture;

