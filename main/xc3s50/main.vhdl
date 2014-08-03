-- This file is a part of the firmware supplied with Andy's Workshop Sprite Engine (ASE)
-- Copyright (c) 2014 Andy Brown <www.andybrown.me.uk>
-- Please see website for licensing terms.

library ieee;
library UNISIM;

use ieee.std_logic_1164.all;
use work.constants.all;
use work.functions.all;
use UNISIM.vcomponents.all;


--
-- main is the top level entity that instantiates all lower level components, connects together their
-- signals and handles asynchronous arbitration for the bi-direction buses (SRAM, flash)
--

entity main is
  port(
  
    -- the clock and FPGA control signals
    
    clk40 : in  std_logic;          -- 40Mhz oscillator
    reset : in  std_logic;          -- overall reset
    busy  : out std_logic;          -- safe to write sprite list on falling edge

    -- sram control signals
    
    sram_addr : out sram_byte_addr_t;    -- 19 bit address bus
    sram_data : inout sram_data_t;       -- 8 bit data bus
    sram_nwr  : out std_logic;           -- write enable
    
    -- LCD control signals
    
    lcd_wr  : out std_logic;         -- write strobe
    lcd_rs  : out std_logic;         -- register select
    lcd_te  : in  std_logic;         -- tearing effect
    lcd_db  : out lcd_bus_t;         -- 8 bit data bus (latched)
    lcd_ale : out std_logic;         -- latch enable
    
    -- MCU command interface

    mcu_wr   : in std_logic;       -- write enable
    mcu_data : in mcu_bus_t;       -- 10-bit data bus

    -- flash IO interface

    flash_ncs : out   std_logic;                      -- flash chip select
    flash_clk : out   std_logic;                      -- flash clock (100MHz)
    flash_io  : inout std_logic_vector(3 downto 0);   -- 4-bit flash bus

    -- debugging test port

    debug : out std_logic

--pragma synthesis_off
    ;
    mcu_state_out_sim : out mcu_interface_state_t;
    sprite_writer_state_out_sim : out sprite_writer_state_t
--pragma synthesis_on
  );
end main;


