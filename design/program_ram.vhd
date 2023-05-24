library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


entity program_ram is
    generic (
        PROGRAM_ADDRESS_WIDTH: natural := 10;
        DATA_WIDTH: natural := 32
    );
    
    port (
        clk: in std_logic;
		reset: in std_logic;
        write_en: in std_logic;
        write_data: in std_logic_vector(DATA_WIDTH-1 downto 0);
        address: in std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);
        read_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end program_ram;

architecture behavioral of program_ram is

    constant MEMORY_DEPTH: natural := 2 ** PROGRAM_ADDRESS_WIDTH;
    type ram_type is array (0 to MEMORY_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0); 
    signal ram: ram_type;
    alias word_address: std_logic_vector(PROGRAM_ADDRESS_WIDTH-3 downto 0) is address(PROGRAM_ADDRESS_WIDTH-1 downto 2);


--       component ila_regs port(
--            clk: in std_logic;
--            probe0: in std_logic_vector(31 downto 0);
--            probe1: in std_logic_vector(0 downto 0);
--            probe2: in std_logic_vector(0 downto 0) );
--        end component;


begin

    instruction_ram: process (clk) is
    begin
        if rising_edge(clk) then
		
			if( reset = '0') then 
				ram <= (others=> (others=>'0'));
			elsif write_en = '1' then
                ram(to_integer(unsigned(word_address))) <= write_data;
            end if;
        end if;
    end process instruction_ram;

    read_data <= ram(to_integer(unsigned(word_address)));

--    ILA_RAM: ila_regs port map(
--    clk => clk,
--    probe0 => std_logic_vector(ram(0)),
--    probe1(0) => ram(0)(0),
--    probe2(0) => ram(0)(1)
--    );



end behavioral;
