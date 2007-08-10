-- This module is a wrapper that creates the Wishbone logic around the DCT core
-- and the Output buffer

library ieee;
use ieee.std_logic_1164.all;

library WORK;
use WORK.MDCT_PKG.all;
use IEEE.NUMERIC_STD.all;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.dpmem;

 entity WBOPRT08 is
   port(-- WISHBONE SLAVE interface for DCT acc core:
   ACK_O: out std_logic;                     -- WBC Acknowledge Output signal
   CLK_I: in std_logic;                      -- WBC Clock signal
   DAT_I: in std_logic_vector( 7 downto 0 ); -- 8 bit WBC Data input bus
   DAT_O: out std_logic_vector( 7 downto 0 );-- 8 bit WBC Data output bus
   RST_I: in std_logic;                      -- WBC Reset In signal
   STB_I: in std_logic;                      -- WBC Strobe In signal
   CYC_I : in std_logic;                     -- WBC Cycle In signal
   WE_I: in std_logic                        -- WBC Write Enable In signal
   );
 end entity WBOPRT08;

 architecture WBOPRT081 of WBOPRT08 is

component MDCT_comp IS	 -- This component is the original non WBC DCT core
	port   (	  
		clk          : in STD_LOGIC;  
		rst          : in std_logic;
      dcti         : in std_logic_vector(IP_W-1 downto 0);
      idv          : in STD_LOGIC;

      odv          : out STD_LOGIC;
      dcto         : out std_logic_vector(COE_W-1 downto 0);
      odv1         : out STD_LOGIC;
      dcto1        : out std_logic_vector(OP_W-1 downto 0)
      );
      end component MDCT_comp; 
  
  FOR ALL:  MDCT_comp USE ENTITY WORK.MDCT(RTL);
    
 component dpmem_comp IS -- This component is the Output Buffer
   port  (
      clk          : in STD_LOGIC;
      reset        : in STD_LOGIC;
      Data_In      : in  std_logic_vector(15 DOWNTO 0);            -- Input data
      Data_Out     : out std_logic_vector(7 DOWNTO 0);             -- Output Data
      WR           : in  std_logic;                                -- Write Enable
      RE           : in  std_logic                                 -- Read Enable
      );
  end component dpmem_comp;
  
   FOR ALL: dpmem_comp USE ENTITY WORK.dpmem(dpmem_v1);                               
    
   signal Q: std_logic_vector( 15 downto 0 ); -- The 16 bit extended version of the 12 
                                              -- bit DCT core output
   signal R: std_logic_vector( 7 downto 0);   -- This signal is mapped to the 8 bit output
                                              -- of the wrapper, output of the Output Buffer
   signal S: std_logic_vector( 15 downto 0);  -- This forms the input to the output buffer
   signal odvtemp: STD_LOGIC;
   signal idvtemp: STD_LOGIC;
   signal odv1temp: STD_LOGIC;
   signal Data_Intemp: std_logic_vector(7 downto 0);
   signal WRtemp: STD_LOGIC;
   signal REtemp: STD_LOGIC;
   signal dcto1temp: std_logic_vector(OP_W-1 downto 0);
   signal flag1: STD_LOGIC;  -- This is used to ensure that no data is read
                             -- from the mem buf until it contains the first
                             -- new output data value data
   
   signal WB_READ : STD_LOGIC;  -- ARISH: Signal to enable Master's control of slave sending data over bus  
   signal MEM_READ: STD_LOGIC;
   signal WB_READ_D : STD_LOGIC;
   signal DATA_VALID : STD_LOGIC;
-- signal  All_Outs  : out std_logic;
    
   begin
      REG: process( CLK_I )
  --    VARIABLE count : INTEGER := 0; 

      begin               
          
      if (rst_i = '1') then
              DATA_VALID <= '0';
        --      count <= X"00";
      else
      -- The following logic handles the control logic for the WBC interface            
      if ( falling_edge( CLK_I ) ) then 
        
          
          if ((odvtemp and flag1) = '1') then  -- If there is output data to be read
              REtemp <= '1'; -- Read enable (for the buffer) is set
          end if;  
                             
          if (odvtemp = '1') then -- If data is being written to output buffer
                                      -- during the next rising edge
              flag1 <= '1';  -- Set flag
          else
              flag1 <= '0';  -- else null it          
          end if;
              
         
        -- if (WB_READ = '1') then    -- if read is enabled, the next rising edge
        --                            -- there will be data in R
        --     count <= count + 1;      -- Increment counter
        -- end if;
                                       
                 
         if (R = "ZZZZZZZZ") then
                
         else
             DAT_O <= R; -- The output of the Output buffer is written to DAT_O via R every falling edge     
             DATA_VALID <= '1';
         end if;    
              
       --  if (count > 128) then       -- End of read (no more read)      
       --      count <= X"00";             -- Reset Counter
       --      REtemp <= '0';          -- Read Enable nulled
       --  end if;
              
         -- Note - Reset operation is taken care of internally.
              
         S <= Q; -- The sign extended output of the DCT core
                 -- is written to the Output buffer            
        
          if (WB_READ = '1' and DATA_VALID = '1' ) then
    --           ACK_O <= ((STB_I and (not(WE_I)))); -- Ack = STB.(WE)'
               DATA_VALID <= '0';
           else 
  --            ACK_O <= ((STB_I) and (WE_I));   -- Ack = STB.WE 
           end if;    
        
        -- elsif (rising_edge (CLK_I)) then
             
  

         end if;
         
      end if;
    end process REG;
      
               --  READ
   ACK_O   <= ((STB_I and (not(WE_I)) ) AND WB_READ AND DATA_VALID) OR (STB_I AND WE_I);       

   idvtemp <= STB_I and WE_I;
   WB_READ  <= STB_I and (not WE_I);
   MEM_READ <=  WB_READ and (not DATA_VALID);
   
   -- LATCH ALL VALID DATA DIRECTLY ONTO DAT_O BUS
  -- PROCESS (R)
  --     begin
  
  -- END PROCESS;
   
   
   Q(15) <= Q(11); -- The 12 bit output of the DCT is extended to 16 bits
   Q(14) <= Q(11); -- by logical sign extension
   Q(13) <= Q(11);
   Q(12) <= Q(11);
   
   YOT1: MDCT_comp 
   PORT MAP(
   clk => CLK_I,
   rst => RST_I,
   dcti => DAT_I,
   idv => idvtemp,
   odv => odvtemp,
   dcto => Q (11 downto 0),-- The DCT core writes its 12 bit output to the Q signal
   odv1 => odv1temp,
   dcto1 => dcto1temp);
   
   YOT2: dpmem_comp
   PORT MAP(
   clk => CLK_I,
   reset => RST_I,
   Data_In => S,  -- The S signal feeds the input to the output buffer
   Data_Out => R, -- The Output buffer writes its data to the R signal
   WR => odvtemp,
   RE => MEM_READ);
  -- All_Out => All_Outs);

end architecture WBOPRT081;
  
   

