-------------------------------------------------------------------------------
-- Title      :  Wishbone Single port RAM
-- Project    :  Memory Cores
-------------------------------------------------------------------------------
-- File        : WB_spmem.vhd
-- Author      : Jamil Khatib  (khatib@ieee.org)
-- Organization: OpenCores Project
-- Created     : 16/04/2001
-- Last update : 16/04/2001
-- Platform    : 
-- Simulators  : Modelsim 5.3XE/Windows98, NC-SIM/Linux
-- Synthesizers: 
-- Target      : 
-- Dependency  : ieee.std_logic_1164,ieee.std_logic_unsigned
--               memLib.mem_pkg
-------------------------------------------------------------------------------
-- Description:  Wishbone Single Port memory
-------------------------------------------------------------------------------
-- Copyright (c) 2001 Jamil Khatib
-- 
-- This VHDL design file is an open design; you can redistribute it and/or
-- modify it and/or implement it after contacting the author
-- You can check the draft license at
-- http://www.opencores.org/OIPC/license.shtml

-------------------------------------------------------------------------------
-- Revisions  :
-- Revision Number :   1
-- Version         :   0.1
-- Date            :   16 April 2001
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   Created
-- Known bugs      :   
-- To Optimze      :
-------------------------------------------------------------------------------
-- $Log: WB_spmem.vhd,v $
-- Revision 1.1.1.1  2001/04/16 20:46:05  khatib
-- Initial Release
--
-- Revision 1.3  2001/04/16 19:38:02  jamil
-- DAT_O width fixed
--
-- Revision 1.2  2001/04/16 19:15:06  jamil
-- Log Added
--
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
LIBRARY memLib;
USE memLib.mem_pkg.ALL;

ENTITY WB_spmem IS

  GENERIC (
    ADD_WIDTH :     INTEGER := 16;       -- Address width
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

END WB_spmem;

ARCHITECTURE WB_spmem_rtl OF WB_spmem IS
  SIGNAL cs    : STD_LOGIC := '0';      -- dummy signal
  SIGNAL reset : STD_LOGIC := '0';      -- dummy signal
  SIGNAL wr_i  : STD_LOGIC;             -- Internal write
BEGIN  -- WB_spmem_rtl

  ACK_O <= STB_I;
  wr_i  <= NOT (STB_I AND WE_I);

  mem_core : Spmem_ent
    GENERIC MAP (
      USE_RESET   => FALSE,
      USE_CS      => FALSE,
      DEFAULT_OUT => '1',
      OPTION      => OPTION,
      ADD_WIDTH   => ADD_WIDTH,
      WIDTH       => WIDTH)
    PORT MAP (
      cs          => cs,
      clk         => CLK_I,
      reset       => reset,
      add         => ADR_I,
      Data_In     => DAT_I,
      Data_Out    => DAT_O,
      WR          => wr_i);

END WB_spmem_rtl;
