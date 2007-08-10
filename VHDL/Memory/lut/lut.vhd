-------------------------------------------------------------------------------
-- Title      : Genereic LUT Model
-- Project    : Memory Cores
-------------------------------------------------------------------------------
-- File        : LUT.VHD
-- Author      : Jamil Khatib  <khatib@ieee.org>
-- Organization: OpenIPCore Project
-- Created     : 2000/02/29
-- Last update: 2001/01/12
-- Platform    : 
-- Simulators  : Modelsim 5.2EE / Windows98
-- Synthesizers: Leonardo / WindowsNT
-- Target      : Flex10K
-- Dependency  : uses memLib.mem_pkg and utility.tools_pkg
-------------------------------------------------------------------------------
-- Description: Generic LUT Model
-------------------------------------------------------------------------------
-- Copyright (c) 2000 Jamil Khatib
-- 
-- This VHDL design file is an open design; you can redistribute it and/or
-- modify it and/or implement it under the terms of the Openip General Public
-- License as it is going to be published by the OpenIPCore Organization and
-- any coming versions of this license.
-- You can check the draft license at
-- http://www.openip.org/oc/license.html

-------------------------------------------------------------------------------
-- Revisions  :
-- Revision Number : 1
-- Version	   : 1.0
-- Date 	   : 29th Feb 2000
-- Modifier     :   Jamil Khatib (khatib@ieee.org)
-- Desccription :   Created
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Revision Number : 2
-- Version	   : 1.1
-- Date 	   : 12 Jan 2001
-- Modifier     :   Jamil Khatib (khatib@ieee.org)
-- Desccription :   Code clean
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity LUT is

  generic (
    NO_INPUTS : integer := 4;           -- LUT no of inputs
    VENDOR    : integer := 0;          -- Vendor ID "it is unusable in this version
    CONTENTS : std_logic_vector :=  
    ('0','1','0','1','0','1','0','1','0','1','0','1','0','1','0','0')); 
  -- LUT contents arranged from MSB to LSB "Left to Right"
  -- Note There is no check on the number items in LUT 

  port (
    LUTAddr   : in  std_logic_vector(NO_INPUTS -1 downto 0);  -- Input address
    LUTOutput : out std_logic);                               -- LUT output


end LUT;


library ieee;
use ieee.std_logic_1164.all;
library memLib;
use memLib.mem_pkg.all;

library utility;
use utility.tools_pkg.all;

architecture behavior of LUT is

  constant LUTtable : std_logic_vector((2**NO_INPUTS -1) downto 0) := CONTENTS;  
                                        -- LUT table
begin  -- behavior

  LUTOutput <= LUTtable(SLV_2_int(LUTAddr));

end behavior;

