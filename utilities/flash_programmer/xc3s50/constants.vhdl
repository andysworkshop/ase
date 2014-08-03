library ieee;

use ieee.std_logic_1164.all;


package constants is

  --
  -- state machine states for mcu_interface
  --
  
  type mcu_interface_state_type is (
    reading_command,
    reading_address_low,reading_address_mid,reading_address_high,
    reading_prog_data,reading_vfy_data,

    write_enable_0,write_enable_1,write_enable_2,
    prog_prg0,prog_prg1,prog_prg2,

    prog_byte_0,
    wait_idle_0,wait_idle_1,wait_idle_2,wait_idle_3,wait_idle_4,

    vfy_cmd_0,vfy_cmd_1,vfy_cmd_2,
    vfy_byte_0,vfy_byte_done,
    
    reading_cr_value,
    write_cr_0,write_cr_1,

    bulk_erase_0,
    bulk_erase_1
  );
  
  -- subtypes for bit vectors
  
  subtype mcu_bus_type      is std_logic_vector(9 downto 0);
  subtype flash_addr_type   is std_logic_vector(23 downto 0);
  subtype flash_io_bus_type is std_logic_vector(3 downto 0);
  
  -- commands accepted by mcu_interface
  
  constant CMD_VERIFY     : std_logic_vector(7 downto 0) := X"00";
  constant CMD_PROGRAM    : std_logic_vector(7 downto 0) := X"01";
  constant CMD_BULK_ERASE : std_logic_vector(7 downto 0) := X"02";
  constant CMD_WRITE_CR   : std_logic_vector(7 downto 0) := X"03";

  -- flash commands

  constant FLASH_WRITE_REGISTERS      : std_logic_vector(7 downto 0) := X"01";
  constant FLASH_PAGE_PROGRAM         : std_logic_vector(7 downto 0) := X"02";
  constant FLASH_WRITE_ENABLE         : std_logic_vector(7 downto 0) := X"06";
  constant FLASH_READ_STATUS_REGISTER : std_logic_vector(7 downto 0) := X"05";
  constant FLASH_BULK_ERASE           : std_logic_vector(7 downto 0) := X"60";
  constant FLASH_READ                 : std_logic_vector(7 downto 0) := X"03";

end constants;

package body constants is
end constants;
