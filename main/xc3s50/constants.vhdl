-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;

use ieee.std_logic_1164.all;


package constants is

  --
  -- state machine states for lcd_sender
  --

  type lcd_sender_state_t is (
    undefined,
    idle, 
    t10,t20,t30,t40,t50,t60,t70
  );

  --
  -- state machine states for fifo_writer
  --

  type fifo_writer_state_t is(
    idle,write_0,write_1
  );

  --
  -- state machine states for fifo_reader
  --

  type fifo_reader_state_t is(
    idle,read_0,read_1
  );

  --
  -- state machine states for mcu_interface
  --

  type mcu_interface_state_t is (
    undefined,
    passthrough_0,passthrough_1,passthrough_2,
    
    reading_cmd,
    reading_showhide_sprite,
    reading_load_sprite_number,reading_load_sprite_addr_low,reading_load_sprite_addr_high,reading_load_sprite_width,
      reading_load_sprite_pixel_size_low,reading_load_sprite_pixel_size_high,
      reading_load_sprite_flash_addr_low,reading_load_sprite_flash_addr_mid,reading_load_sprite_flash_addr_high,
      reading_load_sprite_repeat_x,reading_load_sprite_repeat_y,reading_load_sprite_visible,
      reading_load_sprite_first_x,reading_load_sprite_last_x,reading_load_sprite_first_y,reading_load_sprite_last_y,
    reading_mode,
    reading_move_sprite,reading_move_addr_low,reading_move_addr_high,
    reading_move_first_x,reading_move_last_x,reading_move_first_y,reading_move_last_y,
 
    execute_showhide_0,execute_showhide_1,execute_showhide_2,
    execute_load_sprite_0,execute_load_sprite_1,
    execute_move_0,execute_move_1,execute_move_2,
    execute_move_partial_0,execute_move_partial_1
  );
  
  --
  -- state machine states for the sprite_writer
  --
   
  type sprite_writer_state_t is (
    undefined,
    idle,
    bram_0,bram_1,bram_2,
    outer_setup_0,outer_setup_1,
    cmd_7,cmd_6,cmd_5,cmd_4,cmd_3,cmd_2,cmd_1,cmd_0,
    addr_5,addr_4,addr_3,addr_2,addr_1,addr_0,
    mode_1,mode_0,
    dummy_4,dummy_3,dummy_2,dummy_1,dummy_0,
    data_out_pause0,data_out_pause1,
    first_pixel_read_0,first_pixel_read_1,first_pixel_read_2,first_pixel_read_3,
    pixel_read_0,pixel_read_1,pixel_read_2,pixel_read_3,
    last_pixel_write_0,last_pixel_write_1,last_pixel_write_2,
    done_this_sprite_0,done_this_sprite_1,done_this_sprite_2,
    next_sprite
  );
  
  --
  -- state machine states for the frame writer
  --

  type frame_writer_state_t is(
    undefined,
    idle,
    setup_0,setup_1,
    pre_0,pre_1,pre_2,pre_3,
    state_0,state_10,state_20,state_30,state_40,state_50,state_60
  );

  --
  -- type to hold the two possible modes
  --
  
  type mode_t is (
    mode_passthrough,mode_sprite
  );

  --
  -- current mode of operation for the flash
  -- 
  
  type flash_io_mode_t is (
    reading,
    writing_1bit,
    writing_4bit
  );

  --
  -- SRAM mode constants for the nwr signal
  --

  constant SRAM_READ  : std_logic := '1';
  constant SRAM_WRITE : std_logic := '0';
  
  --
  -- limiting constants
  --

  constant MAX_SPRITES   : integer := 512;
  constant LAST_SPRITE   : std_logic_vector := "111111111";
  constant NUM_PIXELS    : std_logic_vector := "111000010000000000";    -- 230400
  constant SCREEN_WIDTH  : std_logic_vector := "101101000";    -- 360
  constant SCREEN_HEIGHT : std_logic_vector := "1010000000";   -- 640
  constant TRANSPARENT   : std_logic_vector := "0001111111111000";
  
  --
  -- subtype for the MCU bus
  --

  subtype mcu_bus_t is std_logic_vector(9 downto 0);
  
  --
  -- subtypes for the lcd sender data
  --

  subtype lcd_data_t is std_logic_vector(15 downto 0);
  subtype lcd_bus_t is std_logic_vector(7 downto 0);
  
  --
  -- subtypes for the various bit vectors
  --

  subtype bram_data_t       is std_logic_vector(126 downto 0);
  subtype sprite_number_t   is std_logic_vector(8 downto 0);
  subtype flash_addr_t      is std_logic_vector(23 downto 0);
  subtype sram_pixel_addr_t is std_logic_vector(17 downto 0);
  subtype sram_byte_addr_t  is std_logic_vector(18 downto 0);
  subtype sram_data_t       is std_logic_vector(7 downto 0);
  subtype sprite_size_t     is std_logic_vector(17 downto 0);
  subtype sprite_width_t    is std_logic_vector(8 downto 0);
  subtype byte_width_t      is std_logic_vector(9 downto 0);
  subtype sprite_height_t   is std_logic_vector(9 downto 0);
  subtype pixel_t           is std_logic_vector(15 downto 0);
  subtype flash_io_bus_t    is std_logic_vector(3 downto 0);

  --
  -- Structure of a sprite in BRAM. Total size is 127 bits
  --

  type sprite_record_t is record
    
    -- physical address in flash where the sprite starts (24 bits)
    flash_addr : flash_addr_t;
    
    -- pixel address in SRAM where we start writing out the sprite (18 bits)
    sram_addr : sram_pixel_addr_t;
    
    -- size in pixels of this sprite (18 bits)
    size : sprite_size_t;

    -- width of this sprite (9 bits)
    width : sprite_width_t;
    
    -- number of times to repeat in the X-direction (9 bits)
    repeat_x : sprite_width_t;

    -- number of times to repeat in the Y-direction (10 bits)
    repeat_y : sprite_height_t;

    -- visible (enabled) flag (1 bit)
    visible : std_logic;

    -- firstx is the offset of the first pixel to be displayed if the sprite is partially off the left
    firstx : sprite_width_t;

    -- lastx is the offset of the last pixel to be displayed if the sprite is partially off the right
    lastx : sprite_width_t;

    -- firsty is the offset of the first pixel to be displayed if the sprite is partially off the top
    firsty : sprite_height_t;

    -- lasty is the offset of the last pixel to be displayed if the sprite is partially off the bottom
    lasty : sprite_height_t;

  end record;

  --
  -- a null sprite record
  --

  constant null_sprite_record : bram_data_t := (others => '0');

  --
  -- commands accepted by mcu_interface
  --

  constant CMD_PASSTHROUGH  : std_logic_vector(7 downto 0) := X"A2";
  constant CMD_SHOW         : std_logic_vector(7 downto 0) := X"A3";
  constant CMD_HIDE         : std_logic_vector(7 downto 0) := X"A4";
  constant CMD_LOAD         : std_logic_vector(7 downto 0) := X"A5";
  constant CMD_MOVE         : std_logic_vector(7 downto 0) := X"A6";

end constants;

package body constants is
end constants;
