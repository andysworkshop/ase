library ieee;

use ieee.std_logic_1164.all;

use work.constants.all;
use work.functions.all;


--
-- flash_programmer is designed to accept erase/program/verify/write-cr commands from an MCU
-- and execute them against the flash IC. program/verify is done a page at a time. The MCU
-- is able to poll the FPGA for a busy signal so it knows when it's safe to write more commands.
--

entity flash_programmer is
  port(
  
    -- the clock and FPGA control signals
    
    clk40 : in  std_logic;          -- 40Mhz oscillator
    reset : in  std_logic;          -- overall reset    -- MCU command interface

    mcu_wr   : in std_logic;          -- write enable
    mcu_data : in mcu_bus_type;       -- 10-bit data bus

    -- flash IO interface

    flash_ncs : out   std_logic;                      -- flash chip select
    flash_clk : out   std_logic;                      -- flash clock (100MHz)
    flash_io  : inout std_logic_vector(3 downto 0);   -- 4-bit flash bus

    -- busy signal

    busy : out std_logic;

    -- debugging test port

    debug : out std_logic

--pragma synthesis_off
    ;
    state_out_sim : out mcu_interface_state_type
--pragma synthesis_on
  );
end flash_programmer;


architecture behavioral of flash_programmer is

	component clock_generator port (
    clkin_in        : in std_logic;
    clkin_ibufg_out : out std_logic;
    clk0_out        : out std_logic;
    clk180_out      : out std_logic
	);
	end component;

  component reset_conditioner port(
    clk               : in  std_logic;
    reset             : in  std_logic;
    conditioned_reset : out  std_logic
  );
  end component;

  component mcu_interface port(
    -- inputs
    
    clk         : in std_logic;
    clk_inv     : in std_logic;
    reset       : in std_logic;
    mcu_data    : in mcu_bus_type;
    mcu_wr      : in std_logic;
    flash_io_in : in std_logic;

    -- outputs 

    flash_io_out : out std_logic;
    flash_ncs    : out std_logic;
    flash_clk    : out std_logic;
    busy         : out std_logic;
    debug        : out std_logic
--pragma synthesis_off
    ;
    state_out_sim : out mcu_interface_state_type
--pragma synthesis_on
  );
  end component;
  
  -- clock definitions and constraints
  
  signal clk       : std_logic;
  signal clk_inv   : std_logic;
  
  attribute period : string;
  attribute period of clk     : signal is "25 ns";

  signal conditioned_reset_i : std_logic := '0';

  signal debug_i : std_logic := '0';
  signal busy_i : std_logic := '0';

begin

  debug <= debug_i;
  busy <= busy_i;

  -- set up the state of the constant IO pins

  flash_io(1) <= 'Z';     -- input
  flash_io(2) <= '1';
  flash_io(3) <= '1';

  -- the DCM is used to generate a 40MHz signal for internal use and an inverted signal for
  -- use with the normal signal in generating the flash clock via an OFDDR buffer

  inst_clock_generator : clock_generator port map(
		clkin_in        => clk40,
		clk180_out      => clk_inv,
		clkin_ibufg_out => open,
		clk0_out        => clk
	);

  -- reset_conditioner is used to ensure that the asynchronous reset is converted to a synchronous
  -- reset with safety checks to ensure it's not triggered by accident.

  inst_reset_conditioner : reset_conditioner port map(
    clk               => clk,
    reset             => reset,
    conditioned_reset => conditioned_reset_i
  );

  -- mcu_interface reads and executes commands from the MCU
  
  inst_mcu_interface : mcu_interface port map(
    clk          => clk,
    clk_inv      => clk_inv,
    reset        => conditioned_reset_i,
    mcu_data     => mcu_data,
    mcu_wr       => mcu_wr,
    flash_io_in  => flash_io(1),
    flash_io_out => flash_io(0),
    flash_ncs    => flash_ncs,
    flash_clk    => flash_clk,
    busy         => busy_i,
    debug        => debug_i
--pragma synthesis_off
    ,
    state_out_sim => state_out_sim
--pragma synthesis_on
  );

end architecture behavioral;
