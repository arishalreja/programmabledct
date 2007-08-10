-------------------------------------------------------------------------------
-- Title      :  Dual port RAM
-- Project    :  Memory Cores
-------------------------------------------------------------------------------
-- File        : dpmem.vhd
-- Author      : Jamil Khatib  (khatib@ieee.org)
-- Organization: OpenIPCore Project
-- Created     : 1999/5/14
-- Last update : 2000/12/19
-- Platform    : 
-- Simulators  : Modelsim 5.3XE/Windows98
-- Synthesizers: Leonardo/WindowsNT
-- Target      : 
-- Dependency  : ieee.std_logic_1164,ieee.std_logic_unsigned
-------------------------------------------------------------------------------
-- Description:  Dual Port memory
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
-- Date            :   12 May 1999
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   Created
-- Known bugs      :   
-- To Optimze      :   
-------------------------------------------------------------------------------
-- Revision Number :   2
-- Version         :   0.2
-- Date            :   19 Dec 2000
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   General review
--                     Two versions are now available with reset and without
--                     Default output can can be defined
-- Known bugs      :   
-- To Optimze      :   
-------------------------------------------------------------------------------
-- Revision Number :   3
-- Version         :   0.3
-- Date            :   28 May 2001
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   LMP component used
-- Known bugs      :   
-- To Optimze      :   
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- $Log: dpmem.vhd,v $
-- Revision 1.2  2001/05/28 19:21:16  khatib
-- lpm component added
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


-- Dual port Memory core


entity dpmem_ent is
  generic (USE_RESET   :     boolean   := false;  -- use system reset
           USE_CS      :     boolean   := false;  -- use chip select signal
                                        --   This parameter is not used and the CS pin is
                                        --   always unconnected
           DEFAULT_OUT :     std_logic := '1';  -- Default output
           OPTION : integer := 2;     -- '1' Behavioral model
                                        -- '2' LMP_ram_dp component (structural component) model
         -- When OPTION = 2 USE_RESET,USE_CS and DEFAULT_OUT has no effect and
         -- ONLY 1 or 2 Can be assigned to CLK_DOMAIN
           CLK_DOMAIN  :     integer   := 1;  -- Clock Domain
                                        -- 2 := 2, clocks one for read and one
                                        -- for write
                                        -- 1 := Single clock for read and write
                                        -- 0 := Read does not have any clock
           ADD_WIDTH   :     integer   := 3;
           WIDTH       :     integer   := 8);
  port (
    W_clk              : in  std_logic;  -- write clock , or system clock
    R_clk              : in  std_logic;  -- Read clock
    reset              : in  std_logic;  -- System Reset
    W_add              : in  std_logic_vector(add_width -1 downto 0);  -- Write Address
    R_add              : in  std_logic_vector(add_width -1 downto 0);  -- Read Address
    Data_In            : in  std_logic_vector(WIDTH - 1 downto 0);  -- input data
    Data_Out           : out std_logic_vector(WIDTH -1 downto 0);  -- output Data
    WR                 : in  std_logic;  -- Write Enable
    RE                 : in  std_logic);  -- Read Enable
end dpmem_ent;


-------------------------------------------------------------------------------

architecture dpmem_beh of dpmem_ent is



  type data_array is array (integer range <>) of std_logic_vector(WIDTH -1 downto 0);
                                                      -- Memory Type
  signal data : data_array(0 to (2** add_width-1) );  -- Local data



  procedure init_mem(signal memory_cell : inout data_array ) is
  begin

    for i in 0 to (2** add_width-1) loop
      memory_cell(i) <= (others => '0');
    end loop;

  end init_mem;


  COMPONENT lpm_ram_dp
    GENERIC (
      lpm_width             : NATURAL;
      lpm_widthad           : NATURAL;
      lpm_indata            : STRING;
      lpm_wraddress_control : STRING;
      lpm_rdaddress_control : STRING;
      lpm_outdata           : STRING;
      lpm_hint              : STRING);
    PORT (
      rdclock   : IN  STD_LOGIC;
      wren      : IN  STD_LOGIC;
      wrclock   : IN  STD_LOGIC;
      q         : OUT STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
      rden      : IN  STD_LOGIC;
      data      : IN  STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
      rdaddress : IN  STD_LOGIC_VECTOR (ADD_WIDTH-1 DOWNTO 0);
      wraddress : IN  STD_LOGIC_VECTOR (ADD_WIDTH-1 DOWNTO 0));
  END COMPONENT;
  

begin  -- dpmem_beh
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
BEHAVIORAL: IF OPTION = 1 GENERATE
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  REASET_ENABLED : if USE_RESET = true generate

    CLOCKS_2 : if CLK_DOMAIN = 2 generate
-----------------------------------------------------------------------------
      -- purpose: Read process
      -- type   : sequential
      -- inputs : R_clk,reset
      -- outputs: 
      ReProc : process (R_clk, reset)
      begin  -- process ReProc
        if reset = '0' then
          Data_out   <= (others => DEFAULT_OUT);
        elsif R_clk'event and R_clk = '1' then  -- rising clock edge
          if Re = '1' then
            Data_out <= data(conv_integer(R_add));
          else
            Data_out <= (others => DEFAULT_OUT);
          end if;

        end if;
      end process ReProc;
-----------------------------------------------------------------------------
      -- purpose: Write process
      -- type   : sequential
      -- inputs : W_clk,reset
      -- outputs: 
      WrProc : process (W_clk, reset)
      begin  -- process WrProc
        if reset = '0' then
          init_mem ( data);
        elsif W_clk'event and W_clk = '1' then  -- rising clock edge
          if Wr = '1' then

            data(conv_integer(W_add)) <= Data_in;
          end if;

        end if;
      end process WrProc;
