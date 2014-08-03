library ieee;
library unisim;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

use work.constants.all;
use work.functions.all;


-- mcu_interface is a state machine used to sample a sequence of inputs from the
-- connected MCU. A command is a single byte followed by a command-dependent sequence
-- of data bytes. The protocol follows the popular 8080 interface. Commands take a
-- variable number of clock cycles to execute

entity mcu_interface is

  port(
    
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
    state_out_sim         : out mcu_interface_state_type;
    addr_out_sim          : out flash_addr_type;
    mcu_data_byte_out_sim : out std_logic_vector(7 downto 0);
    data_count_out_sim    : out std_logic_vector(7 downto 0);
    write_size_out_sim    : out std_logic_vector(7 downto 0)
--pragma synthesis_on
  );

end mcu_interface;

architecture behavioral OF mcu_interface is

  signal state_i : mcu_interface_state_type := reading_command;
  signal mcu_wr_sreg_i : std_logic_vector(3 downto 0) := (others => '0');
  signal cmd_i : std_logic_vector(7 downto 0);
  signal flash_addr_i : flash_addr_type;
  signal write_size_i : std_logic_vector(7 downto 0);
  signal cr_value_i : std_logic_vector(7 downto 0);
  signal write_srr_value_i : std_logic_vector(23 downto 0);
  signal flash_clk_ce_i : std_logic := '0';
  signal flash_ncs_i : std_logic := '1';
  signal next_write_bit_i : std_logic;
  signal busy_i : std_logic := '0';
  signal data_count_i : std_logic_vector(7 downto 0);
  signal mcu_data_byte_i : std_logic_vector(7 downto 0);
  signal write_cmd_state_i : mcu_interface_state_type;

begin

  flash_ncs <= flash_ncs_i;
  busy <= busy_i;

--pragma synthesis_off

  state_out_sim <= state_i;
  addr_out_sim <= flash_addr_i;
  mcu_data_byte_out_sim <= mcu_data_byte_i;
  data_count_out_sim <= data_count_i;
  write_size_out_sim <= write_size_i;

