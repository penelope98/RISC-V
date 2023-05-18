library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comparator is
    generic(DATA_WIDTH: integer := 32);
    port(
        left_operand: in std_logic_vector(DATA_WIDTH-1 downto 0);
        right_operand: in std_logic_vector(DATA_WIDTH-1 downto 0);
        equal32: out std_logic; 
		great32: out std_logic; 
		less32: out std_logic
    );
end comparator;

architecture behavioral of comparator is

	component comparator_comp
		port (a,b,g,l,e: in std_logic;
			  great,less,equal: out std_logic);
	end component;

  signal gre : std_logic_vector(DATA_WIDTH downto 0);
  signal les : std_logic_vector(DATA_WIDTH downto 0);
  signal equ : std_logic_vector(DATA_WIDTH downto 0);
  

begin
 
    gre(DATA_WIDTH) <= '0';
    les(DATA_WIDTH) <= '0';
    equ(DATA_WIDTH) <= '1';

  gen: 
      for i in 0 to DATA_WIDTH-1 generate
  COMP_UNIT:
          comparator_comp 
              port map ( 
                  a => left_operand(i),
                  b => right_operand(i),
                  g => gre(i+1),   -- gre(i),
                  l => les(i+1),   -- les(i), 
                  e => equ(i+1),   -- equ(i), 
                  great => gre(i), -- gre(i+1), 
                  less => les(i),  -- les(i+1), 
                  equal => equ(i)  -- equ(i+1)
              );		
		
    great32 <= gre(0);
    less32 <= les(0);          
    equal32 <= equ(0);
	end generate;

end behavioral;
