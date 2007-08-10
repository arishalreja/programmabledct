--------------------------------------------------------------------------------
--                                                                            --
--                          V H D L    F I L E                                --
--                          COPYRIGHT (C) 2006                                --
--                                                                            --
--------------------------------------------------------------------------------
--
-- Title       : MDCT_TB
-- Design      : MDCT Core
-- Author      : Michal Krepa
--
--------------------------------------------------------------------------------
--
-- File        : MDCT_TB.VHD
-- Created     : Sat Mar 5 2006
--
--------------------------------------------------------------------------------
--
--  Description : This is the top level test bench for the integrated WBC DCT core
--
--------------------------------------------------------------------------------

library IEEE;
  use IEEE.STD_LOGIC_1164.all;
library WORK;
  use WORK.MDCT_PKG.all;

entity TB_MDCT is
end TB_MDCT;

--**************************************************************************--

architecture TB of TB_MDCT is

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
-- Clock generator
------------------------------
component CLKGEN
  port (   
        clk               : out STD_LOGIC
       );
end component;

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

signal clk_s               : STD_LOGIC;   
signal clk_gen_s           : STD_LOGIC;  
signal gate_clk_s          : STD_LOGIC;    
signal rst_s               : STD_LOGIC;     
signal DATI_s              : STD_LOGIC_VECTOR(IP_W-1 downto 0); 
signal idv_s               : STD_LOGIC;
signal STBI_s              : STD_LOGIC;
signal CYCI_s              : STD_LOGIC;
signal odv_s               : STD_LOGIC;
signal DATO_s              : STD_LOGIC_VECTOR(IP_W-1 downto 0);
signal dcto_s              : STD_LOGIC_VECTOR(OP_W-1 downto 0);
signal odv1_s              : STD_LOGIC;
signal dcto1_s             : STD_LOGIC_VECTOR(OP_W-1 downto 0);
signal testend_s           : BOOLEAN;
signal ACKO_s              : STD_LOGIC;
signal WEI_s               : STD_LOGIC;

------------------------------
-- architecture begin
------------------------------       
begin
------------------------------
-- MDCT port map
------------------------------
WBO : WBOPRT08_COMP
  port map(
  ACK_O => ACKO_s,
  CLK_I => clk_s,
  DAT_I => DATI_s,
  DAT_O => DATO_s,
  RST_I => rst_s,
  STB_I => STBI_s,
  CYC_I => CYCI_s,
  WE_I => WEI_s);


------------------------------
-- CLKGEN map
------------------------------
U_CLKGEN : CLKGEN
  port map (   
        clk        => clk_gen_s       
       );
    


------------------------------
-- Input image generator
------------------------------
U_INPIMAGE : INPIMAGE
  port map (   
        clk       => clk_s,        
        odv1      => odv1_s,
        dcto1     => dcto1_s,
        odv       => odv_s,
        dcto      => dcto_s,                
        
        rst       => rst_s,        
        imageo    => DATI_s,        
        dv        => idv_s,
        testend   => testend_s        
       );

gate_clk_s <= '0' when testend_s = false else '1';

clk_s <= clk_gen_s and (not gate_clk_s);

STIMULUS1: PROCESS
  BEGIN

    -- Sequential stimulus goes here...
    --
    STBI_S <= '1' AFTER 391 ns; -- This sets the Strobe Enable to high 
    WEI_S <= '1'  AFTER 391 ns; -- This sets the Write Enable to high
    WAIT FOR 1671 ns; -- Maintain test stimuli for 1671 ns
    WEI_S <= '0';
    STBI_S <= '0'; 

    -- 
    -- Enter more stimulus here...
    -- 
    WAIT FOR 600 ns;
    
    wait until (falling_edge(clk_s)); wait until (falling_edge(clk_s));
    STBI_S <= '1'; 
    wait until (falling_edge(clk_s)); 
    STBI_S <= '0'; 
    wait until (falling_edge(clk_s)); wait until (falling_edge(clk_s));
    STBI_S <= '1'; 
    wait until (falling_edge(clk_s));
    STBI_S <= '0'; 
    wait until (falling_edge(clk_s)); wait until (falling_edge(clk_s));
    STBI_S <= '1'; 
    wait until (falling_edge(clk_s));
    STBI_S <= '0'; 
    wait until (falling_edge(clk_s)); wait until (falling_edge(clk_s));
    STBI_S <= '1'; 
    wait until (falling_edge(clk_s));
    STBI_S <= '0'; 
    wait until (falling_edge(clk_s)); wait until (falling_edge(clk_s));
    STBI_S <= '1'; 
    wait until (falling_edge(clk_s));
    STBI_S <= '0'; 
    wait until (falling_edge(clk_s)); wait until (falling_edge(clk_s));
    STBI_S <= '1'; 
    wait until (falling_edge(clk_s));
    STBI_S <= '0'; 
   
   --cclin
   WAIT FOR 5000 ns; -- 
   ASSERT (FALSE) REPORT "simulation done (no error)" SEVERITY FAILURE;    
   
   WAIT;            -- Suspend simulation
  END PROCESS STIMULUS1;
  
  CYCI_S <= STBI_S;


end TB;
-----------------------------------

------------------------------
-- configuration begin
------------------------------
configuration CONF_MDCT of TB_MDCT is
  for TB
  
   -- for WBO : WBOPRT08_COMP
  --    use entity WORK.WBOPRT08(WBOPRT081);
--    end for;
    
    for U_INPIMAGE : INPIMAGE
      use entity WORK.INPIMAGE(SIM);
    end for;
    
    for U_CLKGEN : CLKGEN
      use entity WORK.CLKGEN(SIM);
    end for;
    
  end for;
end CONF_MDCT;

configuration CONF_MDCT_TIMING of TB_MDCT is
  for TB
  
    --for WBO : WBOPRT08_COMP
    --  use entity WORK.WBOPRT08(WBOPRT081);
   -- end for;
    
    for U_INPIMAGE : INPIMAGE
      use entity WORK.INPIMAGE(SIM);
    end for;
    
    for U_CLKGEN : CLKGEN
      use entity WORK.CLKGEN(SIM);
    end for;
    
  end for;
end CONF_MDCT_TIMING;
--**************************************************************************--