--pragma synthesis_on

  inst_ofddrsse : OFDDRRSE port map(
    Q  => flash_clk,
    C0 => clk,
    C1 => clk_inv,
    CE => flash_clk_ce_i,
    R  => '0',
    S  => '0',
    D0 => '1',
    D1 => '0'
  );

  --
  -- handle the interaction with data coming from the mcu
  --
  
  process(clk,reset)
  begin
  
    if rising_edge(clk) then

      if reset = '1' then
      
        state_i <= reading_command;
        mcu_wr_sreg_i <= (others => '0');
        flash_clk_ce_i <= '0'; 
        flash_ncs_i <= '1';
        
      else

        -- shift in the current state of the strobe after this clock
      
        mcu_wr_sreg_i <= mcu_wr_sreg_i(mcu_wr_sreg_i'left-1 downto 0) & mcu_wr;
        
        -- have we received a command

        if mcu_wr_sreg_i = "0011" then

          -- process states that change when the MCU write line is toggled from low to high
        
          case state_i is

            -- read the common starting sequence to program/verify

            when reading_command =>
              
              cmd_i <= mcu_data(7 downto 0);
              
              case mcu_data(7 downto 0) is

                  when CMD_BULK_ERASE =>
                    write_cmd_state_i <= bulk_erase_0;
                    state_i <= write_enable_0;

                  when CMD_WRITE_CR =>
                    state_i <= reading_cr_value; 

                  when others =>
                    state_i <= reading_address_high;

              end case;

            when reading_cr_value =>
              cr_value_i <= mcu_data(7 downto 0);
              write_cmd_state_i <= write_cr_0;
              state_i <= write_enable_0;

            when reading_address_high =>
              flash_addr_i(23 downto 16) <= mcu_data(7 downto 0);
              state_i <= reading_address_mid;

            when reading_address_mid =>
              flash_addr_i(15 downto 8) <= mcu_data(7 downto 0);
              state_i <= reading_address_low;

            when reading_address_low =>
              flash_addr_i(7 downto 0) <= mcu_data(7 downto 0);
              flash_ncs_i <= '0';

              -- act on the command

              case cmd_i is

                  when CMD_PROGRAM =>
                    write_cmd_state_i <= prog_prg0;
                    state_i <= write_enable_0;

                  when CMD_VERIFY =>
                    debug <= '0';           -- reset the fail flag
                    busy_i <= '1';
                  	state_i <= vfy_cmd_0;

                  when others =>
                    null;

              end case;

            when reading_prog_data =>
              mcu_data_byte_i <= mcu_data(7 downto 0);
              write_size_i <= X"08";
              busy_i <= '1';
              state_i <= prog_byte_0;

            when reading_vfy_data =>
              mcu_data_byte_i <= mcu_data(7 downto 0);
              write_size_i <= X"07";
              busy_i <= '1';
              flash_clk_ce_i <= '1';
              state_i <= vfy_byte_0;

            when others =>
              null;

          end case;

        end if;

        -- process changes that execute after a command and parameters
        -- have been read

        case state_i is
        
          -- WREN (06h)
          -- this is a pre-req to bulk-erase and program commands

          when write_enable_0 =>
            busy_i <= '1';
            flash_ncs_i <= '0';
            mcu_data_byte_i <= FLASH_WRITE_ENABLE;
            write_size_i <= X"08";
            state_i <= write_enable_1;

          when write_enable_1 =>
            next_write_bit_i <= mcu_data_byte_i(7);
            mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              state_i <= write_enable_2;
            else
              flash_clk_ce_i <= '1';
              write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            end if;

          when write_enable_2 =>
            flash_ncs_i <= '1';             -- deselect flash
            state_i <= write_cmd_state_i;   -- move to the actual command

          -- BULK ERASE (60h)

          when bulk_erase_0 =>
            flash_ncs_i <= '0';
            mcu_data_byte_i <= FLASH_BULK_ERASE;
            write_size_i <= X"08";
            state_i <= bulk_erase_1;

          when bulk_erase_1 =>
            next_write_bit_i <= mcu_data_byte_i(7);
            mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              state_i <= wait_idle_0;
            else
              flash_clk_ce_i <= '1';
              write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            end if;

          -- WRITE REGISTERS (01h) (01, 00, xx) = [ opcode,sr,cr1]
          -- where xx is 00 for serial access or C2 for quad mode
          -- with LC[1:0] = 11 (<=104MHz)

          when write_cr_0 =>
            flash_ncs_i <= '0';
            write_srr_value_i <= FLASH_WRITE_REGISTERS & X"00" & cr_value_i;
            write_size_i <= X"18";
            state_i <= write_cr_1;

          when write_cr_1 =>
            next_write_bit_i <= write_srr_value_i(23);
            write_srr_value_i <= write_srr_value_i(22 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              state_i <= wait_idle_0;
            else
              flash_clk_ce_i <= '1';
              write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            end if;

          -- PP (02h)

          when prog_prg0 =>
          	flash_ncs_i <= '0';
            mcu_data_byte_i <= FLASH_PAGE_PROGRAM;
            write_size_i <= X"08";
            state_i <= prog_prg1;

          when prog_prg1 =>
            next_write_bit_i <= mcu_data_byte_i(7);
            mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              write_size_i <= X"18";
              state_i <= prog_prg2;
            else
              flash_clk_ce_i <= '1';
              write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            end if;

          -- shift out the 24 bit address

          when prog_prg2 =>
            next_write_bit_i <= flash_addr_i(flash_addr_i'left);
            flash_addr_i <= flash_addr_i(flash_addr_i'left-1 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              busy_i <= '0';
              data_count_i <= "11111111";
              state_i <= reading_prog_data;
            else
              flash_clk_ce_i <= '1';
            end if;

            write_size_i <= std_logic_vector(unsigned(write_size_i)-1);

          -- shift out the 8-bit byte

          when prog_byte_0 =>
            next_write_bit_i <= mcu_data_byte_i(7);
            mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

            if write_size_i = X"00" then

              flash_clk_ce_i <= '0';

              if data_count_i = "00000000" then
                state_i <= wait_idle_0;
              else
                busy_i <= '0';
                state_i <= reading_prog_data;
              end if;

              data_count_i <= std_logic_vector(unsigned(data_count_i)-1);

            else
              flash_clk_ce_i <= '1';
            end if;

            write_size_i <= std_logic_vector(unsigned(write_size_i)-1);

          when vfy_cmd_0 =>
          	flash_ncs_i <= '0';
            mcu_data_byte_i <= FLASH_READ;
            write_size_i <= X"08";
            state_i <= vfy_cmd_1;

          when vfy_cmd_1 =>
            next_write_bit_i <= mcu_data_byte_i(7);
            mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              write_size_i <= X"18";
              state_i <= vfy_cmd_2;
            else
              flash_clk_ce_i <= '1';
              write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            end if;

          -- shift out the 24 bit address

          when vfy_cmd_2 =>
            next_write_bit_i <= flash_addr_i(flash_addr_i'left);
            flash_addr_i <= flash_addr_i(flash_addr_i'left-1 downto 0) & "0";

            if write_size_i = X"00" then
              flash_clk_ce_i <= '0';
              busy_i <= '0';
              data_count_i <= "11111111";
              state_i <= reading_vfy_data;
            else
              flash_clk_ce_i <= '1';
            end if;

            write_size_i <= std_logic_vector(unsigned(write_size_i)-1);

          -- shift in the 8-bit byte and compare

       	  when vfy_byte_0 =>
            if mcu_data_byte_i(7) /= flash_io_in then

              -- failed to verify

              debug <= '1';
              flash_clk_ce_i <= '0';
              state_i <= vfy_byte_done;
            else
            
              mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

              if write_size_i = X"00" then

                flash_clk_ce_i <= '0';

                if data_count_i = "00000000" then
                  state_i <= vfy_byte_done;
                else
                  busy_i <= '0';
                  data_count_i <= std_logic_vector(unsigned(data_count_i)-1);
                  state_i <= reading_vfy_data;
                end if;

              end if;

              write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            
            end if;

          when vfy_byte_done =>
            busy_i <= '0';
            flash_ncs_i <= '1';
            state_i <= reading_command;

          -- RDSR1 (read status register 1)
          -- pause before writing the read status register command

          when wait_idle_0 =>
          	flash_ncs_i <= '1';
          	mcu_data_byte_i <= FLASH_READ_STATUS_REGISTER;
          	write_size_i <= X"08";
          	state_i <= wait_idle_1;

          -- select the flash

          when wait_idle_1 =>
          	flash_ncs_i <= '0';
          	state_i <= wait_idle_2;

          -- clock out the 8 bits of the command

          when wait_idle_2 =>
          	flash_clk_ce_i <= '1';
          	next_write_bit_i <= mcu_data_byte_i(7);
          	mcu_data_byte_i <= mcu_data_byte_i(6 downto 0) & "0";

          	if write_size_i = X"00" then
              write_size_i <= X"08";
          	  state_i <= wait_idle_3;
          	else
            	write_size_i <= std_logic_vector(unsigned(write_size_i)-1);
            end if;

          when wait_idle_3 =>

            if write_size_i = X"01" then
              flash_clk_ce_i <= '0';                -- the next cycle is the last tick
            elsif write_size_i = X"00" then

              mcu_data_byte_i(0) <= flash_io_in;    -- the WIP bit is the last one
              flash_ncs_i <= '1';                   -- done with the flash
              state_i <= wait_idle_4;
      
            end if;

            write_size_i <= std_logic_vector(unsigned(write_size_i)-1);

          when wait_idle_4 =>
            if mcu_data_byte_i(0) = '1' then
              state_i <= wait_idle_0;
            else
              busy_i <= '0';
              state_i <= reading_command;
            end if;

          when others =>
            null;

        end case;

      end if;              

    end if;
      
  end process;


  flash_writer : process(clk) is
  begin
  
    if falling_edge(clk) then
      flash_io_out <= next_write_bit_i;
    end if;

  end process flash_writer;
  
end architecture behavioral;

