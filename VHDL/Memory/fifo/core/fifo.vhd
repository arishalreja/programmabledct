-------------------------------------------------------------------------------
-- Title      :  First In First Out buffer
-- Project    :  Memory Cores
-------------------------------------------------------------------------------
-- File        : fifo.vhd
-- Author      : Jamil Khatib  (khatib@ieee.org)
-- Organization: OpenIPCore Project
-- Created     : 1999/5/14
-- Last update:2001/06/01
-- Platform    : 
-- Simulators  : Modelsim 5.3XE/Windows98,NC-Sim/Linux
-- Synthesizers: Leonardo/Windows98
-- Target      : 
-- Dependency  : ieee.std_logic_1164,ieee.std_logic_unsigned
--               memLib.mem_pkg
--               utility.tools_pkg
-------------------------------------------------------------------------------
-- Description:  FIFO buffer
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
-- Date            :   10 Oct 1999
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   Created
-- Known bugs      :   
-- To Optimze      :   
-------------------------------------------------------------------------------
-- Revisions  :
-- Revision Number :   2
-- Version         :   0.2
-- Date            :   21 Feb 2001
-- Modifier        :   Jamil Khatib (khatib@ieee.org)
-- Desccription    :   General review (major rewrite)
-- Known bugs      :   
-- To Optimze      :   
-------------------------------------------------------------------------------
-- $Log: fifo.vhd,v $
-- Revision 1.2  2001/06/04 20:21:56  khatib
-- lpm component added
--
-- Revision 1.2  2001/06/03 09:17:10  jamil
-- Dual clocks and LPM added
--
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

LIBRARY utility;
LIBRARY memlib;
USE utility.tools_pkg.ALL;
USE memlib.mem_pkg.ALL;

ENTITY FIFO_ent IS


  GENERIC (
    ARCH : INTEGER := 0;                -- FIFO internal architecture
                                        -- This parameter is not used

    USE_CS      : BOOLEAN   := FALSE;   -- use chip select signal
                                        -- This parameter is not used and the CS pin is unconnected
    DEFAULT_OUT : STD_LOGIC := '1';     -- Default output
    CLK_DOMAIN  : INTEGER   := 1;       -- Clock domain
                                        -- 1: same clock for read and write
                                        -- (write_clock is used)
                                        -- 2: different clocks for read and write
                                        -- 0: Asynchronous read (single clock
                                        -- for write)

    MEM_CORE   : INTEGER := 2;          -- memory core
                                        -- 0: Dual Port memory
                                        -- 1: Single Port memory
                                        -- 2: LMP altera core
    BLOCK_SIZE : INTEGER := 1;          -- Block size in no of WDITH bits
                                        -- read or written in burst
                                        -- BLOCK_SIZE is Not used in current release
    WIDTH      : INTEGER := 8;          -- Word Size
    DEPTH      : INTEGER := 8);         -- FIFO depth

  PORT (
    rst_n      : IN  STD_LOGIC;         -- System reset
    Rclk       : IN  STD_LOGIC;         -- Read clock
    Wclk       : IN  STD_LOGIC;         -- Write Clock
    cs         : IN  STD_LOGIC;         -- Chip Select
    Din        : IN  STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  -- Data in
    Dout       : OUT STD_LOGIC_VECTOR(WIDTH-1 DOWNTO 0);  -- Data out
    Re         : IN  STD_LOGIC;         -- Read signal
    wr         : IN  STD_LOGIC;         -- Write signal
    RUsedCount : OUT STD_LOGIC_VECTOR(log2(DEPTH)-1 DOWNTO 0);  -- Used data counter(RClk)
    WUsedCount : OUT STD_LOGIC_VECTOR(log2(DEPTH)-1 DOWNTO 0);  -- Used data counter(Wclk)
    Full       : OUT STD_LOGIC;         -- Full Flag (combinational)
    Empty      : OUT STD_LOGIC;         -- Empty flag (combinational)
    RFull      : OUT STD_LOGIC;         -- Full Flag (Rclk)
    RHalf_full : OUT STD_LOGIC;         -- Half full flag (Rclk)
    REmpty     : OUT STD_LOGIC;         -- Empty flag (Rclk)
    WFull      : OUT STD_LOGIC;         -- Full Flag (Wclk)
    WHalf_full : OUT STD_LOGIC;         -- Half full flag (Wclk)
    WEmpty     : OUT STD_LOGIC);        -- Empty flag (Wclk)

END FIFO_ent;

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
ARCHITECTURE fifo_beh OF FIFO_ent IS
-- constant values
  CONSTANT ADD_WIDTH : INTEGER := log2(DEPTH);  -- Address Width

  CONSTANT MAX_ADDR : STD_LOGIC_VECTOR(ADD_WIDTH -1 DOWNTO 0) := (OTHERS => '1');
  CONSTANT MIN_ADDR : STD_LOGIC_VECTOR(ADD_WIDTH -1 DOWNTO 0) := (OTHERS => '0');


