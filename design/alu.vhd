library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity alu is
    generic(DATA_WIDTH: integer := 32);

    port(
        control: in std_logic_vector(3 downto 0);
        left_operand: in std_logic_vector(DATA_WIDTH-1 downto 0);
        right_operand: in std_logic_vector(DATA_WIDTH-1 downto 0);
        zero: out std_logic;
        result: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end alu;

architecture behavioral of alu is


	component abs_value
	generic(DATA_WIDTH: integer := 32);
	port(
        original: in std_logic_vector(DATA_WIDTH-1 downto 0);
		absolute: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
	end component;
	     
   
	signal alu_result,inter: std_logic_vector(DATA_WIDTH-1 downto 0);	
	signal abs_left: std_logic_vector(DATA_WIDTH-1 downto 0);

	
begin


	--SRL will shift zeros in whereas SRA shifts the sign bit in
	
	AB1: abs_value 
		generic map ( DATA_WIDTH => DATA_WIDTH )    
		port map( original=>left_operand, absolute => abs_left);
	
    process(control, left_operand, right_operand)
    begin
        case control is
            when "0000" => --AND
                alu_result <= left_operand and right_operand;
            when "0001" => --OR/ORI
                alu_result <= left_operand or right_operand;
            when "0010" => --ADD/ADDI
                alu_result <= std_logic_vector(signed(left_operand) + signed(right_operand));
            when "0011" => --SUB
                alu_result <= std_logic_vector(signed(left_operand) - signed(right_operand));		
			when "0100" => --XOR/XORI 
                alu_result <= left_operand xor right_operand;	
			when "0101" =>  --SLL/SLLI
                alu_result <= std_logic_vector(shift_left(signed(left_operand),to_integer(unsigned(right_operand)) ));	
			when "0110" => --SRL/SRLI
                alu_result <= std_logic_vector(shift_right(unsigned(left_operand),to_integer(unsigned(right_operand)) ));			
			when "0111" => --SRA/SRAI
                alu_result <= std_logic_vector(shift_right(unsigned(abs_left),to_integer(unsigned(right_operand)) ));
			when "1000" => --SLTU/SLTIU
				alu_result <= ( others => '0');
				if(unsigned(left_operand) < unsigned(right_operand)) then
					alu_result(0) <= '1';	
				else
					alu_result(0) <= '0';
				end if;
			when "1001" => --SLTI/SLT
				alu_result <= ( others => '0');
				if(signed(left_operand) < signed(right_operand)) then
					alu_result(0) <= '1';	
				else
					alu_result(0) <= '0';
				end if;	
			when others =>
				alu_result <= ( others => '0');
        end case;
    end process;

    inter <= std_logic_vector( unsigned(not alu_result) + 1 );
	result_process: process(alu_result,left_operand,control,inter) is
	begin
		if(control = "0111" and left_operand(DATA_WIDTH-1) = '1' ) then
		
			if( to_integer(unsigned(inter)) = 0 ) then
				result <= not inter;
			else
				result <= inter;
			end if;
			
		else 
			result <= alu_result;
		end if;
		
	end process;
	
    zero <= '1' when signed(alu_result) = 0 else '0';

end behavioral;
