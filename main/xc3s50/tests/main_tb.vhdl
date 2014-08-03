library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;
 
entity main_tb is
end main_tb;
 
architecture behavior of main_tb is 
 
  -- component declaration for the unit under test (uut)

  component main
   port(
    clk40 : in  std_logic;
    reset : in  std_logic;
    busy : out  std_logic;
    sram_addr : out  std_logic_vector(18 downto 0);
    sram_data : inout  std_logic_vector(7 downto 0);
    sram_nwr : out  std_logic;
    lcd_wr : out  std_logic;
    lcd_rs : out  std_logic;
    lcd_te : in  std_logic;
    lcd_db : out  std_logic_vector(7 downto 0);
    lcd_ale : out  std_logic;
    mcu_wr : in  std_logic;
    mcu_data : in  std_logic_vector(9 downto 0);
    flash_ncs : out  std_logic;
    flash_clk : out  std_logic;
    flash_io : inout  std_logic_vector(3 downto 0);
    debug : out  std_logic;

    mcu_state_out_sim : out mcu_interface_state_t;
    sprite_writer_state_out_sim : out sprite_writer_state_t
  );
  end component;
    
  --inputs
  signal clk40 : std_logic := '0';
  signal reset : std_logic := '0';
  signal lcd_te : std_logic := '0';
  signal mcu_wr : std_logic := '0';
  signal mcu_data : std_logic_vector(9 downto 0) := (others => '0');

  --bidirs
  signal sram_data : std_logic_vector(7 downto 0);
  signal flash_io : std_logic_vector(3 downto 0);

  --outputs
  signal busy : std_logic;
  signal sram_addr : std_logic_vector(18 downto 0);
  signal sram_nwr : std_logic;
  signal lcd_wr : std_logic;
  signal lcd_rs : std_logic;
  signal lcd_db : std_logic_vector(7 downto 0);
  signal lcd_ale : std_logic;
  signal flash_ncs : std_logic;
  signal flash_clk : std_logic;
  signal debug : std_logic;
  signal mcu_state : mcu_interface_state_t;
  signal sprite_writer_state : sprite_writer_state_t;

  -- clock period definitions
  constant clk40_period : time := 25 ns;
 
  begin
 
  -- instantiate the unit under test (uut)
  uut: main port map (
    clk40 => clk40,
    reset => reset,
    busy => busy,
    sram_addr => sram_addr,
    sram_data => sram_data,
    sram_nwr => sram_nwr,
    lcd_wr => lcd_wr,
    lcd_rs => lcd_rs,
    lcd_te => lcd_te,
    lcd_db => lcd_db,
    lcd_ale => lcd_ale,
    mcu_wr => mcu_wr,
    mcu_data => mcu_data,
    flash_ncs => flash_ncs,
    flash_clk => flash_clk,
    flash_io => flash_io,
    debug => debug,
    mcu_state_out_sim => mcu_state,
    sprite_writer_state_out_sim => sprite_writer_state
  );

  -- clock process definitions
  clk40_process :process
    begin
    clk40 <= '0';
    wait for clk40_period/2;
    clk40 <= '1';
    wait for clk40_period/2;
  end process;
 
  -- stimulus process
  stim_proc: process
  begin    

    -- wait for DCM lock

    wait for 500ns;

    -- reset
    reset <= '0';
    wait for 60 ns;  
    reset <= '1';
    wait for 60 ns;
    reset <= '0';
    wait for 60 ns;

    -- enable sprite mode

    mcu_data <= "1000000000";

    mcu_wr <= '0';
    wait for 50ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_cmd;

    -- write sprite zero

    mcu_data <= "1000000000";

    mcu_wr <= '0';
    wait for 50ns;
    mcu_wr <= '1';

    mcu_data <= "00" & CMD_LOAD;
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_number;
    
    mcu_data <= (others => '0');    -- sprite number
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_addr_low;

    mcu_data <= (others => '0');   -- 0
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_addr_high;

    mcu_data <= (others => '0');    -- 0
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_width;

    mcu_data <= "0110010100";        -- width(404)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_pixel_size_low;

    mcu_data <= "0011000000";    -- pixel_size_low(45248)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_pixel_size_high;

    mcu_data <= "0000101100";    -- pixel_size_high(45248)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_flash_addr_low;

    mcu_data <= (others => '0');    -- flash_start_low(0)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_flash_addr_mid;

    mcu_data <= (others => '0');    -- flash_start_mid(0)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_flash_addr_high;

    mcu_data <= (others => '0');    -- flash_start_high(0)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_repeat_x;

    mcu_data <= "0000000001";    -- repeat_x (1)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_repeat_y;

    mcu_data <= "0000000001";    -- repeat_y (1)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_load_sprite_visible;

    mcu_data <= "0000000001";    -- visible (1)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until mcu_state = reading_cmd;

    -- toggle TE to get into sprite_writer mode

    lcd_te <= '1';
    wait for 60ns;
    lcd_te <= '0';
    wait for 60ns;

    -- wait for a while for the sprite writer to finish

    wait until busy = '0';

    -- toggle TE to get into frame_writer mode

    lcd_te <= '1';
    wait for 60ns;
    lcd_te <= '0';

    wait;
  end process;  
end;
