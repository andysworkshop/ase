library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.constants.all;
use work.functions.all;


entity flash_programmer_tb is
end flash_programmer_tb;

architecture behavior of flash_programmer_tb is 

-- component declaration for the unit under test (uut)

component flash_programmer
  port(
    clk40     : in  std_logic;
    reset     : in  std_logic;
    mcu_wr    : in  std_logic;
    mcu_data  : in  mcu_bus_t;
    
    flash_ncs : out  std_logic;
    flash_clk : out  std_logic;
    flash_io  : inout std_logic_vector(3 downto 0);
    
    busy      : out   std_logic;
    debug     : out   std_logic;
    state_out_sim : out mcu_interface_state_t
  );
end component;

--inputs
signal clk40 : std_logic := '0';
signal reset : std_logic := '0';
signal mcu_wr : std_logic := '0';
signal mcu_data : mcu_bus_t := (others => '0');

--outputs
signal flash_ncs : std_logic := '1';
signal flash_clk : std_logic := '0';
signal flash_io  : std_logic_vector(3 downto 0);

signal busy : std_logic;
signal debug : std_logic;
signal state_out_sim : mcu_interface_state_t;

-- clock period definitions
constant clk_period : time := 25 ns;
constant clk_inv_period : time := 25 ns;

signal data_byte : std_logic_vector(7 downto 0);

begin

-- instantiate the unit under test (uut)
uut: flash_programmer port map (
  clk40      => clk40,
  reset      => reset,
  mcu_data   => mcu_data,
  mcu_wr     => mcu_wr,
  flash_ncs  => flash_ncs,
  flash_clk  => flash_clk,
  flash_io   => flash_io,
  busy       => busy,
  debug      => debug,
  state_out_sim => state_out_sim
);

-- clock process definitions

clk_process : process
begin

  clk40 <= '0';
  wait for clk_period/2;
  clk40 <= '1';
  wait for clk_period/2;

end process;

-- stimulus process

stim_proc : process
begin    

  -- bulk erase command

  mcu_data <= "00" & CMD_BULK_ERASE;
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = wait_idle_0; 

  -- simulate the flash busy for this cycle

  wait until state_out_sim = wait_idle_3;
  flash_io(1) <= '1';
  
  -- now release the flash

  wait until state_out_sim = wait_idle_1;
  flash_io(1) <= '0';
  wait until state_out_sim = reading_command;

  -- done

  wait;

end process;

end;
