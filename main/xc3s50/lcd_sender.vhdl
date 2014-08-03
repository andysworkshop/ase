library IEEE;

use ieee.std_logic_1164.all;

use work.constants.all;


--
-- lcd_sender is a utility for writing out a 16-bit value to the LCD data bus. It's used in passthrough
-- mode. The user sets up 'data' and toggles 'go' to trigger it. When it's done the 'busy' output
-- will go low. The user is assumed to have set up 'RS' themselves.
--

entity lcd_sender is
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
    busy : out boolean                            -- busy flag

    --pragma synthesis_off
    ;
    state_out_sim : out lcd_sender_state_t
    
    --pragma synthesis_on
    );
end lcd_sender;

architecture behavioral of lcd_sender is

  -- internal signals
  
  signal wr_i : std_logic := '1';
  signal ale_i : std_logic := '0';
  signal busy_i : boolean := false;
  signal db_i : std_logic_vector(7 downto 0);
  signal last_go_i : std_logic := '0';
  signal state_i : lcd_sender_state_t := undefined;
 
begin

  --pragma synthesis_off
  state_out_sim <= state_i;
  --pragma synthesis_on
  
  -- register the outputs

  wr <= wr_i;
  db <= db_i;
  ale <= ale_i;
  busy <= busy_i;
  
  --
  -- state machine used to handle the actual writing.
  -- Toggle the 'go' input to kick it off. It will take 70ns to complete.
  -- 'busy' output goes high for those 70ns.
  --
  
  process(clk100,reset)
  begin

    if rising_edge(clk100) then
    
      if reset = '1' then
  
        -- reset the state machine and the 'go' flag

        state_i <= idle;
        last_go_i <= '0';
        busy_i <= false;
        
      else
      
        case state_i is
        
          when idle =>
        
            -- start the process when the 'go' flag changes. start it immediately on this cycle

            if last_go_i /= go then

              -- reset WR and open the latch

              wr_i <= '0';
              ale_i <= '1';

              -- first 8 bits of data

              db_i(7) <= data(0);
              db_i(6) <= data(2);
              db_i(5) <= data(4);
              db_i(4) <= data(6);
              db_i(3) <= data(8);
              db_i(2) <= data(10);
              db_i(1) <= data(12);
              db_i(0) <= data(14);

              -- we're busy

              busy_i <= true;
              state_i <= t10;
              
            end if;
            
          when t10 =>

            -- close the latch

            ale_i <= '0';
            state_i <= t20;
            
          when t20 =>

            -- next 8 bits of data and hold for another 10ns

            db_i(7) <= data(15);
            db_i(6) <= data(13);
            db_i(5) <= data(11);
            db_i(4) <= data(9);
            db_i(3) <= data(7);
            db_i(2) <= data(5);
            db_i(1) <= data(3);
            db_i(0) <= data(1);
            state_i <= t30;
            
          when t30 =>
            state_i <= t40;
            
          when t40 =>
            
            -- now bring WR high and hold for 20ns

            wr_i <= '1';
            state_i <= t50;
              
          when t50 =>
            state_i <= t60;
            
          when t60 =>
            state_i <= t70;
            
          when t70 =>

            -- finished

            last_go_i <= go;
            busy_i <= false;
            state_i <= idle;
            
          when others => null;

        end case;
      
      end if;
    
    end if;

  end process;
    
end behavioral;

