library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity register_file is
    generic(
        DATA_WIDTH: integer := 32;
        ADDRESS_WIDTH: integer := 5
    );
    
    port(
        clk: in std_logic;
        reset_n: in std_logic;
        write_en: in std_logic;
        read1_id: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        read2_id: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        write_id: in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
        write_data: in std_logic_vector(DATA_WIDTH-1 downto 0);
        read1_data: out std_logic_vector(DATA_WIDTH-1 downto 0);
        read2_data: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end register_file;

architecture behavioral of register_file is

    constant REGISTER_FILE_SIZE: natural := 2 ** (ADDRESS_WIDTH);

    type register_array is array (0 to REGISTER_FILE_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal registers: register_array := ( others => (others => '0'));
    
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

    regFile: process(clk) is
    begin
        if rising_edge(clk) then
            if reset_n = '1' then
                for i in 0 to registers'length-1 loop
                    registers(i) <= (others => '0');
                end loop;
            else
                if write_en = '1' then
                    registers(to_integer(unsigned(write_id))) <= write_data;
                end if;
            end if;
        end if;
    end process;

    read1_data <= registers(to_integer(unsigned(read1_id)));
    read2_data <= registers(to_integer(unsigned(read2_id)));
    
    
--	ILA_REGFILE: ila_regs port map(
--    clk => clk,
--    probe0 => registers(7),
--    probe1 => registers(8),
--    probe2 => write_data,
--    probe3 => registers(9),
--    probe4 => write_id,
--    probe5(0) => write_en
--    );
    

end behavioral;