architecture behavioral of main is

  --
  -- clock_generator is a DCM configured with the Xilinx IP core GUI
  --

	component clock_generator port (
    clkin_in        : in std_logic;
    clkfx_out       : out std_logic;
    clkfx180_out    : out std_logic;
    clkin_ibufg_out : out std_logic;
    clk0_out        : out std_logic
	);
	end component;

  --
  -- reset_conditioner converts the async reset input to a clocked version
  --

  component reset_conditioner port(
    clk100            : in  std_logic;
    reset             : in  std_logic;
    conditioned_reset : out  std_logic
  );
  end component;

  --
  -- frame_counter creates a 0/1 output from the asynchronous TE signal
  --

  component frame_counter port(
    
    -- inputs
      
    clk100 : in std_logic;
    reset  : in std_logic;
    lcd_te : in std_logic;
      
    -- outputs
    
    frame_index : out std_logic
  );
  end component;

  --
  -- manage ownership of the LCD bi-directional data bus. mode_passthrough
  -- grants ownership to lcd_sender and mode_sprite grants access to frame_writer
  --

  component lcd_arbiter port(
  
    -- inputs

    clk100 : in std_logic;
    mode   : in mode_t;

    lcd_sender_db  : in lcd_bus_t;
    lcd_sender_wr  : in std_logic;
    lcd_sender_ale : in std_logic;
    lcd_sender_rs  : in std_logic;

    frame_writer_db  : in lcd_bus_t;
    frame_writer_wr  : in std_logic;
    frame_writer_ale : in std_logic;

    -- outputs

    lcd_db  : out lcd_bus_t;
    lcd_wr  : out std_logic;
    lcd_ale : out std_logic;
    lcd_rs  : out std_logic
  );
  end component;

  --
  -- block RAM component to hold the sprite definitions. this is configured using
  -- the Xilinx coregen utility
  --

  component sprite_memory
  port (
    clka  : in std_logic;
    ena   : in std_logic;
    wea   : in std_logic_vector(0 downto 0);
    addra : in sprite_number_t;
    dina  : in bram_data_t;
    douta : out bram_data_t;
    clkb  : in std_logic;
    enb   : in std_logic;
    web   : in std_logic_vector(0 downto 0);
    addrb : in sprite_number_t;
    dinb  : in bram_data_t;
    doutb : out bram_data_t
  );
  end component;

  -- 
  -- send a 16-bit value to the LCD via the 8-bit bus and latch
  --

  component lcd_sender port(
    -- inputs
    
    clk100 : in std_logic;
    reset  : in std_logic;
    data   : in std_logic_vector(15 downto 0);
    go     : in std_logic;
    
    -- outputs
    
    db   : out std_logic_vector(7 downto 0);
    wr   : out std_logic;
    ale  : out std_logic;
    busy : out boolean
  );
  end component;

  --
  -- handle incoming commands from the MCU
  --
  
  component mcu_interface port(
    -- inputs
    
    clk100          : in std_logic;
    reset           : in std_logic;
    mcu_data        : in mcu_bus_t;
    mcu_wr          : in std_logic;
    bram_dout       : in sprite_record_t;
    lcd_sender_busy : in boolean;
    
    -- outputs
    
    lcd_rs          : out std_logic;
    lcd_sender_go   : out std_logic;
    lcd_sender_data : out lcd_data_t;
    bram_wr         : out std_logic;
    bram_addr       : out sprite_number_t;
    bram_din        : out sprite_record_t;
    mode            : out mode_t;
    debug           : out std_logic

--pragma synthesis_off
    ;
    state_out_sim : out mcu_interface_state_t
--pragma synthesis_on
  );
  end component;
  
  -- frame_writer transfers data from SRAM to the LCD. The setting of the display
  -- window to full screen and the issue of the LCDs 'begin write data' command has
  -- already happened when the mode was switched to 'sprite'

  component frame_writer port(
  
    -- inputs

    reset       : in std_logic;
    clk100      : in std_logic;
    mode        : in mode_t;
    frame_index : in std_logic;
    sram_data   : in sram_data_t;

    -- outputs

    lcd_wr   : out std_logic;         -- write strobe
    lcd_db   : out lcd_bus_t;      -- 8 bit data bus (latched)
    lcd_ale  : out std_logic;         -- latch enable

    sram_addr : out sram_byte_addr_t;

    debug : out std_logic

  --pragma synthesis_off
    ;
    state_out_sim : out frame_writer_state_t
  --pragma synthesis_on
  );
  end component;

  -- sprite_writer makes a pass through the BRAM sprite records and transfers
  -- each visible sprite from flash to SRAM. SRAM is not cleared down so the
  -- first visible sprite should be the 'background' and be set to fill the
  -- whole active display area.

  component sprite_writer port(
    -- inputs
    
    reset         : in  std_logic;
    clk100        : in  std_logic;
    clk100_inv    : in  std_logic;
    mode          : in  mode_t;
    frame_index   : in  std_logic;
    flash_io_in   : in  flash_io_bus_t;
    bram_dout     : in  sprite_record_t;
    
    -- outputs
    
    sram_addr     : out sram_byte_addr_t;
    sram_data     : out sram_data_t;
    sram_nwr      : out std_logic;
    flash_ncs     : out std_logic;
    flash_io_out  : out flash_io_bus_t;
    flash_io_mode : out flash_io_mode_t;
    flash_clk     : out std_logic;
    bram_addr     : out sprite_number_t;
    bram_en_mcu_interface : out std_logic;
    bram_en_sprite_writer : out std_logic;
    busy          : out boolean;
    debug         : out std_logic

--pragma synthesis_off
    ;
    state_out_sim       : out sprite_writer_state_t;
    last_pixel_out_sim  : out pixel_t;
    sprite_size_out_sim : out sprite_size_t;
    sram_next_x_out_sim : out sram_byte_addr_t    
--pragma synthesis_on
  );
  end component;

  -- debugging

  signal debug_i : std_logic := '0';
  
  -- clock definitions and constraints
  
  signal clk100       : std_logic;
  signal clk100_inv   : std_logic;
  
  attribute period : string;
  attribute period of clk100     : signal is "10 ns";

  signal conditioned_reset_i : std_logic := '0';
  signal frame_index_i       : std_logic := '0';
  signal mode_i              : mode_t := mode_passthrough;

  -- lcd sender signals
  
  signal lcd_sender_db_i   : lcd_bus_t;
  signal lcd_sender_data_i : lcd_data_t;
  signal lcd_sender_wr_i   : std_logic := '1';
  signal lcd_sender_ale_i  : std_logic := '0';
  signal lcd_sender_busy_i : boolean := false;
  signal lcd_sender_go_i   : std_logic := '0';
 
  -- mcu interface signals
  
  signal mcu_interface_rs_i   : std_logic := '0';
 
  -- BRAM signals (port A: mcu_interface, RW)
  
  signal bram_a_dout_i     : sprite_record_t;
  signal bram_a_dout_i_tmp : bram_data_t;
  signal bram_a_din_i      : sprite_record_t;
  signal bram_a_addr_i     : sprite_number_t := (others => '0');
  signal bram_a_wr_i       : std_logic_vector(0 downto 0) := (others => '0');
  signal bram_a_en_i       : std_logic := '0';
  
  -- BRAM signals (port B: sprite_writer, R)
  
  signal bram_b_dout_i     : sprite_record_t;
  signal bram_b_dout_i_tmp : bram_data_t;
  signal bram_b_addr_i     : sprite_number_t := (others => '0');
  signal bram_b_wr_i       : std_logic_vector(0 downto 0) := (others => '0');
  signal bram_b_en_i       : std_logic := '0';

  -- sprite_writer signals
  
  signal sram_addr_sprite_writer_i : sram_byte_addr_t;
  signal sram_data_sprite_writer_i : sram_data_t;
  signal sram_nwr_sprite_writer_i  : std_logic := SRAM_READ;
  signal sprite_writer_busy_i      : boolean := false;
  signal flash_io_out_i            : flash_io_bus_t;
  signal flash_io_oe_i             : flash_io_bus_t;
  signal flash_io_mode_i           : flash_io_mode_t;

  -- frame_writer signals

  signal sram_addr_frame_writer_i : sram_byte_addr_t;
  signal frame_writer_lcd_wr_i    : std_logic := '1';
  signal frame_writer_lcd_db_i    : lcd_bus_t;
  signal frame_writer_lcd_ale_i   : std_logic;

