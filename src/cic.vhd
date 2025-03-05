-------------------------------------------------------------------------------
-- Title      : CIC
-------------------------------------------------------------------------------
-- File       : cic.vhd
-- Author     : Nainika Saha
-- Created    : 2025-13-02
-- Last update: 2023-09-07
-- Platform   : Vivado
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Cascaded Integrator Comb (CIC)
-- It consists of:
--   1) An integrator section (which acts like an accumulator)
--   2) A comb (differentiator) section (which subtracts delayed values)
--   3) Decimation by a factor of 5 (controlled by ce_r)
-------------------------------------------------------------------------------
-- Copyright (c) 
-------------------------------------------------------------------------------
-- Revisions  : 1.0
-- Date        Version  Author  Description
-- 2023-09-07  1.0      ptracton        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
entity cic is
  generic (
    CI_SIZE : integer := 18;            -- cic input data width
    CO_SIZE : integer := 30;            -- cic output data width
    STAGES  : integer := 5);
  port (
    clk  : in  std_logic;               -- system clock (80 Mhz)
    ce   : in  std_logic;               -- clock enable
    ce_r : in  std_logic;  -- decimated clock by factor of 5 used in comb section
    rst  : in  std_logic;               -- system reset
    d    : in  std_logic_vector (CI_SIZE - 1 downto 0);   -- input data
    q    : out std_logic_vector (CO_SIZE - 1 downto 0));  -- output data
end cic;
architecture syn of cic is
  
  ------------------------------------------------------------------------------  
  -- array definition for integrator and comb section
  ------------------------------------------------------------------------------
  type d_array_type is array (STAGES downto 0) of std_logic_vector(CO_SIZE - 1 downto 0);

  ------------------------------------------------------------------------------
  -- array definition for comb section
  ------------------------------------------------------------------------------
  type array_type is array (STAGES downto 1) of std_logic_vector(CO_SIZE - 1 downto 0);
  signal d_fs  : d_array_type;          -- used in the integrator section
  signal d_fsr : d_array_type;  -- used in the differentiator section, at rate r
  signal m1    : array_type;  -- used in the differentiator section, at rate r
  signal id    : std_logic_vector(CO_SIZE - 1 downto 0) := (others => '0');  -- to use for sign extended version of the input
  
begin
  ------------------------------------------------------------------------------
  -- output data
  ------------------------------------------------------------------------------
  q <= d_fsr(STAGES);

  ------------------------------------------------------------------------------
  -- input data (d input is sign extended to 30 bits)
  ------------------------------------------------------------------------------
  id(CO_SIZE - 1 downto CI_SIZE) <= (others => d(CI_SIZE - 1));
  id(CI_SIZE - 1 downto 0)       <= d;

  ------------------------------------------------------------------------------
  -- integrator section
  ------------------------------------------------------------------------------
  process (clk)
  begin
    if (clk'event and clk = '1') then  -- Rising edge trigger
      if (rst = '1') then
        d_fs(0) <= (others => '0'); -- resetting all inputs of integrator to zero
        for i in 1 to STAGES loop
          d_fs(i) <= (others => '0');
        end loop;
      elsif (ce = '1') then
        d_fs(0) <= id;  -- first data for integrator
        -- each state of the integrator accumulates its previous state's output
        for i in 1 to STAGES loop
          d_fs(i) <= d_fs(i - 1) + d_fs(i); 
        end loop;
      end if;
    end if;
  end process;


  ------------------------------------------------------------------------------
  -- differentiator (comb) section
  ------------------------------------------------------------------------------
  process (clk)
  begin
    if (clk'event and clk = '1') then
      if (rst = '1') then
        d_fsr(0) <= (others => '0'); -- resetting all comb outputs to zero
        for i in 1 to STAGES loop
          m1(i)    <= (others => '0');
          d_fsr(i) <= (others => '0');
        end loop;
      elsif (ce = '1') then -- differentiating states at decimated rate
        d_fsr(0) <= d_fs(STAGES);
        if (ce_r = '1') then
          for i in 1 to STAGES loop
            m1(i)    <= d_fsr(i - 1); -- stores previous value
            d_fsr(i) <= d_fsr(i - 1) - m1(i); -- high pass effect
          end loop;
        else
          m1 <= m1; -- holding previous value
          for i in 1 to STAGES loop
            d_fsr(i) <= d_fsr(i);
          end loop;
        end if;
      end if;
    end if;
  end process;
end syn;
