library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;


entity mcu_interface_tb is
end mcu_interface_tb;
 
architecture behavior of mcu_interface_tb is 
 
  -- component declaration for the unit under test (uut)

  component mcu_interface
    port(
      
      -- inputs
      
      clk100          : in std_logic;
      reset           : in std_logic;
      mcu_data        : in mcu_bus_t;
      mcu_wr          : in std_logic;
      bram_dout       : in sprite_record_t;
      lcd_sender_busy : in boolean;
      
      -- outputs
      
      lcd_rs          : out std_logic;
      lcd_sender_go   : out std_logic;
      lcd_sender_data : out lcd_data_t;
      bram_wr         : out std_logic;
      bram_addr       : out sprite_number_t;
      bram_din        : out sprite_record_t;
      mode            : out mode_t;

      debug           : out std_logic
      
  --pragma synthesis_off
      ;
      state_out_sim : out mcu_interface_state_t
  --pragma synthesis_on
    );
  end component;

  --inputs
  signal reset     : std_logic := '0';
  signal clk100    : std_logic := '0';
  signal mcu_data  : mcu_bus_t := (others => '0');
  signal mcu_wr    : std_logic := '1';
  signal bram_dout : sprite_record_t;
  
  --outputs
  signal lcd_rs          : std_logic;
  signal bram_wr         : std_logic;
  signal bram_addr       : sprite_number_t;
  signal bram_din        : sprite_record_t;
  signal mode            : mode_t := mode_passthrough;
  signal lcd_sender_busy : boolean := false;
  signal state_out_sim   : mcu_interface_state_t;
  signal lcd_sender_go   : std_logic;
  signal lcd_sender_data : lcd_data_t;
  signal debug           : std_logic;

  -- clock period definitions
  constant clk100_period : time := 10 ns;
 
