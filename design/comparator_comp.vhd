library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity comparator_comp is
    port(
	  a : in std_logic ;
      b : in std_logic ;
      g : in std_logic ;
      l : in std_logic ;
      e : in std_logic ;
      great : out std_logic ;
      less : out std_logic ;
      equal : out std_logic );
end comparator_comp;

architecture behavioral of comparator_comp is

signal s1,s2,s3: std_logic;
 begin
 
    s1 <= (a and (not b));
    s2  <= (not ((a and (not b)) or (b and (not a))));
    s3 <= (b and (not a));
    equal <= (e and s2);
    great <= (g or(e and s1));
    less  <= (l or(e and s3));

end behavioral;
