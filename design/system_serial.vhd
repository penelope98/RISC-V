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
        b_Enter: in std_logic;
		input_data: in std_logic;
		output_led: out std_logic
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
	signal system_bin: std_logic; --debug state conversion
	
	
	signal instr_fill_count,instr_fill_count_next: unsigned(PROGRAM_ADDRESS_WIDTH-1 downto 0); --counter for instructions
	signal instruction_assembled_reg,instruction_assembled_next: unsigned(DATA_ADDRESS_WIDTH-1 downto 0); --counter for instruction get
	signal new_instr,new_instr_reg,new_instr_next: std_logic_vector(CPU_DATA_WIDTH-1 downto 0); --instruction reg and wire
	signal char_get,instr_get: std_logic; --flags for character get and instruction get
	
	signal new_char: std_logic_vector(CHARACTER_SIZE-1 downto 0); --new char from uart
	
	signal ram_write_enable: std_logic;
	signal eot,risc_reset,force_flag: std_logic; --signals the end of instruction read from uart
	signal force_reset: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
	--buffers for ram
	signal i_get_current,i_get_next: std_logic;
	signal write_address_current,write_address_next: std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);

	--==--==--==--==--==--==--==--==--==--==-BEDUGGING-==--==--==--==--==--==--==--==--==--==--

--    component ila_regs port(
--        clk: in std_logic;
--        probe0: in std_logic_vector(31 downto 0);
--        probe1: in std_logic_vector(0 downto 0);
--        probe2: in std_logic_vector(4 downto 0 );
--        probe3: in std_logic_vector(5 downto 0 ));
--    end component;


--     component ila_char port(
--            clk: in std_logic;
--            probe0: in std_logic_vector(0 downto 0);
--            probe1: in std_logic_vector(7 downto 0);
--            probe2: in std_logic_vector(2 downto 0);
--            probe3: in std_logic_vector(0 downto 0) );
--     end component;

--     component ila_serial_state port(
--            clk: in std_logic;
--            probe0: in std_logic_vector(0 downto 0);
--            probe1: in std_logic_vector(0 downto 0);
--            probe2: in std_logic_vector(9 downto 0));
--     end component;


	--==--==--==--==--==--==--==--==--==--==-==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--
begin

	uart_unit: entity work.uart_inner
		generic map(
        CHARACTER_SIZE => CHARACTER_SIZE
		)
		port map(
			clk=>clk,
			reset=>reset_n,
			rx=>input_data,
			char_out=>new_char,
			char_flag=>char_get
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
            reset_n => risc_reset,
            b_Enter => b_Enter,
            program_read => program_data,
            pc => program_counter,
            data_address => data_address,
            data_read => data_read,
            data_write_en => data_write_en,
            data_write => data_write,
			instruction_count_final => std_logic_vector(instr_fill_count)
        );
     
    prog_mem: entity work.program_ram 
        generic map (
                PROGRAM_ADDRESS_WIDTH => PROGRAM_ADDRESS_WIDTH,
                DATA_WIDTH => INSTRUCTION_WIDTH
            )    
        port map (
            clk => clk,
			reset => reset_n,
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
			reset => reset_n,
            write_en => data_write_en,
            write_data => data_write,
            address => data_address,
            read_data => data_read
        );
    
	--------------------------INSTR READ PROCESS ---------------------------------------INSTR READ PROCESS ------------------------------------INSTR READ PROCESS -------------------------
	
	--CALCULATE-- when instruction is FFFF_FFFF
	risc_reset <= (not reset_n) or force_flag;
	force_reset(0) <= new_instr(0);
	
	
	FORCE_RESET_BITAND : for I in 1 to CPU_DATA_WIDTH-1 generate
	force_reset(I)<= force_reset(I-1) and new_instr(I);
	end generate;

	
	REG: process(clk) is
	begin		
		if rising_edge(clk) then 
			if( reset_n = '0' ) then
				system_state <= fill_ram;
				instr_fill_count <= (others => '0');
				new_instr_reg <= (others => '0');
				instruction_assembled_reg <= (others => '0');
				i_get_current <= '0';
				write_address_current <= (others => '0');
			else 
				system_state <= system_state_next;
				instr_fill_count <= instr_fill_count_next;
				new_instr_reg <= new_instr_next;
				instruction_assembled_reg <= instruction_assembled_next;
				i_get_current <= i_get_next;
				write_address_current <= write_address_next;
			end if;
		end if;	

	end process;
		
	character_decode: process( new_char, char_get, new_instr_reg) is
	begin
	   if( char_get='1') then
	       new_instr_next <= new_instr_reg(CPU_DATA_WIDTH-2 downto 0) & new_char(0);
	   else
            new_instr_next <= new_instr_reg;
	   end if; 
	end process;
	
	new_instr <= new_instr_reg;
	
	get_instruction: process ( char_get, instruction_assembled_reg ) is --counter for instruction assembling
	begin
		if (char_get = '1') then
			if(instruction_assembled_reg = CPU_DATA_WIDTH-1) then
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
	
	SYSTEM_FSM: process(instr_get,system_state,force_reset,program_counter,instr_fill_count,i_get_current,write_address_current)is
	begin

		program_address <= program_counter;
		instr_fill_count_next <= instr_fill_count;
		system_state_next <= system_state;
		ram_write_enable <= '0';
		force_flag <= '0';
		
		case system_state is			
			when fill_ram =>	
				--program_address <= std_logic_vector(instr_fill_count);
				--ram_write_enable <= instr_get;
				ram_write_enable <= i_get_current;
				program_address <= write_address_current;
				
				if(instr_get = '1') then
					instr_fill_count_next <= instr_fill_count + 4;	--increment instr counter and enable writing to program ram 				
				end if;			
				if( force_reset(CPU_DATA_WIDTH-1) = '1') then
					force_flag <= '1';
					system_state_next <= calculate; --end of transmission from uart
				end if;						
			when calculate => 
				program_address <= program_counter;
				instr_fill_count_next <= instr_fill_count;				
			when others =>

				
		end case;
		
	end process;
	
	write_address_next <= std_logic_vector(instr_fill_count);
	i_get_next<=instr_get;
	output_led <= eot;
	
-----------------------------------DEBUG--------------------------------------------------------------------------------------------
	process(system_state) is
	begin
	   case(system_state) is
            when fill_ram =>
                system_bin<='1';
            when calculate => 
				system_bin<='0';
            when others =>

	   end case;	
	end process;
	
	
--	ILA_SERIAL: ila_regs port map( 
--    clk => clk,
--    probe0 => new_instr,
--    probe1(0) => instr_get,
--    probe2 => std_logic_vector(instr_fill_count(4 downto 0)),
--    probe3 => std_logic_vector(instruction_assembled_reg)
--     );
       
--    ILA_UART_SERIAL: ila_char port map(
--    clk => clk,
--    probe0(0) => char_get,
--    probe1 => new_char,
--    probe2 => (others => '0'),
--    probe3(0) => input_data
--    );	
    
--    ILA_STATE_SERIAL: ila_serial_state port map(
--    clk => clk,
--    probe0(0) => system_bin,
--    probe1(0) => force_reset(CPU_DATA_WIDTH-1),
--    probe2 => std_logic_vector(instr_fill_count)
--    );	
        
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