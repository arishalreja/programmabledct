
-- VHDL Test Bench Created from source file cpu_engine.vhd -- 12:41:11 06/20/2003
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
library WORK;
use work.cpu_pack.ALL;
use WORK.MDCT_PKG.all;

ENTITY testbench IS
END testbench;

ARCHITECTURE behavior OF testbench IS 

 TYPE data_array IS ARRAY (integer range <>) OF std_logic_vector(7  DOWNTO 0);-- Memory Type
 SIGNAL mydata : data_array(0 to 63 );  -- Local data buffer to take data from INPIMAGE 
 

------------------------------
-- WBO
------------------------------
component WBOPRT08_COMP	 -- This component is the Wishbone Wrapper
	port(
   -- WISHBONE SLAVE interface for DCT acc core:
   ACK_O: out std_logic;
   CLK_I: in std_logic;
   DAT_I: in std_logic_vector( 7 downto 0 );
   DAT_O: out std_logic_vector( 7 downto 0 );
   RST_I: in std_logic;
   STB_I: in std_logic;
   CYC_I: in std_logic;
   WE_I: in std_logic
   );
end component WBOPRT08_COMP;

------------------------------
-- Input image generator
------------------------------
   component INPIMAGE -- This module reads in the input image
   port (   
        clk               : in STD_LOGIC;
        odv1              : in STD_LOGIC;
        dcto1             : in STD_LOGIC_VECTOR(OP_W-1 downto 0);
        odv               : in STD_LOGIC;
        dcto              : in STD_LOGIC_VECTOR(COE_W-1 downto 0);
        
        rst               : out STD_LOGIC;
        imageo            : out STD_LOGIC_VECTOR(IP_W-1 downto 0);
        dv                : out STD_LOGIC;
        testend           : out BOOLEAN
       );
  end component;

