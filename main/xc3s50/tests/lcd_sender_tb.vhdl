library IEEE;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.constants.all;


entity lcd_sender_tb is
end lcd_sender_tb;


architecture behavior of lcd_sender_tb is 

  component lcd_sender is
  port(
    -- inputs
    
    clk100 : in std_logic;                        -- 100MHz clock
    reset  : in std_logic;                        -- synchronous reset
    data   : in std_logic_vector(15 downto 0);    -- input data
    go     : in std_logic;                        -- toggle trigger
    
    -- outputs
    
    db   : out std_logic_vector(7 downto 0);      -- 8 bit data for the latch
    wr   : out std_logic;                         -- LCD WR signal  
    ale  : out std_logic;                         -- latch enable
    busy : out boolean;                           -- busy flag
    
    -- simulation outputs
    
    state_out_sim : out lcd_sender_state_t
  );
  end component;

  -- inputs
  
  signal clk100 : std_logic := '0';
  signal reset : std_logic := '0';
  signal data : std_logic_vector(15 downto 0) := (others => '0');
  signal go : std_logic := '0';
  
  -- outputs
    
  signal db   : std_logic_vector(7 downto 0);
  signal wr   : std_logic;
  signal ale  : std_logic;
  signal busy : boolean;
  
  -- simulation outputs
  
  signal state_out_sim : lcd_sender_state_t;
  
  -- constants
  
  constant clk100_period : time := 10ns;
  
begin

  uut : lcd_sender port map (
    
    clk100 => clk100,
    reset => reset,
    data => data,
    go => go,
    
    db => db,
    wr => wr,
    ale => ale,
    busy => busy,
    
    state_out_sim => state_out_sim
  );

  clk_process : process
  begin
    clk100 <= '0';
    wait for clk100_period/2;
    clk100 <= '1';
    wait for clk100_period/2;
  end process;
  
  stim_proc : process
  begin
  
    reset <= '1';
    wait for 20ns;
    reset <= '0';
    wait for 20ns;
    
    data <= X"1234";
    go <= '1';
    
    wait until busy = false;
    
    data <= X"ABCD";
    go <= '0';
    
    wait;
    
  end process;

end architecture;

