-------------------------------------------------------------------------------
-- Title      :  First In First Out buffer test bench
-- Project    :  Memory Cores
-------------------------------------------------------------------------------
-- File        : fifo_tb.vhd
-- Author      : Jamil Khatib  (khatib@ieee.org)
-- Organization: OpenIPCore Project
-- Created     : 2001/03/08
-- Last update:2001/06/01
-- Platform    : 
-- Simulators  : Modelsim 5.3XE/Windows98,NC-Sim/Linux
-- Synthesizers: Leonardo/Windows98
-- Target      : 
-- Dependency  : ieee.std_logic_1164
--               utility.tools_pkg
--               memlib.mem_pkg
-------------------------------------------------------------------------------
-- Description:  FIFO buffer test bench
-------------------------------------------------------------------------------
-- Copyright (c) 2000 Jamil Khatib
-- 
-- This VHDL design file is an open design; you can redistribute it and/or
-- modify it and/or implement it after contacting the author
-- You can check the draft license at
-- http://www.opencores.org/OIPC/license.shtml

-------------------------------------------------------------------------------
-- Revisions  :
-- Revision Number :   1
-- Version         :   0.1
-- Date            :   8 March 2001
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   Created
-- Known bugs      :   
-- To Optimze      :   
-------------------------------------------------------------------------------
-- $Log: fifo_tb.vhd,v $
-- Revision 1.1  2001/06/05 19:31:25  khatib
-- Initial Release
--
-- Revision 1.1  2001/06/05 17:42:49  jamil
-- Initial Release
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY memlib;
LIBRARY utility;
USE utility.tools_pkg.ALL;
USE memLib.mem_pkg.ALL;
-------------------------------------------------------------------------------

ENTITY FIFO_ent_tb IS
  GENERIC (
    CLK_DOMAIN : INTEGER := 2);         -- No of clock domains
END FIFO_ent_tb;

-------------------------------------------------------------------------------

ARCHITECTURE FIFO_tb OF FIFO_ent_tb IS

  CONSTANT ARCH        : INTEGER   := 0;
  CONSTANT USE_CS      : BOOLEAN   := FALSE;
  CONSTANT DEFAULT_OUT : STD_LOGIC := '1';
  CONSTANT MEM_CORE    : INTEGER   := 0;
  CONSTANT BLOCK_SIZE  : INTEGER   := 1;
  CONSTANT WIDTH       : INTEGER   := 8;
  CONSTANT DEPTH       : INTEGER   := 8;

  SIGNAL rst_n      : STD_LOGIC;
  SIGNAL R_clk      : STD_LOGIC := '0';
  SIGNAL W_clk      : STD_LOGIC := '0';
  SIGNAL cs         : STD_LOGIC := '0';
  SIGNAL Din        : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  SIGNAL Dout       : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);
  SIGNAL Re         : STD_LOGIC;
  SIGNAL wr         : STD_LOGIC;
  SIGNAL RUsedCount : STD_LOGIC_VECTOR(log2(DEPTH)-1 DOWNTO 0);
  SIGNAL WUsedCount : STD_LOGIC_VECTOR(log2(DEPTH)-1 DOWNTO 0);
  SIGNAL RFull      : STD_LOGIC;
  SIGNAL RHalf_full : STD_LOGIC;
  SIGNAL REmpty     : STD_LOGIC;
  SIGNAL WFull      : STD_LOGIC;
  SIGNAL WHalf_full : STD_LOGIC;
  SIGNAL WEmpty     : STD_LOGIC;

BEGIN  -- FIFO_tb
  rst_n <= '0',
           '1' AFTER 50 NS;
-------------------------------------------------------------------------------
  SINGLECLK : IF CLK_DOMAIN = 1 GENERATE

    W_clk <= NOT W_clk AFTER 20 NS;
    R_clk <= W_clk;

  END GENERATE SINGLECLK;


  DOUBLECLK : IF CLK_DOMAIN = 2 GENERATE
    W_clk <= NOT W_clk AFTER 20 NS;
    R_clk <= NOT R_clk AFTER 25 NS;
  END GENERATE DOUBLECLK;

-------------------------------------------------------------------------------
-- purpose: Fill FIFO process
-- type   : combinational
-- inputs : 
-- outputs: 
  Fill_data_proc     : PROCESS
    VARIABLE counter : STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0) := (OTHERS => '0');
  BEGIN  -- PROCESS Fill_data_proc

    WAIT UNTIL W_clk = '1';
    IF (rst_n = '1') THEN


      WAIT UNTIL W_clk = '0';
      Din     <= counter;
      IF (WFull = '1') THEN
        WAIT UNTIL WFull = '0';
      END IF;
      wr      <= '1';
      counter := counter + 1;
      WAIT UNTIL W_clk = '1';
      wr      <= '0';

    ELSE
      wr <= '0';
    END IF;
  END PROCESS Fill_data_proc;

-------------------------------------------------------------------------------
-- purpose: Empty FIFO process
-- type   : combinational
-- inputs : 
-- outputs: 
  Empty_data_proc    : PROCESS
    VARIABLE counter : STD_LOGIC_VECTOR(WIDTH -1 DOWNTO 0) := (OTHERS => '0');
  BEGIN  -- PROCESS Empty_data_proc
    WAIT UNTIL R_clk = '1';

    IF (rst_n = '1') THEN


      WAIT UNTIL R_clk = '0';

      IF (REmpty = '1') THEN
        WAIT UNTIL REmpty = '0';
      END IF;
--      re      <= '1';
      re <= '0';
      counter := counter + 1;
      WAIT UNTIL R_clk = '1';

--      ASSERT (Dout = counter) REPORT "Incorrect Output value" SEVERITY WARNING;
      re <= '0';
    ELSE
      re <= '0';
    END IF;
  END PROCESS Empty_data_proc;
-------------------------------------------------------------------------------
  dut : FIFO_ent
    GENERIC MAP (
      ARCH        => ARCH,
      USE_CS      => USE_CS,
      DEFAULT_OUT => DEFAULT_OUT,
      CLK_DOMAIN  => CLK_DOMAIN,
      MEM_CORE    => MEM_CORE,
      BLOCK_SIZE  => BLOCK_SIZE,
      WIDTH       => WIDTH,
      DEPTH       => DEPTH)
    PORT MAP (
      rst_n       => rst_n,
      Rclk        => R_clk,
      Wclk        => W_clk,
      cs          => cs,
      Din         => Din,
      Dout        => Dout,
      Re          => Re,
      wr          => wr,
      RUsedCount  => RUsedCount,
      WUsedCount  => WUsedCount,
      RFull       => RFull,
      RHalf_full  => RHalf_full,
      REmpty      => REmpty,
      WFull       => WFull,
      WHalf_full  => WHalf_full,
      WEmpty      => WEmpty);

END FIFO_tb;

-------------------------------------------------------------------------------
