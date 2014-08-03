library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;

 
entity frame_writer_tb is
end frame_writer_tb;
 
architecture behavior of frame_writer_tb is 
 
  -- component declaration for the unit under test (uut)

  component frame_writer
  port(
    -- inputs

    reset       : in std_logic;
    clk100      : in std_logic;
    mode        : in mode_t;
    frame_index : in std_logic;
    sram_data   : in sram_data_t;

    -- outputs

    lcd_wr   : out std_logic;         -- write strobe
    lcd_db   : out lcd_bus_t;      -- 8 bit data bus (latched)
    lcd_ale  : out std_logic;         -- latch enable

    sram_addr : out sram_byte_addr_t;
    debug     : out std_logic;
    
    state_out_sim : out frame_writer_state_t
  );
  end component;

   --inputs
   signal reset : std_logic := '0';
   signal clk100 : std_logic := '0';
   signal mode : mode_t;
   signal frame_index : std_logic := '0';
   signal sram_data : sram_data_t := (others => '0');

  --outputs
   signal lcd_wr : std_logic;
   signal lcd_db : lcd_bus_t;
   signal lcd_ale : std_logic;
   signal sram_addr : sram_byte_addr_t;
   signal state : frame_writer_state_t;
   signal debug : std_logic;

   signal data : sram_data_t;
   signal i : unsigned(0 to 1001);

   -- clock period definitions
   constant clk100_period : time := 10 ns;
 
begin

  -- instantiate the unit under test (uut)
  uut: frame_writer port map (
    reset => reset,
    clk100 => clk100,
    mode => mode,
    frame_index => frame_index,
    sram_data => sram_data,
    lcd_wr => lcd_wr,
    lcd_db => lcd_db,
    lcd_ale => lcd_ale,
    sram_addr => sram_addr,
    state_out_sim => state,
    debug => debug
  );

  -- clock process definitions
  clk100_process :process
    begin
    clk100 <= '0';
    wait for clk100_period/2;
    clk100 <= '1';
    wait for clk100_period/2;
  end process;
 

  -- stimulus process
  stim_proc: process
  begin    

    mode <= mode_sprite;

    reset <= '1';
    wait for 20ns;
    reset <= '0';
    wait for 20ns;

    -- trigger the start

    wait until clk100='0'; wait until clk100='1'; 
    frame_index <= '1';
    wait until clk100='0'; wait until clk100='1'; 
    frame_index <= '0';

    -- write out the pixels

    data <= (others => '0');
    
    wait until state = pre_0;
    sram_data <= data;
    data<=sram_data_t(unsigned(data)+1);

    wait until state = pre_1;
    sram_data <= data;
    data<=sram_data_t(unsigned(data)+1);

    for i in 1 to 1000 loop

      wait until state = state_20;
      sram_data <= data;
      data<=sram_data_t(unsigned(data)+1);

      wait until state = state_30;
      sram_data <= data;
      data<=sram_data_t(unsigned(data)+1);

    end loop;

  wait;
  end process;

end;
