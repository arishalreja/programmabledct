-- An Output Buffer is required because the original DCT core, acting as the Wishbone 
-- Slave, had a 12 bit output. However, the Wishbone Master, has a wishbone compliant 
-- 8 bit I/O port. Thus each 12 bit DCT output is extended to 16 bits, and stored in
-- this output buffer. Each output value is sent to the Master in 2 clock cycles, in 
-- 8 bit blocks.  

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL;
-- Dual port Memory core. This component forms the basis of the Output Memory Buffer
ENTITY dpmem IS
generic ( ADD_WIDTH: integer := 8 ;
          WIDTH : integer := 16;
          DATA_OUT_WIDTH: integer := 8);
  PORT (
    clk      : IN  std_logic;                                -- write clock
    reset    : IN  std_logic;                                -- System Reset
    Data_In  : IN  std_logic_vector(WIDTH - 1  DOWNTO 0);    -- input data
    Data_Out : OUT std_logic_vector(DATA_OUT_WIDTH -1 DOWNTO 0);    -- output Data
    WR       : IN  std_logic;                                -- Write Enable
    RE       : IN  std_logic);                               -- Read Enable
  --  All_Out  : OUT std_logic;
END dpmem;

-------------------------------------------------------------------------------
ARCHITECTURE dpmem_v1 OF dpmem IS

  TYPE data_array IS ARRAY (integer range <>) OF std_logic_vector(WIDTH -1  DOWNTO 0);
                                        -- Memory Type
  SIGNAL data : data_array(0 to (2** add_width) );  -- Local data. 
  SIGNAL flag : STD_LOGIC; -- Flag variable

  procedure init_mem(signal memory_cell : inout data_array ) is
  begin
   -- This procedure sets the value of each cell of the data array to zero
    for i in 0 to (2** add_width) loop
      memory_cell(i) <= (others => '0');
    end loop;

  end init_mem;

BEGIN  -- dpmem_v1

  PROCESS (clk, reset)

  VARIABLE W_add : INTEGER := 0; --This variable corresponds to the write address, initialized to 0
  VARIABLE R_add : INTEGER := 0; --This variable corresponds to the read address, initialized to 0 

 BEGIN  -- PROCESS

    -- activities triggered by asynchronous reset (active high)
    IF reset = '1' THEN
      data_out <= (OTHERS => 'Z'); --floating value assigned to 'Z'
      init_mem ( data); -- Calls the init_mem procedure
      W_add := 0; -- resets the read and write addresses to 0
      R_add := 0;
      flag <= '0';-- flag set to 0
      -- activities triggered by rising edge of clock
    ELSIF clk'event AND clk = '1' THEN
      IF RE = '1' THEN --OR flag = '1' THEN
  --      IF R_add /= W_add THEN -- Data is latched onto output bus only if Read and Write addresses
                               -- are different, preventing contention. 
            IF flag = '0' THEN -- Most significant 8 bits are placed on Output bus
            
                data_out <= data(R_add)(15 downto 8);
                -- data_out <= data(R_add)(7 downto 0);
                
                flag <= '1';
            ELSE -- Least significant 8 bits are placed on Output bus
            
                data_out <= data(R_add)(7 downto 0);
                -- data_out <= data(R_add)(15 downto 8);
                
                flag <= '0';
                R_add := R_add + 1; -- Read address is incremented
            
                --Circular addressing scheme is implemented, allowing for read address roll-over
                R_add := R_add mod 64; -- There are 64 input values per block
               -- IF R_add = '0'
                 -- All_Out <= '1';
               -- ELSE
                --  All_Out <= '0';
               -- END IF;
            END IF;
  --     END IF;
      ELSE
        data_out <= (OTHERS => 'Z');    -- Defualt value
      END IF;

      IF WR = '1' THEN -- Data is written to the Output Buffer only when WR is high
        data(W_add) <= Data_In;
        W_add := W_add + 1; -- Write Address is incremented
        
        --Circular addressing scheme is implemented, allowing for write address roll-over
        W_add := W_add mod 64;
      END IF;
    END IF;
  END PROCESS;
END dpmem_v1;