begin
 
  -- instantiate the unit under test (uut)
  uut: mcu_interface port map (
    clk100          => clk100,
    reset           => reset,
    mcu_data        => mcu_data,
    mcu_wr          => mcu_wr,
    bram_dout       => bram_dout,
    lcd_sender_busy => lcd_sender_busy,
  
    lcd_rs          => lcd_rs,
    lcd_sender_go   => lcd_sender_go,
    lcd_sender_data => lcd_sender_data,
    bram_wr         => bram_wr,
    bram_addr       => bram_addr,
    bram_din        => bram_din,
    mode            => mode,
    debug           => debug,

    state_out_sim => state_out_sim
  );

  -- clock process definitions
  
  clk_process :process
  begin
    clk100 <= '0';
    wait for clk100_period/2;
    clk100 <= '1';
    wait for clk100_period/2;
  end process;

   -- stimulus process
  stim_proc: process
  begin		

    -- reset the component
    
    reset <= '1';
    wait for 20ns;
    reset <= '0';
    wait for 20ns;

    -- write a command (RS=1)
    
    mcu_data <= "0011110000";     -- F0
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = passthrough_1;
    
    mcu_data <= "1010101010";     -- AA
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    
    lcd_sender_busy <= true;
    wait until state_out_sim = passthrough_2;
    
    assert lcd_sender_data = X"AAF0" report "unexpected lcd_sender_data " & hstr(lcd_sender_data) & " expected AAF0";
    assert lcd_rs = '1' report "unexpected lcd_rs = 0, expected 1";
    
    lcd_sender_busy <= false;
    wait until state_out_sim = passthrough_0;

    -- write a data (RS=0)
    
    mcu_data <= "0000001111";     -- 0F
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = passthrough_1;
    
    mcu_data <= "0010010011";     -- 93
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    
    lcd_sender_busy <= true;
    wait until state_out_sim = passthrough_2;
    
    assert lcd_sender_data = X"930F" report "unexpected lcd_sender_data " & hstr(lcd_sender_data) & " expected 930F";
    assert lcd_rs = '0' report "unexpected lcd_rs = 1, expected 0";
    
    lcd_sender_busy <= false;
    wait until state_out_sim = passthrough_0;
    
    -- get out of passthrough into sprite mode
    
    mcu_data <= "1000000000";

    mcu_wr <= '0';
    wait for 50ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_cmd;

    assert mode = mode_sprite report "unexpected mode, expecting '1'";
    
    -- CMD_LOAD testing
    -- load sprite 295
    
    mcu_data <= "00" & CMD_LOAD;
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_number;
    
    mcu_data <= "0100100111";    -- sprite number
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_addr_low;

    mcu_data <= "1110111010";   -- low address
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_addr_high;

    mcu_data <= "0000110100";    -- high address
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_width;

    mcu_data <= "0101001101";    -- width(333)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_pixel_size_low;

    mcu_data <= "0000000100";    -- pixel_size_low(6804)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_pixel_size_high;

    mcu_data <= "0000011010";    -- pixel_size_high(6804)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_flash_addr_low;

    mcu_data <= "0001100110";    -- flash_start_low(0xccaa66)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_flash_addr_mid;

    mcu_data <= "0010101010";    -- flash_start_mid(0xccaa66)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_flash_addr_high;

    mcu_data <= "0111001100";    -- flash_start(0xccaa66), visible(1)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_repeat_x;

    mcu_data <= "0000001100";    -- repeat_x (12)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_repeat_y;

    mcu_data <= "0000001101";    -- repeat_y (13)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_visible;

    mcu_data <= "0000000001";    -- visible (1)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_first_x;

    mcu_data <= "0001010101";    -- firstx (55)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_last_x;

    mcu_data <= "0001110101";    -- lastx (75)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_first_y;

    mcu_data <= "0000110011";    -- firsty (33)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_load_sprite_last_y;

    mcu_data <= "0000111011";    -- lasty (3b)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_cmd;

    -- assert the correct values in the sprite record
    
    assert bram_addr = "100100111"
      report "load: unexpected bram_addr " & hstr(bram_addr) & " expected 0x127";

    assert bram_din.flash_addr = X"CCAA66"
      report "load: unexpected bram_din.flash_addr " & hstr(bram_din.flash_addr) & " expected ccaa66";
    
    assert bram_din.sram_addr = "00" & X"d3ba"
      report "load: unexpected bram_din.sram_addr " & hstr(bram_din.sram_addr) & " expected d3ba";

    assert bram_din.size = "00" & X"6804"
      report "load: unexpected bram_din.size " & hstr(bram_din.size) & " expected 06804";

    assert bram_din.width = "101001101"
      report "load: unexpected bram_din.width " & hstr(bram_din.width) & " expected 14d";

    assert bram_din.repeat_x = "0" & X"0C"
      report "load: unexpected bram_din.repeat_x " & hstr(bram_din.repeat_x) & " expected 00c";

    assert bram_din.repeat_y = "00" & X"0D"
      report "load: unexpected bram_din.repeat_y " & hstr(bram_din.repeat_y) & " expected 00d";

    assert bram_din.visible = '1'
      report "load: unexpected bram_din.visible " & std_logic'image(bram_din.visible) & " expected 1";

    assert bram_din.firstx = "0" & X"55"
      report "load: unexpected bram_din.firstx " & hstr(bram_din.firstx) & " expected 55";

    assert bram_din.lastx = "0" & X"75"
      report "load: unexpected bram_din.lastx " & hstr(bram_din.lastx) & " expected 75";

    assert bram_din.firsty = "00" & X"33"
      report "load: unexpected bram_din.firsty " & hstr(bram_din.firsty) & " expected 33";

    assert bram_din.lasty = "00" & X"3b"
      report "load: unexpected bram_din.lasty " & hstr(bram_din.lasty) & " expected 3b";

    -- CMD_PASSTHROUGH

    mcu_data(7 downto 0) <= CMD_PASSTHROUGH;
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = passthrough_0;
    
    -- assert the result
    
    assert mode = mode_passthrough
      report "mode: unexpected value. was expecting 0 (mode_passthrough)";

    -- set back to sprite mode
    
    mcu_data <= "1000000000";
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_cmd;
      
    -- assert the result
    
    assert mode = mode_sprite
      report "mode: unexpected value. was expecting 1 (mode_sprite)";

    -- show sprite 13
    
    mcu_data <= "00" & CMD_SHOW;
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_showhide_sprite;
    
    mcu_data <= "0000001101";
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_cmd;

    assert bram_addr = "000001101" 
      report "show: unexpected bram_addr " & hstr(bram_addr) & " expected 00D";
    
    assert bram_din.visible = '1'
      report "show: unexpected visibility " & std_logic'image(bram_din.visible) & " expected 1";
    
    -- CMD_MOVE testing
    -- move sprite 17

    mcu_data(7 downto 0) <= CMD_MOVE;
    mcu_data(mcu_data'left) <= '0';
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_sprite;
    
    mcu_data <= "0000010001";       -- 17
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_addr_low;

    mcu_data <= "0011000001";    -- low
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_addr_high;

    mcu_data <= "0000011011";   -- high
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_cmd;

    assert bram_addr = "000010001" 
      report "move: unexpected bram_addr " & hstr(bram_addr) & " expected 11";
    
    assert bram_din.sram_addr = "000110110011000001" 
      report "move: unexpected sram_addr " & hstr(bram_din.sram_addr) & " expected 6cc1";

    -- CMD_MOVE (with partial) testing
    -- move sprite 17

    mcu_data(7 downto 0) <= CMD_MOVE;
    mcu_data(mcu_data'left) <= '1';     -- partial flag
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_sprite;
    
    mcu_data <= "0000010001";       -- 17
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_addr_low;

    mcu_data <= "0011011001";    -- low
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_addr_high;

    mcu_data <= "0000011111";   -- high
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_first_x;

    mcu_data <= "0010001111";    -- firstx (0x8f)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_last_x;

    mcu_data <= "0011000110";    -- lastx (0xc6)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_first_y;

    mcu_data <= "0110110110";    -- firsty (0x1B6)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_move_last_y;

    mcu_data <= "0111110110";    -- lasty (0x1F6)
    mcu_wr <= '0';
    wait for 40ns;
    mcu_wr <= '1';
    wait until state_out_sim = reading_cmd;

    assert bram_addr = "000010001" 
      report "move: unexpected bram_addr " & hstr(bram_addr) & " expected 11";
    
    assert bram_din.sram_addr = "000111110011011001"
      report "move: unexpected sram_addr " & hstr(bram_din.sram_addr) & " expected 7cd9";

    assert bram_din.firstx = "0" & X"8f"
      report "load: unexpected bram_din.firstx " & hstr(bram_din.firstx) & " expected 8f";

    assert bram_din.lastx = "0" & X"c6"
      report "load: unexpected bram_din.lastx " & hstr(bram_din.lastx) & " expected c6";

    assert bram_din.firsty = "0110110110"
      report "load: unexpected bram_din.firsty " & hstr(bram_din.firsty) & " expected 1b6";

    assert bram_din.lasty = "0111110110"
      report "load: unexpected bram_din.lasty " & hstr(bram_din.lasty) & " expected 1f6";

    wait;
    
  end process;

end;