--pragma synthesis_off
  signal mcu_interface_state_out_sim_i : mcu_interface_state_t;
  signal sprite_writer_state_out_sim_i : sprite_writer_state_t;
--pragma synthesis_on

begin

--pragma synthesis_off
  mcu_state_out_sim <= mcu_interface_state_out_sim_i;
  sprite_writer_state_out_sim <= sprite_writer_state_out_sim_i;
--pragma synthesis_on

  -- continuous assignment of the SRAM signals

  sram_nwr <= sram_nwr_sprite_writer_i when frame_index_i = '1' else SRAM_READ;
  sram_data <= sram_data_sprite_writer_i when sram_nwr_sprite_writer_i = SRAM_WRITE and frame_index_i='1' else (others => 'Z');
  sram_addr <= sram_addr_frame_writer_i when frame_index_i = '0' else sram_addr_sprite_writer_i;

  --- continuous assignment of the flash signals

  flash_io(0) <= flash_io_out_i(0) when flash_io_oe_i(0) = '1' else 'Z';
  flash_io(1) <= flash_io_out_i(1) when flash_io_oe_i(1) = '1' else 'Z';
  flash_io(2) <= flash_io_out_i(2) when flash_io_oe_i(2) = '1' else 'Z';
  flash_io(3) <= flash_io_out_i(3) when flash_io_oe_i(3) = '1' else 'Z';

  -- the BRAM module outputs to a std_logic_vector but we want to address it
  -- as a record so this hack does that.

  bram_a_dout_i <= unpack_sprite_record(bram_a_dout_i_tmp);
  bram_b_dout_i <= unpack_sprite_record(bram_b_dout_i_tmp);

  -- register the busy output

  busy <= to_std_logic(sprite_writer_busy_i);

  -- never write to the B port

  bram_b_wr_i(0) <= '0';

  -- debug output

  debug <= debug_i;

  -- instantiate the components

  inst_clock_generator : clock_generator port map(
		clkin_in        => clk40,
		clkfx_out       => clk100,
		clkfx180_out    => clk100_inv,
		clkin_ibufg_out => open,
		clk0_out        => open
	);

  inst_reset_conditioner : reset_conditioner port map(
    clk100            => clk100,
    reset             => reset,
    conditioned_reset => conditioned_reset_i
  );

  inst_frame_counter : frame_counter port map(
    clk100      => clk100,
    reset       => reset,
    lcd_te      => lcd_te,
    frame_index => frame_index_i
  );
  
  inst_lcd_sender : lcd_sender port map(
    clk100  => clk100,
    reset   => conditioned_reset_i,
    data    => lcd_sender_data_i,
    go      => lcd_sender_go_i,
    db      => lcd_sender_db_i,
    wr      => lcd_sender_wr_i,
    ale     => lcd_sender_ale_i,
    busy    => lcd_sender_busy_i
  );
  
  inst_mcu_interface : mcu_interface port map(
    clk100          => clk100,
    reset           => conditioned_reset_i,
    mcu_data        => mcu_data,
    mcu_wr          => mcu_wr,
    bram_dout       => bram_a_dout_i,
    lcd_sender_busy => lcd_sender_busy_i,
    lcd_rs          => mcu_interface_rs_i,
    lcd_sender_go   => lcd_sender_go_i,
    lcd_sender_data => lcd_sender_data_i,
    bram_wr         => bram_a_wr_i(0),
    bram_addr       => bram_a_addr_i,
    bram_din        => bram_a_din_i,
    mode            => mode_i,
    debug           => open
--pragma synthesis_off
    ,
    state_out_sim => mcu_interface_state_out_sim_i
--pragma synthesis_on
  );

  -- Instantiate the sprite memory block RAM
  
  inst_sprite_memory : sprite_memory port map(
    clka  => clk100,
    ena   => bram_a_en_i,
    wea   => bram_a_wr_i,
    addra => bram_a_addr_i,
    dina  => pack_sprite_record(bram_a_din_i),
    douta => bram_a_dout_i_tmp,
    clkb  => clk100,
    enb   => bram_b_en_i,
    web   => bram_b_wr_i,
    addrb => bram_b_addr_i,
    dinb  => (others => '0'),
    doutb => bram_b_dout_i_tmp
  );

  inst_frame_writer : frame_writer port map(
    reset       => conditioned_reset_i,
    clk100      => clk100,
    mode        => mode_i,
    frame_index => frame_index_i,
    sram_data   => sram_data,
    lcd_wr      => frame_writer_lcd_wr_i,
    lcd_db      => frame_writer_lcd_db_i,
    lcd_ale     => frame_writer_lcd_ale_i,
    sram_addr   => sram_addr_frame_writer_i,
    debug       => open
  );

  inst_sprite_writer : sprite_writer port map(
    reset         => conditioned_reset_i,
    clk100        => clk100,
    clk100_inv    => clk100_inv,
    mode          => mode_i,
    frame_index   => frame_index_i,
    flash_io_in   => flash_io,
    bram_dout     => bram_b_dout_i,
    sram_addr     => sram_addr_sprite_writer_i,
    sram_data     => sram_data_sprite_writer_i,
    sram_nwr      => sram_nwr_sprite_writer_i,
    flash_ncs     => flash_ncs,
    flash_io_out  => flash_io_out_i,
    flash_io_mode => flash_io_mode_i,
    flash_clk     => flash_clk,
    bram_addr     => bram_b_addr_i,
    bram_en_mcu_interface => bram_a_en_i,
    bram_en_sprite_writer => bram_b_en_i,
    busy          => sprite_writer_busy_i,
    debug         => open
--pragma synthesis_off
    ,
    state_out_sim => sprite_writer_state_out_sim_i
--pragma synthesis_on
  );

  inst_lcd_arbiter : lcd_arbiter port map(
    clk100           => clk100,
    mode             => mode_i,
    lcd_sender_db    => lcd_sender_db_i,
    lcd_sender_wr    => lcd_sender_wr_i,
    lcd_sender_ale   => lcd_sender_ale_i,
    lcd_sender_rs    => mcu_interface_rs_i,
    frame_writer_db  => frame_writer_lcd_db_i,
    frame_writer_wr  => frame_writer_lcd_wr_i,
    frame_writer_ale => frame_writer_lcd_ale_i,
    lcd_db           => lcd_db,
    lcd_wr           => lcd_wr,
    lcd_ale          => lcd_ale,
    lcd_rs           => lcd_rs
  );

  -- the flash device clocks data in on the rising edge so we must make it available on the
  -- falling edge so that setup and hold conditions are satisified. We want to do as little
  -- as possible here to avoid creating timing dependencies between the rising and falling
  -- edges of clk100
  
  flash_writer : process(clk100) is
  begin
  
    if falling_edge(clk100) then

      -- a 1 bit in the OE vector indicates that data in the position in flash_io_out_i
      -- should be written to the pin. A zero places that pin in high-Z (see the continuous
      -- assignment section above). This faff is to avoid inferring internal tristates.

      case flash_io_mode_i is
        
        when writing_1bit =>
          flash_io_oe_i <= "0001";

        when writing_4bit =>
          flash_io_oe_i <= "1111";

        when others =>
          flash_io_oe_i <= "0000";
      
      end case;

    end if;

  end process flash_writer;

end architecture behavioral;
