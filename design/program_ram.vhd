library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;


entity program_ram is
    generic (
        PROGRAM_ADDRESS_WIDTH: natural := 6;
        DATA_WIDTH: natural := 32
    );
    
    port (
        clk: in std_logic;
		reset: in std_logic;
        write_en: in std_logic;
        write_data: in std_logic_vector(DATA_WIDTH/2-1 downto 0);
        address: in std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);
        read_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end program_ram;

architecture behavioral of program_ram is

    constant MEMORY_DEPTH: natural := 2 ** PROGRAM_ADDRESS_WIDTH+1;
    type ram_type is array (0 to MEMORY_DEPTH-1) of std_logic_vector(DATA_WIDTH/2 -1 downto 0);     
    signal ram: ram_type;
    alias word_address: std_logic_vector(PROGRAM_ADDRESS_WIDTH-2 downto 0) is address(PROGRAM_ADDRESS_WIDTH-1 downto 1);

    signal debug_read: std_logic_vector(DATA_WIDTH-1 downto 0);

--    component ila_regs port(
--        clk: in std_logic;
--        probe0: in std_logic_vector(31 downto 0);
--        probe1: in std_logic_vector(15 downto 0);
--        probe2: in std_logic_vector(15 downto 0);
--        probe3: in std_logic_vector(8 downto 0);
--        probe4: in std_logic_vector(4 downto 0);
--        probe5: in std_logic_vector(0 downto 0 ));
--    end component;


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

    debug_read <= ram(to_integer(unsigned(word_address))+1)& ram(to_integer(unsigned(word_address)));
    read_data <= debug_read;
    
--	ILA_RAM: ila_regs port map(
--    clk => clk,
--    probe0 => debug_read,
--    probe1 => ram(4),
--    probe2 => ram(5),
--    probe4 => address(4 downto 0),
--    probe3 => word_address,
--    probe5(0) => write_en
--    );


end behavioral;