-------------------------------------------------------------------------------
    end generate CLOCKS_2;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
    CLOCKS_1 : if CLK_DOMAIN = 1 generate

      process (w_clk, reset)

      begin  -- PROCESS


        -- activities triggered by asynchronous reset (active low)
        if reset = '0' then
          data_out <= (others => DEFAULT_OUT);
          init_mem (data);

          -- activities triggered by rising edge of clock
        elsif w_clk'event and w_clk = '1' then
          if RE = '1' then
            data_out <= data(conv_integer(R_add));
          else
            data_out <= (others => DEFAULT_OUT);  -- Defualt value
          end if;

          if WR = '1' then
            data(conv_integeR(W_add)) <= Data_In;
          end if;
        end if;


      end process;
    end generate CLOCKS_1;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

    CLOCKS_0 : if CLK_DOMAIN = 0 generate
      -- purpose: Write process
      -- type   : sequential
      -- inputs : W_clk,reset
      -- outputs: 
      WrProc : process (W_clk, reset)
      begin  -- process WrProc
        if reset = '0' then
          init_mem (data);
        elsif W_clk'event and W_clk = '1' then  -- rising clock edge
          if Wr = '1' then

            data(conv_integer(W_add)) <= Data_in;
          end if;

        end if;
      end process WrProc;

      data_out <= data(conv_integer(R_add)) when RE = '1' else (others => DEFAULT_OUT);

    end generate CLOCKS_0;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

  end generate REASET_ENABLED;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  RESET_DISABLED : if USE_RESET = false generate


    CLOCKS_2 : if CLK_DOMAIN = 2 generate
-----------------------------------------------------------------------------
      -- purpose: Read process
      -- type   : sequential
      -- inputs : R_clk
      -- outputs: 
      ReProc : process (R_clk)
      begin  -- process ReProc

        if R_clk'event and R_clk = '1' then  -- rising clock edge
          if Re = '1' then
            Data_out <= data(conv_integer(R_add));
          else
            Data_out <= (others => DEFAULT_OUT);
          end if;

        end if;
      end process ReProc;
-----------------------------------------------------------------------------
      -- purpose: Write process
      -- type   : sequential
      -- inputs : W_clk
      -- outputs: 
      WrProc : process (W_clk)
      begin  -- process WrProc

        if W_clk'event and W_clk = '1' then  -- rising clock edge
          if Wr = '1' then

            data(conv_integer(W_add)) <= Data_in;
          end if;

        end if;
      end process WrProc;
-------------------------------------------------------------------------------
    end generate CLOCKS_2;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
    CLOCKS_1 : if CLK_DOMAIN = 1 generate

      process (w_clk)

      begin  -- PROCESS  
        -- activities triggered by rising edge of clock
        if w_clk'event and w_clk = '1' then
          if RE = '1' then
            data_out <= data(conv_integer(R_add));
          else
            data_out <= (others => DEFAULT_OUT);  -- Defualt value
          end if;

          if WR = '1' then
            data(conv_integeR(W_add)) <= Data_In;
          end if;
        end if;


      end process;
    end generate CLOCKS_1;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

    CLOCKS_0 : if CLK_DOMAIN = 0 generate
      -- purpose: Write process
      -- type   : sequential
      -- inputs : W_clk
      -- outputs: 
      WrProc : process (W_clk)
      begin  -- process WrProc

        if W_clk'event and W_clk = '1' then  -- rising clock edge
          if Wr = '1' then

            data(conv_integer(W_add)) <= Data_in;
          end if;

        end if;
      end process WrProc;

      data_out <= data(conv_integer(R_add)) when RE = '1' else (others => DEFAULT_OUT);

    end generate CLOCKS_0;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------


  end generate RESET_DISABLED;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
END GENERATE BEHAVIORAL;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
STRUCTURAL: IF OPTION = 2 GENERATE
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DUALCLKS: IF CLK_DOMAIN = 2 GENERATE
    mem_core: lpm_ram_dp
    GENERIC MAP (
      lpm_width             => WIDTH-1,
      lpm_widthad           => ADD_WIDTH-1,
      lpm_indata            => "REGISTERED",
      lpm_wraddress_control => "REGISTERED",
      lpm_rdaddress_control => "REGISTERED",
      lpm_outdata           => "UNREGISTERED",
      lpm_hint              => "USE_EAB=ON")
    PORT MAP (
      rdclock   => R_clk,
      wren      => WR,
      wrclock   => W_clk,
      q         => Data_Out,
      rden      => RE,
      data      => Data_In,
      rdaddress => R_add,
      wraddress => W_add);

END GENERATE DUALCLKS;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
SINGLECLK: IF CLK_DOMAIN = 1 GENERATE  
  mem_core: lpm_ram_dp
    GENERIC MAP (
      lpm_width             => WIDTH-1,
      lpm_widthad           => ADD_WIDTH-1,
      lpm_indata            => "REGISTERED",
      lpm_wraddress_control => "REGISTERED",
      lpm_rdaddress_control => "REGISTERED",
      lpm_outdata           => "UNREGISTERED",
      lpm_hint              => "USE_EAB=ON")
    PORT MAP (
      rdclock   => W_clk,
      wren      => WR,
      wrclock   => W_clk,
      q         => Data_Out,
      rden      => RE,
      data      => Data_In,
      rdaddress => R_add,
      wraddress => W_add);

END GENERATE SINGLECLK;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
END GENERATE STRUCTURAL;            
  
-------------------------------------------------------------------------------
end dpmem_beh;
-------------------------------------------------------------------------------