-- components
  COMPONENT dcfifo
    GENERIC (
      lpm_width     :     NATURAL;
      lpm_numwords  :     NATURAL;
      lpm_showahead :     STRING;
      lpm_hint      :     STRING);
    PORT (
      rdfull        : OUT STD_LOGIC;
      wrclk         : IN  STD_LOGIC;
      rdempty       : OUT STD_LOGIC;
      rdreq         : IN  STD_LOGIC;
      wrusedw       : OUT STD_LOGIC_VECTOR (ADD_WIDTH -1 DOWNTO 0);
      wrfull        : OUT STD_LOGIC;
      wrempty       : OUT STD_LOGIC;
      rdclk         : IN  STD_LOGIC;
      q             : OUT STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
      wrreq         : IN  STD_LOGIC;
      data          : IN  STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
      rdusedw       : OUT STD_LOGIC_VECTOR (ADD_WIDTH-1 DOWNTO 0));
  END COMPONENT;


  COMPONENT scfifo
    GENERIC (
      lpm_width     :     NATURAL;
      lpm_numwords  :     NATURAL;
      lpm_showahead :     STRING;
      lpm_hint      :     STRING);
    PORT (
      usedw         : OUT STD_LOGIC_VECTOR (ADD_WIDTH-1 DOWNTO 0);
      rdreq         : IN  STD_LOGIC;
      empty         : OUT STD_LOGIC;
      aclr          : IN  STD_LOGIC;
      clock         : IN  STD_LOGIC;
      q             : OUT STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
      wrreq         : IN  STD_LOGIC;
      data          : IN  STD_LOGIC_VECTOR (WIDTH-1 DOWNTO 0);
      full          : OUT STD_LOGIC);
  END COMPONENT;

-------------------------------------------------------------------------------
  SIGNAL W_add_i : STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);  -- Internal Write address
  SIGNAL R_add_i : STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);
                                        -- Internal Read Address

  SIGNAL D_add_i : STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);  -- Diff Address


  SIGNAL full_i  : STD_LOGIC;           -- Internal full
  SIGNAL empty_i : STD_LOGIC;           -- Internal empty

  SIGNAL W_add_old : STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);
  SIGNAL R_add_old : STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);
-------------------------------------------------------------------------------
BEGIN  -- fifo_beh


-------------------------------------------------------------------------------
  SINGLE_CLK : IF CLK_DOMAIN = 1 GENERATE
-------------------------------------------------------------------------------
    DP_MEM   : IF MEM_CORE = 0 GENERATE

-- purpose: Write Read process
-- type   : sequential
-- inputs : Wclk, rst_n
-- outputs: 
      Write_Read           : PROCESS (Wclk, rst_n)
        VARIABLE D_add_var : STD_LOGIC_VECTOR(ADD_WIDTH-1 DOWNTO 0);  -- Diff address

      BEGIN  -- process Write_Read
        IF rst_n = '0' THEN             -- asynchronous reset (active low)

          W_add_i   <= (OTHERS => '0');
          R_add_i   <= (OTHERS => '0');
          D_add_i   <= (OTHERS => '0');
          D_add_var := (OTHERS => '0');

          RFull <= '0';
          WFull <= '0';

          REmpty <= '1';
          WEmpty <= '1';
        ELSIF Wclk'event AND Wclk = '1' THEN  -- rising clock edge

          IF WR = '1' THEN

            W_add_i   <= W_add_i +1;
            D_add_var := D_add_var+1;

          END IF;

          IF RE = '1' THEN

            R_add_i   <= R_add_i +1;
            D_add_var := D_add_var-1;

          END IF;

          RFull <= full_i;
          WFull <= full_i;

          REmpty  <= empty_i;
          WEmpty  <= empty_i;
          D_add_i <= D_add_var;

        END IF;
      END PROCESS Write_Read;

      -- generate internal flags
      empty_i <= '1' WHEN (D_add_i = MIN_ADDR)ELSE '0';
      full_i  <= '1' WHEN (D_add_i = MAX_ADDR) ELSE '0';

      Full  <= full_i;
      Empty <= empty_i;


      RUsedCount <= D_add_i;
      WUsedCount <= D_add_i;

      RHalf_full <= D_add_i(ADD_WIDTH -1);
      WHalf_full <= D_add_i(ADD_WIDTH -1);

      mem_core : dpmem_ent
        GENERIC MAP (
          USE_RESET   => FALSE,
          USE_CS      => FALSE,
          DEFAULT_OUT => DEFAULT_OUT,
          OPTION      => 1,
          CLK_DOMAIN  => 1,
          ADD_WIDTH   => ADD_WIDTH,
          WIDTH       => WIDTH)
        PORT MAP (
          W_clk       => Wclk,
          R_clk       => Rclk,
          reset       => rst_n,
          W_add       => W_add_i,
          R_add       => R_add_i,
          Data_In     => Din,
          Data_Out    => Dout,
          WR          => WR,
          RE          => RE);
    END GENERATE DP_MEM;
