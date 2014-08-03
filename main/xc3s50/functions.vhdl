library IEEE;

use IEEE.STD_LOGIC_1164.all;
use work.constants.all;


package functions is

  -- forward declaration for the functions defined here

  function pack_sprite_record(arg : sprite_record_t) return bram_data_t;
  function unpack_sprite_record(arg : bram_data_t) return sprite_record_t;

  function to_mode(arg : std_logic) return mode_t;
  function to_std_logic(arg : boolean) return std_logic; 
  function to_boolean(arg : std_logic) return boolean;

--pragma synthesis_off
  function hstr(slv: std_logic_vector) return string;
--pragma synthesis_on
  
end functions;

package body functions is

  --
  -- pack a sprite record to a std_logic_vector
  --

  function pack_sprite_record(arg : sprite_record_t) 
    return bram_data_t is
    variable result : bram_data_t;
  begin
  
    -- somewhat fragile direct numeric addressing
    
    result(23 downto 0)    := arg.flash_addr;
    result(41 downto 24)   := arg.sram_addr;
    result(59 downto 42)   := arg.size;
    result(68 downto 60)   := arg.width;
    result(77 downto 69)   := arg.repeat_x;
    result(87 downto 78)   := arg.repeat_y;
    result(88)             := arg.visible;
    result(97 downto 89)   := arg.firstx;
    result(106 downto 98)  := arg.lastx;
    result(116 downto 107) := arg.firsty;
    result(126 downto 117) := arg.lasty;

    return result;
  
  end function pack_sprite_record;

  --    
  -- unpack a std_logic_vector into a record
  --

  function unpack_sprite_record(arg : bram_data_t) 
    return sprite_record_t is
    variable result : sprite_record_t;
  begin
  
    result.flash_addr := arg(23 downto 0);
    result.sram_addr := arg(41 downto 24);
    result.size := arg(59 downto 42);
    result.width := arg(68 downto 60);
    result.repeat_x := arg(77 downto 69);
    result.repeat_y := arg(87 downto 78);
    result.visible := arg(88);
    result.firstx := arg(97 downto 89);
    result.lastx := arg(106 downto 98);
    result.firsty := arg(116 downto 107);
    result.lasty := arg(126 downto 117);

    return result;

  end function unpack_sprite_record;

  --
  -- convert a std_logic into mode_t
  --

  function to_mode(arg : std_logic)
    return mode_t is
    variable result : mode_t;
  begin
  
    if arg = '0' then
      result := mode_passthrough;
    else
      result := mode_sprite;
    end if;
    
    return result;
    
  end function to_mode;

  --
  -- convert a boolean to a std_logic
  --

  function to_std_logic(arg : boolean) 
    return std_logic is 
  begin 
  
    if arg then 
      return '1'; 
    else 
      return '0'; 
    end if; 
  
  end function to_std_logic;

  --
  -- convert a std_logic to a boolean
  --

  function to_boolean(arg : std_logic)
    return boolean is
  begin

    if arg = '1' then
      return true;
    else
      return false;
    end if;

  end function to_boolean;

--pragma synthesis_off

  -- useful hex converter for simulation reporting only
  
  function hstr(slv: std_logic_vector) return string is
       variable hexlen: integer;
       variable longslv : std_logic_vector(67 downto 0) := (others => '0');
       variable hex : string(1 to 20);
       variable fourbit : std_logic_vector(3 downto 0);
     begin
       hexlen := (slv'left+1)/4;
       if (slv'left+1) mod 4 /= 0 then
         hexlen := hexlen + 1;
       end if;
       longslv(slv'left downto 0) := slv;
       for i in (hexlen -1) downto 0 loop
         fourbit := longslv(((i*4)+3) downto (i*4));
         case fourbit is
           when "0000" => hex(hexlen -I) := '0';
           when "0001" => hex(hexlen -I) := '1';
           when "0010" => hex(hexlen -I) := '2';
           when "0011" => hex(hexlen -I) := '3';
           when "0100" => hex(hexlen -I) := '4';
           when "0101" => hex(hexlen -I) := '5';
           when "0110" => hex(hexlen -I) := '6';
           when "0111" => hex(hexlen -I) := '7';
           when "1000" => hex(hexlen -I) := '8';
           when "1001" => hex(hexlen -I) := '9';
           when "1010" => hex(hexlen -I) := 'A';
           when "1011" => hex(hexlen -I) := 'B';
           when "1100" => hex(hexlen -I) := 'C';
           when "1101" => hex(hexlen -I) := 'D';
           when "1110" => hex(hexlen -I) := 'E';
           when "1111" => hex(hexlen -I) := 'F';
           when "ZZZZ" => hex(hexlen -I) := 'z';
           when "UUUU" => hex(hexlen -I) := 'u';
           when "XXXX" => hex(hexlen -I) := 'x';
           when others => hex(hexlen -I) := '?';
         end case;
       end loop;
       return hex(1 to hexlen);
     end hstr;

--pragma synthesis_on
  
end functions;
