-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


--
-- fpga_sram is a continually looping test of all the locations in the SRAM device. It will write a changing
-- value to every location in the device and then read back from those locations to test the data integrity.
-- if all is good then 'status' will remain at '0' otherwise it will go to '1' and stay there.
--

entity fpga_sram is
port(
  clk40  : in  std_logic;     -- 40MHz input from the oscillator
  status : out std_logic;     -- output test status (1 = bad)

  -- sram control signals
  
  sram_addr : out std_logic_vector(18 downto 0);    -- 19 bit address bus
  sram_data : inout std_logic_vector(7 downto 0);   -- 8 bit data bus
  sram_nwr  : out std_logic                         -- write enable
);
end fpga_sram;

architecture behavioural of fpga_sram is

  component clock_generator
    port(
      clkin_in : in std_logic;          
      clkfx_out : out std_logic;
      clkin_ibufg_out : out std_logic;
      clk0_out : out std_logic
  );
  end component;

  type state_type is (
      pre_write_0,pre_write_1,write_1,write_2,
      pre_read_0,read_1,read_2,read_3,read_4
  );

  constant sram_read  : std_logic := '1';
  constant sram_write : std_logic := '0'; 

  signal clk100 : std_logic;
  attribute period : string;
  attribute period of clk100     : signal is "10 ns";

  signal state_i : state_type := pre_write_0;
  signal value_base_i,sram_value_i,the_data : std_logic_vector(7 downto 0) := (others => '0');
  signal sram_nwr_i : std_logic := sram_read;
  signal sram_addr_i : std_logic_vector(18 downto 0);
  signal sram_data_i : std_logic_vector(7 downto 0);
  signal status_i : std_logic := '0';

begin

  -- instantiate the DCM that generates the 100MHz internal clock

  inst_clock_generator: clock_generator port map(
    clkin_in => clk40,
    clkfx_out => clk100,
    clkin_ibufg_out => open,
    clk0_out => open
  );

  -- continuous assignment of the SRAM signals including the bidirectional data bus

  sram_nwr <= sram_nwr_i;
  sram_addr <= sram_addr_i;
  sram_data <= sram_data_i when sram_nwr_i = sram_write else (others => 'Z');
  status <= status_i;

  process(clk100) is
  begin

    if rising_edge(clk100) then

      case state_i is

        -- writing to the array

        when pre_write_0 =>
          value_base_i <= (others => '0');
          state_i <= pre_write_1;

        when pre_write_1 =>                    -- address setup
          sram_value_i <= value_base_i;
          sram_addr_i <= (others => '0');
          sram_nwr_i <= sram_read;
          state_i <= write_1;

        when write_1 =>
          sram_data_i <= sram_value_i;         -- data setup, write enable
          sram_nwr_i <= sram_write;
          state_i <= write_2;

        when write_2 =>
          sram_nwr_i <= sram_read;             -- write disable, address update
          if sram_value_i = "11101101" then
            sram_value_i <= (others => '0');
          else
            sram_value_i <= std_logic_vector(unsigned(sram_value_i)+1);
          end if;

          if sram_addr_i = "1111111111111111111" then
            state_i <= pre_read_0;
          else
            sram_addr_i <= std_logic_vector(unsigned(sram_addr_i)+1);
            state_i <= write_1;
          end if;

        -- reading from the array

        when pre_read_0 =>
          sram_value_i <= value_base_i;
          sram_addr_i <= (others => '0');
          state_i <= read_1;
          sram_nwr_i <= sram_read;

        when read_1 =>
          state_i <= read_2;

        when read_2 =>
          the_data <= sram_data;
          state_i <= read_3;

        when read_3 =>
          if the_data /= sram_value_i then
            status_i <= '1';
          end if;

          if sram_value_i = "11101101" then
            sram_value_i <= (others => '0');
          else
            sram_value_i <= std_logic_vector(unsigned(sram_value_i)+1);
          end if;

          state_i <= read_4;

        when read_4 =>

          if sram_addr_i = "1111111111111111111" then
            state_i <= pre_write_1;
            value_base_i <= std_logic_vector(unsigned(value_base_i)+1);
          else
            sram_addr_i <= std_logic_vector(unsigned(sram_addr_i)+1);
            state_i <= read_1;
          end if;

        when others => null;

      end case;
    end if;
  end process;
end behavioural;
