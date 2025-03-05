-------------------------------------------------------------------------------
-- Title      : CIC Testbench
-------------------------------------------------------------------------------
-- File       : cic_tb.vhd
-- Author     : Nainika Saha
-- Created    : 2025-02-13
-- Last update: 2023-09-07
-- Platform   : Vivado
-- Standard   : VHDL 2008
-------------------------------------------------------------------------------
-- Description: Cascaded Integrator Comb Testbench using TEXTIO
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
library std;
use std.env.all;

entity cic_tb is
end entity;

architecture testbench of cic_tb is

    constant CI_SIZE : integer := 18;  -- CIC input data width
    constant CO_SIZE : integer := 30;  -- CIC output data width
    constant STAGES  : integer := 5;   -- Number of filter stages
    constant CLK_PERIOD : time := 12.5 ns;  -- 80 MHz Clock

    -- DUT Component Declaration
    component cic
        port (
            clk  : in  std_logic;
            ce   : in  std_logic;
            ce_r : in  std_logic;
            rst  : in  std_logic;
            d    : in  std_logic_vector (CI_SIZE - 1 downto 0);
            q    : out std_logic_vector (CO_SIZE - 1 downto 0)
        );
    end component;

    -- Testbench Signals
    signal clk_tb  : std_logic := '0';
    signal rst_tb  : std_logic := '0';
    signal ce_tb   : std_logic := '1';
    signal ce_r_tb : std_logic := '0';
    signal clk_div_tb : integer := 0;

    signal d_tb    : std_logic_vector(CI_SIZE-1 downto 0) := (others => '0');  
    signal q_tb    : std_logic_vector(CO_SIZE-1 downto 0);  

begin

  -- Clock Generation: Free Running 80 MHz Clock
  clk_process : process
  begin
    clk_tb <= '0';
    wait for CLK_PERIOD/2;
    clk_tb <= '1';
    wait for CLK_PERIOD/2;
  end process;

  -- Generate ce_r_tb (Decimated Clock: One Pulse Every 5 Cycles)
  ce_r_process: process(clk_tb)
  begin
    if rising_edge(clk_tb) then
        if clk_div_tb = 4 then
            ce_r_tb <= '1';
            clk_div_tb <= 0;
            report "ce_r_tb toggled HIGH at: " & time'image(now);
        else
            ce_r_tb <= '0';
            clk_div_tb <= clk_div_tb + 1;
        end if;
    end if;
  end process;

  -- ? Device Under Test (DUT) without generics
  DUT: cic
    port map (
        clk  => clk_tb,
        ce   => ce_tb,
        ce_r => ce_r_tb,
        rst  => rst_tb,
        d    => d_tb,
        q    => q_tb
    );

  -- Test Process: Apply Data & Read/Write to Files
  test_case : process
      file input_file : text;
      file output_file : text;
      variable input_line   : line;
      variable output_line  : line;
      variable data_in      : real;
      variable int_data     : integer;
      variable data_out     : integer;
      variable sample_count : integer;
      variable sample_index : integer;
  begin
      wait for 30 ns;

      -- Loop through 3 test cases (8 MHz, 16 MHz, 24 MHz)
      for test_case_id in 1 to 3 loop
          -- Apply Reset Before Each Test Case
          report "Applying Reset before test case " & integer'image(test_case_id);
          rst_tb <= '1';
          wait for CLK_PERIOD;  
          rst_tb <= '0';
          wait for CLK_PERIOD;  -- Allow filter to stabilize

          -- Open corresponding input and output files
          if test_case_id = 1 then
              file_open(input_file, "C:\Users\naini\Downloads\Saha_Nainika_lab3\Saha_Nainika_Lab3\sinewave_8MHz.txt", read_mode);
              file_open(output_file, "C:\Users\naini\Downloads\Saha_Nainika_lab3\Saha_Nainika_Lab3\output_8MHz.txt", write_mode);
              sample_count := 10;
          elsif test_case_id = 2 then
              file_open(input_file, "C:\Users\naini\Downloads\Saha_Nainika_lab3\Saha_Nainika_Lab3\sinewave_16MHz.txt", read_mode);
              file_open(output_file, "C:\Users\naini\Downloads\Saha_Nainika_lab3\Saha_Nainika_Lab3\output_16MHz.txt", write_mode);
              sample_count := 5;
          else
              file_open(input_file, "C:\Users\naini\Downloads\Saha_Nainika_lab3\Saha_Nainika_Lab3\sinewave_24MHz.txt", read_mode);
              file_open(output_file, "C:\Users\naini\Downloads\Saha_Nainika_lab3\Saha_Nainika_Lab3\output_24MHz.txt", write_mode);
              sample_count := 3;
          end if;

          sample_index := 0;

          -- Apply data samples per cycle for correct waveform repetition
          while not endfile(input_file) loop
              for i in 0 to sample_count - 1 loop
                  if not endfile(input_file) then
                      readline(input_file, input_line);
                      if input_line'length > 0 then
                          read(input_line, data_in);
                      else
                          report "Empty line detected! Skipping...";
                          next;
                      end if;
                  end if;

                  -- Convert floating-point to 18-bit integer
                  int_data := integer(data_in * real(integer(2**(CI_SIZE-1) - 1)));

                  -- Apply input data
                  wait until rising_edge(clk_tb);
                  if rst_tb = '1' then
                      d_tb <= (others => '0');
                  else
                      d_tb <= std_logic_vector(to_signed(int_data, CI_SIZE));
                  end if;

                  -- Capture output as INTEGER and immediately write it
                  wait until rising_edge(clk_tb);
                  data_out := to_integer(signed(q_tb));

                  -- Debugging prints
                  report "Applying Input: " & integer'image(int_data);
                  report "CIC Output (Integer): " & integer'image(data_out);

                  -- Write integer output to file immediately
                  write(output_line, data_out);
                  writeline(output_file, output_line);

                  -- Handle 3.33 samples per cycle for 24 MHz
                  if test_case_id = 3 and (sample_index mod 3 = 2) then
                      readline(input_file, input_line);
                  end if;

                  sample_index := sample_index + 1;
              end loop;
          end loop;

          -- Close files after processing each test case
          file_close(input_file);
          file_close(output_file);
      end loop;

      -- Stop Simulation After Processing All Test Cases
      report "Simulation Completed Successfully!";
      std.env.finish;
  end process;

end architecture;
