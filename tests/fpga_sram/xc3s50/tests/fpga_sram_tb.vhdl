-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;
use ieee.std_logic_1164.all;

entity fpga_sram_tb is
end fpga_sram_tb;
 
architecture behavior of fpga_sram_tb is 

  -- component declaration for the unit under test (uut)

  component fpga_sram
    port(
      clk40     : in  std_logic;
      status    : out  std_logic;
      sram_addr : out  std_logic_vector(18 downto 0);
      sram_data : inout  std_logic_vector(7 downto 0);
      sram_nwr  : out  std_logic
    );
  end component;

  -- component definition for the SRAM model. leave this in to accurate model
  -- fpga_sram. comment out to see the actual data vs. Z signals on sram_data
  -- which is useful to ensure you're driving the tristate bus only when you should.
  -- WARNING: ISIM will use crazy amounts of memory to elaborate sram_sim.

  component sram_sim
    generic(
      addr_width : integer
    );    
    port(
      addr : in std_logic_vector(18 downto 0);     -- 19 bit address bus
      data : inout std_logic_vector(7 downto 0);   -- 8 bit data bus
      nwr  : in std_logic                          -- write enable
    );
  end component;

  --inputs
  signal clk40 : std_logic := '0';

  --bidirs
  signal sram_data : std_logic_vector(7 downto 0);

  --outputs
  signal status : std_logic := '0';
  signal sram_addr : std_logic_vector(18 downto 0);
  signal sram_nwr : std_logic := '1';

  -- clock period definitions
  constant clk40_period : time := 25 ns;

begin
 
  -- instantiate the unit under test (uut)
  uut: fpga_sram 
    port map (
      clk40 => clk40,
      status => status,
      sram_addr => sram_addr,
      sram_data => sram_data,
      sram_nwr => sram_nwr
    );

  -- instantiate the sram sim
  inst_sram_sim : sram_sim 
    generic map(
      addr_width => 19        -- 19 bit SRAM bus
    )
    port map(
      addr => sram_addr,
      data => sram_data,
      nwr => sram_nwr
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
    wait;
  end process;

end;


