library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


entity top_testbench is

end top_testbench;

architecture Behavioral of top_testbench is

    constant CLOCK_PERIOD: time := 10 ns;
    constant RESET_STOP: time := 10 ns;
    
    signal tb_clk,tb_reset,tb_led,tb_data: std_logic;
            
    
begin


    tb_reset <= '1' after RESET_STOP;         
    tb_clk <= not tb_clk after CLOCK_PERIOD / 2;
    ------------------------------------------
    risc_v_design: entity work.top_wrapper 
    generic map(
        PROGRAM_ADDRESS_WIDTH => 10,
        DATA_ADDRESS_WIDTH => 6,
        CPU_DATA_WIDTH => 32,
		CPU_COMPRESSED_WIDTH => 16,
		CHARACTER_SIZE => 8
    ) 
    port map(
        clk => tb_clk,
        reset_n => tb_reset,
		input_data => tb_data,
		output_led => tb_led
    );
    
    
    
    
    
    
    
    


end Behavioral;
