library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;


entity system_serial is
    generic (
        PROGRAM_ADDRESS_WIDTH: natural := 10;
        DATA_ADDRESS_WIDTH: natural := 6;
        CPU_DATA_WIDTH: natural := 32;
		CHARACTER_SIZE: natural := 8
    );
    
    port (
        clk: in std_logic;
        reset_n: in std_logic;
		input_data: in std_logic
    );
end system_serial;


architecture structural of system_serial is
    
    signal program_address: std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0); --ingoing to program ram
    signal program_data: std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);
    
    signal data_write_en: std_logic;
    signal data_address: std_logic_vector(DATA_ADDRESS_WIDTH-1 downto 0);
    signal data_read: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal data_write: std_logic_vector(CPU_DATA_WIDTH-1 downto 0); 
	

	--==--==--==--==--==--==--==--==--==-signals for uart-==--==--==--==--==--==--==--==--==--==--==--

	signal program_counter: std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0); --outgoing from risc v
	
	type state_type is (fill_ram,calculate);
	signal system_state, system_state_next: state_type;
	
	
	signal instr_fill_count,instr_fill_count_next: unsigned(PROGRAM_ADDRESS_WIDTH-1 downto 0); --counter for instructions
	signal instruction_assembled_reg,instruction_assembled_next: unsigned(DATA_ADDRESS_WIDTH-1 downto 0); --counter for instruction get
	signal new_instr,new_instr_reg,new_instr_next: std_logic_vector(CPU_DATA_WIDTH-1 downto 0); --instruction reg and wire
	signal char_get,instr_get: std_logic; --flags for character get and instruction get
	
	signal new_char: std_logic_vector(CHARACTER_SIZE-1 downto 0); --new char from uart
	
	signal ram_write_enable: std_logic;
	signal eot: std_logic; --signals the end of instruction read from uart

	--==--==--==--==--==--==--==--==--==--==-signals for uart-==--==--==--==--==--==--==--==--==--==--

begin

	uart_unit: entity work.uart
		generic map(
        CHARACTER_SIZE => CHARACTER_SIZE
		)
		port map(
			clk=>clk,
			reset=>reset_n,
			rx=>input_data,
			char_out=>new_char,
			char_flag=>char_get,
			end_of_transmission=>eot
		);

    cpu: entity work.risc_v 
        generic map (
            PROGRAM_ADDRESS_WIDTH => PROGRAM_ADDRESS_WIDTH,
            DATA_ADDRESS_WIDTH => DATA_ADDRESS_WIDTH,
            CPU_DATA_WIDTH => CPU_DATA_WIDTH,
            REGISTER_FILE_ADDRESS_WIDTH => 5
        )
        port map (
            clk => clk,
            reset_n => reset_n,
            program_read => program_data,
            pc => program_counter,
            data_address => data_address,
            data_read => data_read,
            data_write_en => data_write_en,
            data_write => data_write
        );
     
    prog_mem: entity work.program_ram 
        generic map (
                ADDRESS_WIDTH => PROGRAM_ADDRESS_WIDTH,
                DATA_WIDTH => INSTRUCTION_WIDTH
            )    
        port map (
            clk => clk,
            write_en => ram_write_enable,
            write_data => new_instr,
            address => program_address,
            read_data => program_data
        ); 

    data_mem: entity work.data_memory 
        generic map (
            ADDRESS_WIDTH => DATA_ADDRESS_WIDTH,
            DATA_WIDTH => CPU_DATA_WIDTH
        )
        port map (
            clk => clk,
            write_en => data_write_en,
            write_data => data_write,
            address => data_address,
            read_data => data_read
        );
    
	--------------------------INSTR READ PROCESS ---------------------------------------INSTR READ PROCESS ------------------------------------INSTR READ PROCESS -------------------------
	
	REG: process(clk,reset_n) is
	begin
		if( reset_n = '1' ) then
			system_state <= fill_ram;
            instr_fill_count <= (others => '0');
			new_instr_reg <= (others => '0');
			instruction_assembled_reg <= (others => '0');
		else
			system_state <= system_state_next;
            instr_fill_count <= instr_fill_count_next;
			new_instr_reg <= new_instr_next;
			instruction_assembled_reg <= instruction_assembled_next;
		end if;	

	end process;
	
	
	character_decode: process( new_char, char_get) is
	begin
		if( new_char = "00110000" and char_get = '1' ) then 
			new_instr_next <= '0' & new_instr_reg(CPU_DATA_WIDTH-1 downto 1);
		elsif ( new_char = "00110001" and char_get = '1') then
			new_instr_next <= '1' & new_instr_reg(CPU_DATA_WIDTH-1 downto 1);
		else
			new_instr_next <= new_instr_reg;
		end if;
	end process;


	new_instr <= new_instr_reg;


	get_instruction: process ( char_get, instruction_assembled_reg ) is --counter for instruction assembling
	begin
		if (char_get = '1') then
			if(instruction_assembled_reg = CPU_DATA_WIDTH) then
				instr_get <= '1';
				instruction_assembled_next <= (others => '0' );
			else
				instruction_assembled_next <= instruction_assembled_reg + 1;
				instr_get <= '0';
			end if;
		else
			instruction_assembled_next <= instruction_assembled_reg;
			instr_get <= '0';
		end if;
	
	end process;
	
	
--------------------------INSTR READ PROCESS end---------------------------------------INSTR READ PROCESS end------------------------------------INSTR READ PROCESS end-------------------------
	
	SYSTEM_FSM: process(instr_get,system_state,eot)is
	begin


		ram_write_enable <='0';
		program_address <= program_counter;
		instr_fill_count_next <= instr_fill_count;
		
		case system_state is			
			when fill_ram =>	
				program_address <= std_logic_vector(instr_fill_count);
				if(instr_get = '1') then
					instr_fill_count_next <= instr_fill_count + 4;	--increment instr counter and enable writing to program ram 
					ram_write_enable <= '1';
				end if;			
				if(eot = '1') then
					system_state_next <= calculate; --end of transmission from uart
				end if;						
			when calculate => 
				program_address <= program_counter;
				instr_fill_count_next <= instr_fill_count;				
			when others =>

				
		end case;
		
	end process;
	
	
    -- Just added to force the tools not to optimize away the logic
   -- process (clk)
        --variable red: std_logic := '0';
  -- begin
      --  if rising_edge(clk) then
        --    if reset_n = '0' then
          --      red := '0';
          --  else
             --   for i in data_write'range loop
              --      red := red or data_write(i);
               -- end loop;
           -- end if;            
           -- redundant <= red;
       -- end if;
   -- end process;
    
end structural;