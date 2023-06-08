library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity data_memory is
    generic (
        ADDRESS_WIDTH: natural := 6;
        DATA_WIDTH: natural := 32
    );
    
    port (
        clk: in std_logic;
		reset: in std_logic;
        write_en: in std_logic;
        write_data: in std_logic_vector(DATA_WIDTH-1 downto 0);
        address: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        read_data : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end data_memory;

architecture behavioral of data_memory is

    constant MEMORY_DEPTH: natural := 2 ** ADDRESS_WIDTH;
    
    type ram_type is array (0 to MEMORY_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal ram: ram_type := (
        others => "00000000000000000000000000000000"
    );

--    component ila_regs port(
--        clk: in std_logic;
--        probe0: in std_logic_vector(31 downto 0);
--        probe1: in std_logic_vector(31 downto 0);
--        probe2: in std_logic_vector(31 downto 0);
--        probe3: in std_logic_vector(31 downto 0);
--        probe4: in std_logic_vector(4 downto 0);
--        probe5: in std_logic_vector(0 downto 0 ));
--    end component;




begin

    data_ram: process (clk) is
    begin
        if rising_edge(clk) then
		
			if reset = '0' then
				ram <= (others=> (others=>'0'));
            elsif write_en = '1' then
                ram(to_integer(unsigned(address))) <= write_data;
            end if;
        end if;
    end process data_ram;

    read_data <= ram(to_integer(unsigned(address)));
    
    
--    ILA_RAMS: ila_regs port map(
--    clk => clk,
--    probe0 => write_data,
--    probe1 => ram(0),
--    probe2 => ram(1),
--    probe3 => ram(2),
--    probe4 => address(4 downto 0) ,
--    probe5(0) => write_en
--    );


end behavioral;
