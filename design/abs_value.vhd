library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity abs_value is
    generic(DATA_WIDTH: integer := 32);
    port(
        original: in std_logic_vector(DATA_WIDTH-1 downto 0);
		absolute: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
	
end abs_value ;

architecture behavioral of abs_value is

	signal fixed: unsigned(DATA_WIDTH-1 downto 0);
 begin
 
	fixed <= unsigned(not original) + 1;
 
    process(fixed) 
	begin
	if (original(DATA_WIDTH-1) = '1') then
		absolute <= std_logic_vector(fixed);
	else
		absolute <= original;
	end if;
	
	end process;

end behavioral;