FOR ALL:  WBOPRT08_COMP	USE ENTITY WORK.WBOPRT08(WBOPRT081);

	COMPONENT cpu_engine
	PORT(
		clk_i   : IN std_logic;
		dat_i   : IN std_logic_vector(7 downto 0);
		rst_i   : IN std_logic;
		ack_i   : IN std_logic;
		int     : IN std_logic;          
		dat_o   : OUT std_logic_vector(7 downto 0);
		adr_o   : OUT std_logic_vector(15 downto 0);
		cyc_o   : OUT std_logic;
		stb_o   : OUT std_logic;
		tga_o   : OUT std_logic_vector(0 to 0);
		we_o    : OUT std_logic;
		halt    : OUT std_logic;
		q_pc    : OUT std_logic_vector(15 downto 0);
		q_opc   : OUT std_logic_vector(7 downto 0);
		q_cat   : OUT op_category;
		q_imm   : OUT std_logic_vector(15 downto 0);
		q_cyc   : OUT cycle;
		q_sx    : OUT std_logic_vector(1 downto 0);
		q_sy    : OUT std_logic_vector(3 downto 0);
		q_op    : OUT std_logic_vector(4 downto 0);
		q_sa    : OUT std_logic_vector(4 downto 0);
		q_smq   : OUT std_logic;
		q_we_rr : OUT std_logic;
		q_we_ll : OUT std_logic;
		q_we_sp : OUT SP_OP;
		q_rr    : OUT std_logic_vector(15 downto 0);
		q_ll    : OUT std_logic_vector(15 downto 0);
		q_sp    : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;


COMPONENT WB_spmem
 GENERIC (
   ADD_WIDTH :     INTEGER := 16;      -- Address width
   WIDTH     :     INTEGER := 8;       -- Word Width
   OPTION    :     INTEGER := 0);      -- 1: Registered read Address(suitable
                                       -- for Altera's FPGAs
                                       -- 0: non registered read address  
 PORT (
      DAT_O   : OUT STD_LOGIC_VECTOR(WIDTH -1 DOWNTO 0);
      DAT_I   : IN  STD_LOGIC_VECTOR(WIDTH -1 DOWNTO 0);
      CLK_I   : IN  STD_LOGIC;
      ADR_I   : IN  STD_LOGIC_VECTOR(ADD_WIDTH -1 DOWNTO 0);
      STB_I   : IN  STD_LOGIC;
      WE_I    : IN  STD_LOGIC;
      ACK_O   : OUT STD_LOGIC);
  END COMPONENT;

  
	SIGNAL	CLK_I         : STD_LOGIC;
   SIGNAL RESET         : STD_LOGIC; 
    
	signal	INT           : STD_LOGIC;
	signal	HALT          : STD_LOGIC;
   
	--cclin
	SIGNAL	flag	: STD_LOGIC; 

	-- debug signals
	signal	Q_PC    : std_logic_vector(15 downto 0);
	signal	Q_OPC   : std_logic_vector( 7 downto 0);
	signal	Q_CAT   : op_category;
	signal	Q_IMM   : std_logic_vector(15 downto 0);
	signal	Q_CYC   : cycle;

	-- select signals
	signal	Q_SX    : std_logic_vector(1 downto 0);
	signal	Q_SY    : std_logic_vector(3 downto 0);
	signal	Q_OP    : std_logic_vector(4 downto 0);
	signal	Q_SA    : std_logic_vector(4 downto 0);
	signal	Q_SMQ   : std_logic;

	-- write enable/select signal
	signal	Q_WE_RR : std_logic;
	signal	Q_WE_LL : std_logic;
	signal	Q_WE_SP : SP_OP;

	signal	Q_RR    : std_logic_vector(15 downto 0);
	signal	Q_LL    : std_logic_vector(15 downto 0);
	signal	Q_SP    : std_logic_vector(15 downto 0);
	    
	signal	clk_counter : INTEGER := 0;
	
	
	-- SIGNALS FROM DCT CORE
   signal gate_clk_s          : STD_LOGIC;    
   signal rst_s               : STD_LOGIC;     
   signal idv_s               : STD_LOGIC;
   signal odv_s               : STD_LOGIC;
   signal dcto_s              : STD_LOGIC_VECTOR(OP_W-1 downto 0);
   signal odv1_s              : STD_LOGIC;
   signal dcto1_s             : STD_LOGIC_VECTOR(OP_W-1 downto 0);
   signal testend_s           : BOOLEAN;
   SIGNAL INPUT_DATA          : STD_LOGIC_VECTOR(IP_W-1 downto 0);

   -- PROCESSOR WISHBONE SIGNALS
	SIGNAL	DATI                : std_logic_vector( 7 downto 0);
	SIGNAL DATI_PROC           : std_logic_vector(7 downto 0);
	SIGNAL	DATO_PROC           : std_logic_vector( 7 downto 0);
	SIGNAL	ACKI_PROC           : std_logic;
	SIGNAL	ADRO_PROC           : std_logic_vector(15 downto 0);
	SIGNAL	CYCO_PROC           : std_logic;
	SIGNAL	STBO_PROC           : std_logic;
	SIGNAL	TGA_O               : std_logic_vector( 0 downto 0);		-- '1' if I/O
	signal	WEO_PROC            : std_logic;

   -- DCT WRAPPER SIGNALS
   SIGNAL ACKO_DCT            : STD_LOGIC;  
   SIGNAL DATI_DCT            : STD_LOGIC_VECTOR(IP_W-1 DOWNTO 0);  
   SIGNAL DATO_DCT            : STD_LOGIC_VECTOR(IP_W-1 DOWNTO 0);    
   SIGNAL STBI_DCT            : STD_LOGIC;  
   SIGNAL CYCI_DCT            : STD_LOGIC;  
   SIGNAL WEI_DCT             : STD_LOGIC;  

   -- EXTERNAL MEMORY SIGNALS 
   SIGNAL DATO_MEM            : STD_LOGIC_VECTOR(IP_W-1 DOWNTO 0); 
   SIGNAL DATI_MEM            : STD_LOGIC_VECTOR(IP_W-1 DOWNTO 0); 
   SIGNAL ADRI_MEM            : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL STBI_MEM            : STD_LOGIC;
   SIGNAL CYCI_MEM            : STD_LOGIC;
   SIGNAL WEI_MEM             : STD_LOGIC;
   SIGNAL ACKO_MEM            : STD_LOGIC;

   -- OTHER SIGNALS
   SIGNAL CHIP_SEL            : STD_LOGIC;
   SIGNAL CARRYA              : STD_LOGIC;
   SIGNAL CARRYB              : STD_LOGIC;
   SIGNAL DATO_INPIMAGE       : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL ADRO_INPIMAGE       : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL STBO_INPIMAGE       : STD_LOGIC;
   SIGNAL WEO_INPIMAGE        : STD_LOGIC;
   
BEGIN

	uut: cpu_engine
	PORT MAP(
		clk_i   => clk_i,
		-- PROCESSOR WISHBONE SIGNALS
		dat_i   => DATI_PROC,
		dat_o   => DATO_PROC,
		rst_i   => RESET,
		ack_i   => ACKI_PROC,
		adr_o   => ADRO_PROC,
		cyc_o   => CYCO_PROC,
		stb_o   => STBO_PROC,
		tga_o   => tga_o,
		we_o    => WEO_PROC,
		-- PROCESSOR WISHBONE SIGNALS
		int     => int,
		halt    => halt,
		q_pc    => q_pc,
		q_opc   => q_opc,
		q_cat   => q_cat,
		q_imm   => q_imm,
		q_cyc   => q_cyc,
		q_sx    => q_sx,
		q_sy    => q_sy,
		q_op    => q_op,
		q_sa    => q_sa,
		q_smq   => q_smq,
		q_we_rr => q_we_rr,
		q_we_ll => q_we_ll,
		q_we_sp => q_we_sp,
		q_rr    => q_rr,
		q_ll    => q_ll,
		q_sp    => q_sp
	);

--------------------
-- MDCT port map ---
--------------------
WBO : WBOPRT08_COMP
  port map(
  ACK_O => ACKO_DCT,
  CLK_I => CLK_I,
  DAT_I => DATI_DCT,
  DAT_O => DATO_DCT,
  RST_I => RESET,
  STB_I => STBI_DCT,
  CYC_I => CYCI_DCT,
  WE_I  => WEI_DCT);
    
---------------------
-- EXTERNAL MEMORY -- 
---------------------
memory: WB_spmem
 PORT MAP(
      DAT_O => DATO_MEM, 
      DAT_I => DATI_MEM,
      CLK_I => CLK_I,
      ADR_I => ADRI_MEM,
      STB_I => STBI_MEM,
      WE_I  => WEI_MEM,
      ACK_O => ACKO_MEM);
	
	
------------------------------
-- Input image generator
------------------------------
U_INPIMAGE : INPIMAGE
  port map (   
        clk       => CLK_I,        
        odv1      => odv1_s,
        dcto1     => dcto1_s,
        odv       => odv_s,
        dcto      => dcto_s,                
        rst       => rst_s,        
        imageo    => DATO_INPIMAGE,        
        dv        => idv_s,
        testend   => testend_s        
       );



	
--  TEST BENCH - USER DEFINED CODE *** --

--gate_clk_s <= '0' when testend_s = false else '1';
ADRI_MEM <= ADRO_PROC WHEN RESET = '0' ELSE ADRO_INPIMAGE;	

	PROCESS -- clock process for CLK_I,
	BEGIN
		CLOCK_LOOP : LOOP
			CLK_I <= transport '0';
			WAIT FOR 1 ns;
			CLK_I <= transport '1';
			WAIT FOR 1 ns;
			WAIT FOR 11 ns;
			CLK_I <= transport '0';
			WAIT FOR 12 ns;
		END LOOP CLOCK_LOOP;
	END PROCESS;
	
	CHIP_SEL <= '1' WHEN ( (ADRO_PROC = X"2001") OR (ADRO_PROC = X"2002") ) ELSE '0';
	 -- RESOLVE BUS CONTENTION FOR DATA OUT FROM MEMORY AND DCT
   DATI_DCT  <= DATO_PROC WHEN (CHIP_SEL = '1') ELSE DATI_DCT;
   
   DATI_MEM  <= DATO_INPIMAGE WHEN (RESET = '1') ELSE 
                DATO_PROC     WHEN ((CHIP_SEL = '0') AND (RESET='0')) ELSE 
                DATI_MEM;
   
   STBI_DCT  <= STBO_PROC WHEN (CHIP_SEL = '1') ELSE '0'; 
   CYCI_DCT  <= CYCO_PROC WHEN (CHIP_SEL = '1') ELSE '0';
   WEI_DCT   <= WEO_PROC  WHEN (CHIP_SEL = '1') ELSE '0';
   STBI_MEM  <= STBO_PROC     WHEN ((CHIP_SEL = '0') AND (RESET ='0')) ELSE 
                STBO_INPIMAGE WHEN (RESET = '1') ELSE '0';
   CYCI_MEM  <= CYCO_PROC WHEN (CHIP_SEL = '0') ELSE '0';
   WEI_MEM   <= WEO_PROC  WHEN ((CHIP_SEL = '0') AND (RESET = '0')) ELSE 
                WEO_INPIMAGE WHEN (RESET = '1') ELSE '0';
   
   DATI      <= DATO_DCT  WHEN (CHIP_SEL = '1') ELSE DATO_MEM;
   ACKI_PROC <= ACKO_DCT  WHEN (CHIP_SEL = '1') ELSE ACKO_MEM;
   	
	PROCESS(CLK_I)
	BEGIN	    
 
      IF (NOT(DATI = "UUUUUUUU")) THEN DATI_PROC <= DATI; END IF;
    
     	if (rising_edge(CLK_I)) then
			if (Q_CYC = M1) then
				CLK_COUNTER <= CLK_COUNTER + 1;
			end if;

			--if (ADR_O(0) = '0') then		DAT_I <= X"44";	-- data
			--else					DAT_I <= X"01";	-- control
			--end if;
			if ( flag = '1')then	
			if (ADRO_PROC(0) = '0') then		DATI_PROC <= X"44";	-- data
			else					DATI_PROC <= X"01";	-- control
			end if;
			end if;

			case CLK_COUNTER is
				when 0		=>	--RESET <= '1';   
				           INT <= '0';
					   flag<= '0';
				when 1		=>	--RESET <= '0';
--				when 20		=>	INT <= '1';
				--when 1000		=>	flag<= '1';
				--when 1000		=>	INT <= '1';flag<= '1';
				when 1050		=>	flag<= '0';
				when 1005		=>	INT <= '0';
				--when 2000		=>	flag<= '1';
				--when 2000		=>	INT <= '1';flag<= '1';
				when 2005		=>	INT <= '0';
				when 2050		=>	flag<= '0';
				--when 3000		=>	flag<= '1';
				when 3000		=>	INT <= '1';flag<= '1';
				when 3005		=>	INT <= '0';
				when 3050		=>	flag<= '0';
				--when 4000		=>	flag<= '1';
				when 4000		=>	INT <= '1';flag<= '1';
				when 4005		=>	INT <= '0';
				when 4050		=>	flag<= '0';
				when 5000		=>	INT <= '1';
				when 5005		=>	INT <= '0';
				when 6000		=>	INT <= '1';
				when 6005		=>	INT <= '0';
				--when 7000		=>	INT <= '1';
				--when 7005		=>	INT <= '0';
				--when 8000		=>	INT <= '1';
				--when 8005		=>	INT <= '0';
				--when 9000		=>	INT <= '1';
				--when 9005		=>	INT <= '0';


				when 7000	=>	CLK_COUNTER <= 0;
								ASSERT (FALSE) REPORT
									"simulation done (no error)"
									SEVERITY FAILURE;
				when others	=>
			end case;
		end if;
	
	END PROCESS;


	STIMULUS1: PROCESS
     BEGIN
       -- Sequential stimulus goes here...
       --
     RESET    <= '1';     -- STALL PROCESSOR AND DCT
     WAIT FOR 2 ns;
     ADRO_INPIMAGE <= X"FFBF"; -- AFTER 2 ns;
     WAIT FOR 474 ns;
     STBO_INPIMAGE <= '1';  -- AFTER 391 ns;
     WEO_INPIMAGE  <= '1';  -- AFTER 391 ns;
    
    eins: for j in 1 to 64 loop  -- WRITE FROM INPIMAGE TO EXTERNAL MEM
    
       WAIT until CLK_I = '0';    
       WAIT FOR 0.2 ns;    
       CARRYA <= ADRO_INPIMAGE(0) AND '1';
       WAIT FOR 0.2 ns;
       ADRO_INPIMAGE(0) <= ADRO_INPIMAGE(0) XOR '1';
  	   
       zwei: for i in 1 to 15 loop
                CARRYB <= ADRO_INPIMAGE(i) AND CARRYA;
                WAIT FOR 0.2 ns;
                ADRO_INPIMAGE(i) <= ADRO_INPIMAGE(i) XOR CARRYA;
                WAIT FOR 0.2 ns;
                CARRYA <= CARRYB;
                WAIT FOR 0.2 ns;
  	    end loop zwei;                 

    end loop eins;
     
   
    WAIT until CLK_I = '0';
    WEO_INPIMAGE <= '0';
    RESET   <= '0';
       
    WAIT;            -- Suspend simulation
  
--       RESET <= '1';
--       
--       WAIT FOR 391 ns; -- WAIT FOR INPIMAGE TO START PUTTING OUT DATA
--    
--       FOR j IN 63 DOWNTO 0 LOOP -- WRITE 64 DATA FROM INPIMAGE TO mydata
--          WAIT UNTIL CLK_I = '1';
--          mydata(63-j) <= INPUT_DATA;
--       END LOOP;
--       
--       RESET <= '0';
--       WAIT;
--     -- FOR k IN 63 DOWNTO 0 LOOP -- DO 64 WISHBONE WRITES FROM mydata TO DCT
      --     DATI_DCT <= mydata(63-k);
      --     WAIT UNTIL CLK_I = '1';
      --     STBI_DCT <= '1';          -- Set Strobe high 
      --     WEI_DCT  <= '1';          -- Set Write Enable 
      --     WAIT UNTIL ACKO_DCT = '1';
      --     WAIT UNTIL CLK_I = '1';
      --     WEI_DCT  <= '0';
      --     STBI_DCT <= '0';
      --     WAIT FOR 70 ns;
      --  END LOOP;
    
      -- FOR i IN 127 DOWNTO 0 LOOP -- START READING FROM DCT, 128 TIMES
      --    WAIT FOR 80 ns;
      --    STBI_DCT <= '1';
      --    WAIT UNTIL ACKO_DCT = '1';
      --    WAIT UNTIL ACKO_DCT = '0';
      --    STBI_DCT <= '0';
      --    WAIT UNTIL ACKO_S = '0';
      --  END LOOP;
    
       -- 
       -- Enter more stimulus here...
       -- 
       --WAIT;            -- Suspend simulation
  
  END PROCESS STIMULUS1;
 
END;
