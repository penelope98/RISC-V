library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


entity top_wrapper is
    generic (
        PROGRAM_ADDRESS_WIDTH: natural := 10;
        DATA_ADDRESS_WIDTH: natural := 6;
        CPU_DATA_WIDTH: natural := 32;
		CPU_COMPRESSED_WIDTH: natural := 16;
		CHARACTER_SIZE: natural := 8
    );
    
    port (
        clk: in std_logic;
        reset_n: in std_logic;
		input_data: in std_logic;
		output_led: out std_logic
    );
end top_wrapper;

architecture Behavioral of top_wrapper is


    component clk_wizard_top
    port (
        clk_in1: in std_logic;
        clk_out1: out std_logic
    );
    end component;
    signal new_clk: std_logic;

begin

    system: entity work.system_serial
        generic map (
        PROGRAM_ADDRESS_WIDTH => PROGRAM_ADDRESS_WIDTH,
        DATA_ADDRESS_WIDTH => DATA_ADDRESS_WIDTH,
        CPU_DATA_WIDTH => CPU_DATA_WIDTH,
		CPU_COMPRESSED_WIDTH => CPU_COMPRESSED_WIDTH,
		CHARACTER_SIZE => CHARACTER_SIZE
        )
        port map (
                clk => new_clk,
                reset_n => reset_n,
		        input_data => input_data,
		        output_led => output_led
        );
     

    clock_wizard_inst : clk_wizard_top
        port map (
        clk_in1 => clk,
        clk_out1 => new_clk
        );


end Behavioral;