-------------------------------------------------------------------------------
    LMP        : IF MEM_CORE = 2 GENERATE
      Full       <= full_i;
      Empty      <= empty_i;
      RFull      <= full_i;
      REmpty     <= empty_i;
      WFull      <= full_i;
      WEmpty     <= empty_i;
      WUsedCount <= D_add_i;
      RUsedCount <= D_add_i;

      scfifo_component : scfifo
        GENERIC MAP (
          lpm_width     => WIDTH,
          lpm_numwords  => 2**ADD_WIDTH,
          lpm_showahead => "OFF",
          lpm_hint      => "USE_EAB = ON"
          )
        PORT MAP (
          rdreq         => re,
          aclr          => rst_n,
          clock         => Wclk,
          wrreq         => wr,
          data          => Din,
          usedw         => D_add_i,
          empty         => empty_i,
          q             => Dout,
          full          => full_i
          );

    END GENERATE LMP;
-------------------------------------------------------------------------------
  END GENERATE SINGLE_CLK;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
  DUAL_CLK : IF CLK_DOMAIN = 2 GENERATE
-------------------------------------------------------------------------------
    DP_MEM : IF MEM_CORE = 0 GENERATE

      -- purpose: Read Process
      -- type   : sequential
      -- inputs : Rclk, rst_n
      -- outputs: 
      Read_proc : PROCESS (Rclk, rst_n)

      BEGIN  -- PROCESS Read_proc

        IF rst_n = '0' THEN             -- asynchronous reset (active low)
          R_add_i   <= (OTHERS => '0');
          R_add_old <= (OTHERS => '1');

          REmpty <= '1';
          RFull  <= '0';
        ELSIF Rclk'event AND Rclk = '1' THEN  -- rising clock edge


          IF (re = '1') THEN
            R_add_i   <= R_add_i +1;
            R_add_old <= R_add_i;
          END IF;

          REmpty <= empty_i;
          RFull  <= full_i;
        END IF;

      END PROCESS Read_proc;

      empty_i <= '1' WHEN R_add_i = W_add_i
                 ELSE '0';
      full_i  <= '1' WHEN W_add_i = R_add_old
                 ELSE '0';

      Full  <= full_i;
      Empty <= empty_i;

      -- purpose: Write Process
      -- type   : sequential
      -- inputs : Wclk, rst_n
      -- outputs: 
      Write_proc : PROCESS (Wclk, rst_n)

      BEGIN  -- PROCESS Write_proc

        IF rst_n = '0' THEN             -- asynchronous reset (active low)
          W_add_i   <= (OTHERS => '0');
          W_add_old <= (OTHERS => '1');

          WFull  <= '0';
          WEmpty <= '1';
        ELSIF Wclk'event AND Wclk = '1' THEN  -- rising clock edge

          IF (wr = '1') THEN
            W_add_i   <= W_add_i +1;
            W_add_old <= W_add_i;
          END IF;

          WFull  <= full_i;
          WEmpty <= empty_i;
        END IF;

      END PROCESS Write_proc;


      mem_core : dpmem_ent
        GENERIC MAP (
          USE_RESET   => FALSE,
          USE_CS      => FALSE,
          DEFAULT_OUT => DEFAULT_OUT,
          OPTION      => 1,
          CLK_DOMAIN  => 1,
          ADD_WIDTH   => ADD_WIDTH,
          WIDTH       => WIDTH)
        PORT MAP (
          W_clk       => Wclk,
          R_clk       => Rclk,
          reset       => rst_n,
          W_add       => W_add_i,
          R_add       => R_add_i,
          Data_In     => Din,
          Data_Out    => Dout,
          WR          => WR,
          RE          => RE);

    END GENERATE DP_MEM;
-------------------------------------------------------------------------------

    LMP : IF MEM_CORE = 2 GENERATE

      dcfifo_component : dcfifo
        GENERIC MAP (
          lpm_width     => WIDTH,
          lpm_numwords  => 2**ADD_WIDTH,
          lpm_showahead => "OFF",
          lpm_hint      => "USE_EAB = ON, CLOCKS_ARE_SYNCHRONIZED = FALSE"
          )
        PORT MAP (
          wrclk         => Wclk,
          rdreq         => RE,
          rdclk         => Rclk,
          wrreq         => WR,
          data          => Din,
          rdfull        => RFull,
          rdempty       => REmpty,
          wrusedw       => WUsedCount,
          wrfull        => WFull,
          wrempty       => WEmpty,
          q             => Dout,
          rdusedw       => RUsedCount
          );

    END GENERATE LMP;
-------------------------------------------------------------------------------
  END GENERATE DUAL_CLK;
-------------------------------------------------------------------------------

END fifo_beh;
