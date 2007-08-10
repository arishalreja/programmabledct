-------------------------------------------------------------------------------
-- Title      :  Wishbone Dual port RAM
-- Project    :  Memory Cores
-------------------------------------------------------------------------------
-- File        : WB_dpmem.vhd
-- Author      : Jamil Khatib  (khatib@ieee.org)
-- Organization: OpenCores Project
-- Created     : 16/04/2001
-- Last update : 16/04/2001
-- Platform    : 
-- Simulators  : Modelsim 5.3XE/Windows98, NC-SIM/Linux
-- Synthesizers: 
-- Target      : 
-- Dependency  : ieee.std_logic_1164
--               memLib.mem_pkg
-------------------------------------------------------------------------------
-- Description:  Dual Port memory
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
-- $Log: WB_dpmem.vhd,v $
-- Revision 1.1.1.1  2001/04/16 20:46:16  khatib
-- Initial Release
--
-- Revision 1.1  2001/04/16 20:14:02  jamil
-- Initial Release
--
-------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

LIBRARY memLib;
USE memLib.mem_pkg.ALL;


ENTITY wb_dpmem IS

  GENERIC (
    ADD_WIDTH  : INTEGER := 8;
    WIDTH      : INTEGER := 8;
    CLK_DOMAIN : INTEGER := 2);         -- 2=Two clock domains
                                        -- 1=Single Clock domain CLK_I_2 will be ignored

  PORT (
    CLK_I_1 : IN  STD_LOGIC;            -- Domain 1 (Write)
    CLK_I_2 : IN  STD_LOGIC;            -- Domain 2 (Read)
    ADR_I_1 : IN  STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);  -- ADR Domain 1
    ADR_I_2 : IN  STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);  -- ADR Domain 2
    DAT_O   : OUT STD_LOGIC_VECTOR(WIDTH -1 DOWNTO 0);  -- Domain 2
    DAT_I   : IN  STD_LOGIC_VECTOR(WIDTH -1 DOWNTO 0);  -- Domain 1
    WE_I_1  : IN  STD_LOGIC;            -- Write to Domain 1
    WE_I_2  : IN  STD_LOGIC;            -- Read from Domain 2
    ACK_O_1 : OUT STD_LOGIC;            -- ACK domain 1
    ACK_O_2 : OUT STD_LOGIC;            -- ACK domain 2
    STB_I_1 : IN  STD_LOGIC;            -- STB domain 1
    STB_I_2 : IN  STD_LOGIC);           -- STB domain 2

END wb_dpmem;

ARCHITECTURE wb_dpmem_rtl OF wb_dpmem IS
  SIGNAL reset : STD_LOGIC;             -- Dummy
  SIGNAL WR_i  : STD_LOGIC;             -- Internal Wr
  SIGNAL RE_i  : STD_LOGIC;             -- Internal Re
BEGIN  -- wb_dpmem_rtl

  ACK_O_1 <= STB_I_1;
  ACK_O_2 <= STB_I_2;

  WR_i <= STB_I_1 AND WE_I_1;
  RE_i <= NOT WE_I_2;

  mem_core : dpmem_ent
    GENERIC MAP (
      USE_RESET   => FALSE,
      USE_CS      => FALSE,
      DEFAULT_OUT => '1',
      CLK_DOMAIN  => CLK_DOMAIN,
      ADD_WIDTH   => ADD_WIDTH,
      WIDTH       => WIDTH)
    PORT MAP (
      W_clk       => CLK_I_1,
      R_clk       => CLK_I_2,
      reset       => reset,
      W_add       => ADR_I_1,
      R_add       => ADR_I_2,
      Data_In     => DAT_I,
      Data_Out    => DAT_O,
      WR          => WR_i,
      RE          => RE_i);

END wb_dpmem_rtl;
