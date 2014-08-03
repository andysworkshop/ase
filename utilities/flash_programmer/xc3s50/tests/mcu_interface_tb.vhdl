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
    clk             : in  std_logic;
    clk_inv         : in  std_logic;
    reset           : in  std_logic;
    mcu_data        : in  mcu_bus_type;
    mcu_wr          : in  std_logic;
    flash_io_in     : in  std_logic;
    flash_io_out    : out  std_logic;
    flash_ncs       : out  std_logic;
    flash_clk       : out  std_logic;
    busy            : out  std_logic;
    debug           : out  std_logic;

    state_out_sim         : out mcu_interface_state_type;
    addr_out_sim          : out flash_addr_type;
    mcu_data_byte_out_sim : out std_logic_vector(7 downto 0);
    data_count_out_sim    : out std_logic_vector(7 downto 0);
    write_size_out_sim    : out std_logic_vector(7 downto 0)
  );
end component;


--inputs
signal clk : std_logic := '0';
signal clk_inv : std_logic := '0';
signal reset : std_logic := '0';
signal mcu_data : mcu_bus_type := (others => '0');
signal mcu_wr : std_logic := '0';
signal flash_io_in : std_logic;

--outputs
signal flash_io_out : std_logic;
signal flash_ncs : std_logic := '1';
signal flash_clk : std_logic := '0';
signal busy : std_logic;
signal debug : std_logic;
signal state_out_sim : mcu_interface_state_type;
signal addr_out_sim : flash_addr_type;
signal mcu_data_byte_out_sim : std_logic_vector(7 downto 0);
signal data_count_out_sim : std_logic_vector(7 downto 0);
signal write_size_out_sim : std_logic_vector(7 downto 0);

-- clock period definitions
constant clk_period : time := 25 ns;
constant clk_inv_period : time := 25 ns;

signal data_byte : std_logic_vector(7 downto 0);

begin

-- instantiate the unit under test (uut)
uut: mcu_interface port map (
  clk           => clk,
  clk_inv       => clk_inv,
  reset         => reset,
  mcu_data      => mcu_data,
  mcu_wr        => mcu_wr,
  flash_io_in   => flash_io_in,
  flash_io_out  => flash_io_out,
  flash_ncs     => flash_ncs,
  flash_clk     => flash_clk,
  busy          => busy,
  debug         => debug,
  state_out_sim         => state_out_sim,
  addr_out_sim          => addr_out_sim,
  mcu_data_byte_out_sim => mcu_data_byte_out_sim,
  data_count_out_sim    => data_count_out_sim,
  write_size_out_sim    => write_size_out_sim
);

-- clock process definitions

clk_process : process
begin

  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;

end process;

clk_inv_process : process
begin

  wait for clk_inv_period/2;
  clk_inv <= '0';
  wait for clk_inv_period/2;
  clk_inv <= '1';

end process;

-- stimulus process

stim_proc : process
begin    

  -- write configuration register (serial)

  mcu_data <= "00" & CMD_WRITE_CR;
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_cr_value; 

  mcu_data <= "00" & X"C2";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';

  -- now release the flash

  wait until state_out_sim = wait_idle_1;
  flash_io_in <= '0';
  wait until state_out_sim = reading_command;

  -- bulk erase command

  mcu_data <= "00" & CMD_BULK_ERASE;
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = wait_idle_0; 

  -- simulate the flash busy for this cycle

  wait until state_out_sim = wait_idle_3;
  flash_io_in <= '1';
  
  -- now release the flash

  wait until state_out_sim = wait_idle_1;
  flash_io_in <= '0';
  wait until state_out_sim = reading_command;

  -- program command

  mcu_data <= "00" & CMD_PROGRAM;
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_high;

  -- address 0xAABBCC

  mcu_data <= "00" & X"AA";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_mid;

  mcu_data <= "00" & X"BB";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_low;

  mcu_data <= "00" & X"CC";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_prog_data;

  -- write a page
  
  for i in 0 to 255 loop
    mcu_data <= mcu_bus_type(to_unsigned(i,mcu_bus_type'length));
    mcu_wr <= '0';
    wait for 160ns;
    mcu_wr <= '1';
    wait until (state_out_sim = reading_prog_data or state_out_sim = wait_idle_0);
  end loop;

  -- simulate the flash busy for this cycle

  wait until state_out_sim = wait_idle_3;
  flash_io_in <= '1';
  
  -- now release the flash

  wait until state_out_sim = wait_idle_1;
  flash_io_in <= '0';
  wait until state_out_sim = reading_command;

  -- verify command - all working

  mcu_data <= "00" & CMD_VERIFY;
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_high;

  -- address 0xAABBCC

  mcu_data <= "00" & X"AA";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_mid;

  mcu_data <= "00" & X"BB";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_low;

  mcu_data <= "00" & X"CC";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_vfy_data;

  -- write a page - this is expected to work
  
  for i in 0 to 255 loop
    
    mcu_data <= mcu_bus_type(to_unsigned(i,mcu_bus_type'length));
    data_byte <= std_logic_vector(to_unsigned(i,data_byte'length));
    
    mcu_wr <= '0';
    wait for 160ns;
    mcu_wr <= '1';

    for j in 0 to 7 loop    
      wait until flash_clk='0';
      flash_io_in <= data_byte(7);
      data_byte <= data_byte(6 downto 0) & "0";
      wait until flash_clk='1';
    end loop;

    assert debug = '0' report "expected verify to work but debug = 1";

  end loop;

  -- verify command - fail a byte

  mcu_data <= "00" & CMD_VERIFY;
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_high;

  -- address 0xAABBCC

  mcu_data <= "00" & X"AA";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_mid;

  mcu_data <= "00" & X"BB";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_address_low;

  mcu_data <= "00" & X"CC";
  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';
  wait until state_out_sim = reading_vfy_data;

  -- write a byte - it will mismatch on the second bit

  mcu_data <= "00" & X"AA";
  flash_io_in <= '1';

  mcu_wr <= '0';
  wait for 160ns;
  mcu_wr <= '1';

  wait until flash_clk='0';
  wait until flash_clk='1';
  assert debug = '0' report "expected bit 7 to work but debug = 1";

  wait until flash_clk='0';
  wait until flash_clk='1';
  assert debug = '1' report "expected bit 6 to fail but debug = 0";
  
  -- done

  wait;

end process;

end;
