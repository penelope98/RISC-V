library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common.all;



-------------------
--more bits for ALU control (more than 3)
--merge entire funct7 and funct3 for the alu control process

-------------------

entity risc_v is    
    generic(
        PROGRAM_ADDRESS_WIDTH: natural := 6;
        DATA_ADDRESS_WIDTH: natural := 6;
        CPU_DATA_WIDTH: natural := 32;
        REGISTER_FILE_ADDRESS_WIDTH: natural := 5
    );
    
    port(
        clk: in std_logic;
        reset_n: in std_logic;
        b_Enter: in std_logic;
        program_read: in std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);
        pc: out std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);
        data_address: out std_logic_vector(DATA_ADDRESS_WIDTH-1 downto 0);
        data_read: in std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        data_write_en: out std_logic;
        data_write: out std_logic_vector(CPU_DATA_WIDTH-1 downto 0) 
    );        
end risc_v;

architecture behavioral of risc_v is

    type forward_control_type is record
        ex_forward_mux_left_operand: std_logic_vector(1 downto 0);
        ex_forward_mux_right_operand: std_logic_vector(1 downto 0);
        id_forward_mux_r1: boolean;
        id_forward_mux_r2: boolean;          
    end record;
    
    type instruction_type is record
        funct7: std_logic_vector(6 downto 0);
        rs2: std_logic_vector(4 downto 0);
        rs1: std_logic_vector(4 downto 0);
        funct3: std_logic_vector(2 downto 0);
        rd: std_logic_vector(4 downto 0);
        opcode: std_logic_vector(6 downto 0);
    end record;    

    type if_id_type is record 
        pc: std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);
        instruction: instruction_type;
    end record;
    
    type id_ex_type is record
        control_alu_op: std_logic_vector(1 downto 0);
        control_alu_src: std_logic;
        control_mem_read: std_logic;
        control_mem_write: std_logic;
        control_reg_write: std_logic;
        control_mem_to_reg: std_logic;
        register_file_data1: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        register_file_data2: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        sign_extended_immediate: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        alu_control: std_logic_vector(3 downto 0); -- FUNCT7(5) & FUNCT3
        register_file_rs1: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
        register_file_rs2: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
        register_file_rd: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
    end record;
    
    type ex_mem_type is record
        control_mem_read: std_logic;
        control_mem_write: std_logic;
        control_reg_write: std_logic;
        control_mem_to_reg: std_logic;    
        alu_result: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        register_store_addr: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        register_file_rd: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
    end record;
    
    type mem_wb_type is record
        control_reg_write: std_logic;
        control_mem_to_reg: std_logic;      
        memory_data: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        alu_result: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
        register_file_rd: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
    end record;
 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++FUNCTIONS++++++++++++++++++++++++++++++++++++++++++++++++++++   
    constant FORWARD_NONE: std_logic_vector(1 downto 0) := "00";
    constant FORWARD_EX_MEM: std_logic_vector(1 downto 0) := "01";
    constant FORWARD_MEM_WB: std_logic_vector(1 downto 0) := "10";
        
    function generate_immediate(instruction: instruction_type) return std_logic_vector is
        type inst_t is (I, S,ISHMT, SB, U);
        variable inst_type: inst_t;
        variable sign_extended_immediate: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
		variable zero_fill : std_logic_vector(CPU_DATA_WIDTH-21 downto 0) := ( others=>'0');
    begin
        if (instruction.opcode(6) = '0' and instruction.opcode(5) = '0') then
			if(instruction.funct3 = "001" or instruction.funct3 = "101") then
				inst_type := ISHMT;
			else
				inst_type := I;
			end if;
		
        elsif (instruction.opcode(6) = '0' and instruction.opcode(5) = '1') then
			if( instruction.opcode(2) = '0' ) then 
				inst_type := S;  
			else
				inst_type := U;  
			end if;
        else
            inst_type := SB; 
        end if;
            
        if (inst_type = I) then
            sign_extended_immediate := 
                std_logic_vector(resize(signed(instruction.funct7 & instruction.rs2), sign_extended_immediate'length));
		elsif (inst_type = ISHMT) then
			sign_extended_immediate := 
                std_logic_vector(resize(unsigned(instruction.rs2), sign_extended_immediate'length));
        elsif (inst_type = S) then
            sign_extended_immediate := 
                std_logic_vector(resize(unsigned(instruction.funct7 & instruction.rd), sign_extended_immediate'length));
		elsif (inst_type = U) then
            sign_extended_immediate := 
                instruction.funct7 & instruction.rs2 & instruction.rs1 & instruction.funct3 & zero_fill;
        else
            sign_extended_immediate := 
                std_logic_vector(resize(unsigned((
                    instruction.funct7(6) & instruction.rd(0) & 
                    instruction.funct7(5 downto 0) & instruction.rd(4 downto 1))), sign_extended_immediate'length
                ));
        end if;   
        
        return sign_extended_immediate; 
    end;
    
    function control_forwarding(
        ex_mem_reg_write: std_logic;
        ex_mem_rd: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0); 
        mem_wb_reg_write: std_logic;
        mem_wb_rd: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
        if_id_rs1: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0); 
        if_id_rs2: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0); 
        id_ex_rs1: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0);
        id_ex_rs2: std_logic_vector(REGISTER_FILE_ADDRESS_WIDTH-1 downto 0)    
    ) return forward_control_type is
        variable ex_mem_writes_back: boolean;
        variable ex_mem_reg_rd_not_x0: boolean;
        variable mem_wb_writes_back: boolean;
        variable mem_wb_reg_rd_not_x0: boolean; 
        variable forward_control: forward_control_type;              
    begin
        forward_control.ex_forward_mux_left_operand := FORWARD_NONE;
        forward_control.ex_forward_mux_right_operand := FORWARD_NONE;
        forward_control.id_forward_mux_r1 := false;
        forward_control.id_forward_mux_r2 := false;
        
        ex_mem_writes_back := (ex_mem_reg_write = '1');
        ex_mem_reg_rd_not_x0 := (ex_mem_rd /= std_logic_vector(to_unsigned(0, ex_mem_rd'length))); 
        mem_wb_writes_back := (mem_wb_reg_write = '1');
        mem_wb_reg_rd_not_x0 := (mem_wb_rd /= std_logic_vector(to_unsigned(0, mem_wb_rd'length)));

        -- forward to id (since register file is sync with clock and wb can't write in time for RF to read the right value)
        if mem_wb_writes_back and mem_wb_reg_rd_not_x0 then
            if mem_wb_rd = if_id_rs1 then
                forward_control.id_forward_mux_r1 := true;
            end if;     
            if mem_wb_rd = if_id_rs2 then
                forward_control.id_forward_mux_r2 := true;
            end if; 
        end if; 
            
        -- forward to ex           
        if ex_mem_writes_back and ex_mem_reg_rd_not_x0 then
            if ex_mem_rd = id_ex_rs1 then
                forward_control.ex_forward_mux_left_operand := FORWARD_EX_MEM;
            end if;
            if ex_mem_rd = id_ex_rs2 then
                forward_control.ex_forward_mux_right_operand := FORWARD_EX_MEM;
            end if;
        elsif mem_wb_writes_back and mem_wb_reg_rd_not_x0 then
            if mem_wb_rd = id_ex_rs1 then
                forward_control.ex_forward_mux_left_operand := FORWARD_MEM_WB;
            end if;
            if mem_wb_rd = id_ex_rs2 then
                forward_control.ex_forward_mux_right_operand := FORWARD_MEM_WB;
            end if;                         
        end if;
        
        return forward_control;
    end;    
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
  
  
  -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>INTERNAL SIGNALS>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    signal pc_reg, pc_next: std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);
    
    signal if_id_reg, if_id_next: if_id_type;
    signal id_ex_reg, id_ex_next: id_ex_type;
    signal ex_mem_reg, ex_mem_next: ex_mem_type;
    signal mem_wb_reg, mem_wb_next: mem_wb_type;
    
    -- ID stage>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    signal id_sign_extended_immediate: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal id_sign_extended_immediate_shifted_1: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal id_branch_address: std_logic_vector(PROGRAM_ADDRESS_WIDTH-1 downto 0);
    signal id_register_file_read1_data: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal id_register_file_read2_data: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal id_r1_equals_r2: std_logic;
    signal id_read1_final_data, id_read1_final_data_signfixed: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal id_read2_final_data, id_read2_final_data_signfixed: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);

    signal id_control_alu_op: std_logic_vector(1 downto 0);
    signal id_control_alu_src: std_logic;
    signal id_control_mem_read: std_logic;
    signal id_control_mem_write: std_logic;
    signal id_control_reg_write: std_logic;
    signal id_control_mem_to_reg: std_logic; 
    signal id_control_is_branch: std_logic;   
    signal id_control_branch_taken: std_logic;
    
    signal id_forward_mux_r1: boolean;
    signal id_forward_mux_r2: boolean;
        
    -- EX stage >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   
    signal ex_alu_zero: std_logic;
    signal ex_alu_result: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);    
    signal ex_alu_left_operand: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal ex_alu_right_operand: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    signal ex_alu_control: std_logic_vector(3 downto 0);
    signal ex_read2_final_data: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    
    signal ex_forward_mux_left_operand: std_logic_vector(1 downto 0);
    signal ex_forward_mux_right_operand: std_logic_vector(1 downto 0);

    -- WB stage>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    signal wb_register_file_write_data: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);

    -- control>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    signal pc_src: std_logic;
    signal forward_controls: forward_control_type;
--COMPRESSED MODE <<<<<<<<<<<<<<COMPRESSED MODE<<<<<<<<<<<<<<<<<<COMPRESSED MODE <<<<<<<<<<<<<<COMPRESSED MODE<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<COMPRESSED MODE <<<<<<<<<<<<<<COMPRESSED MODE<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	
	signal pc_cmp: std_logic;
	signal expanded_instruction: std_logic_vector(31 downto 0);
	
--COMPRESSED MODE end<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	
	--additional>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
	signal comparator_great,comparator_less,comparator_equal,comparator_great_s,comparator_less_s,comparator_equal_s: std_logic;
	
	signal flush_instruction: std_logic;
	signal input_instruction: instruction_type;
	
	 --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~COMPONENTS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	component comparator 
    generic(DATA_WIDTH: integer := 32);
    port(
        left_operand: in std_logic_vector(DATA_WIDTH-1 downto 0);
        right_operand: in std_logic_vector(DATA_WIDTH-1 downto 0);
        equal32: out std_logic; 
		great32: out std_logic; 
		less32: out std_logic
    );
	end component;
          
	component abs_value
	generic(DATA_WIDTH: integer := 32);
	port(
        original: in std_logic_vector(DATA_WIDTH-1 downto 0);
		absolute: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
	end component;
	     
	   
begin --&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

    registers: process (clk) is
    begin
        if rising_edge(clk) then
            if reset_n = '1' then
                pc_reg <= (others => '0');
                if_id_reg <= (instruction => (others => (others => '0')), others => (others => '0'));               
                id_ex_reg <= ("00", '0', '0', '0', '0', '0', others => (others => '0'));
                ex_mem_reg <= ('0', '0', '0', '0',others => (others => '0'));
                mem_wb_reg <= ('0', '0', others => (others => '0'));
            else
                pc_reg <= pc_next;
                if_id_reg <= if_id_next;
                id_ex_reg <= id_ex_next;
                ex_mem_reg <= ex_mem_next;
                mem_wb_reg <= mem_wb_next;
            end if;
        end if;
    end process registers;
 --~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~UNITS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    reg_file: entity work.register_file 
        generic map (
            DATA_WIDTH => CPU_DATA_WIDTH,
            ADDRESS_WIDTH => REGISTER_FILE_ADDRESS_WIDTH
        )
        port map (
            clk => clk,
            reset_n => reset_n,
            b_Enter => b_Enter,
            write_en => mem_wb_reg.control_reg_write,
            read1_id => if_id_reg.instruction.rs1,
            read2_id => if_id_reg.instruction.rs2,
            write_id => mem_wb_reg.register_file_rd,
            write_data => wb_register_file_write_data,
            read1_data => id_register_file_read1_data,
            read2_data => id_register_file_read2_data
        );
    
    alu_unit: entity work.alu 
        port map (
            control => ex_alu_control,
            left_operand => ex_alu_left_operand,
            right_operand => ex_alu_right_operand,
            zero => ex_alu_zero,
            result => ex_alu_result
        );
	
	
	abs_unit_1: abs_value 
		generic map ( DATA_WIDTH => CPU_DATA_WIDTH )    
		port map( original=>id_read1_final_data, absolute => id_read1_final_data_signfixed);
	abs_unit_2: abs_value 
		generic map ( DATA_WIDTH => CPU_DATA_WIDTH )    
		port map( original=>id_read2_final_data, absolute => id_read2_final_data_signfixed);
	
	comparator_unit_unsigned: comparator 
		generic map (
            DATA_WIDTH => CPU_DATA_WIDTH
        )
		port map(
        left_operand => id_read1_final_data,
        right_operand => id_read2_final_data,
        equal32 => comparator_equal,
		great32 => comparator_great,
		less32 => comparator_less
		);

	comparator_unit_signed: comparator 
		generic map (
            DATA_WIDTH => CPU_DATA_WIDTH
        )    
		port map(
        left_operand => id_read1_final_data_signfixed,
        right_operand => id_read2_final_data_signfixed,
        equal32 => comparator_equal_s,
		great32 => comparator_great_s,
		less32 => comparator_less_s
		);


	--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~	

--############################################################################################################PROCESSES####################################################3
    next_pc_logic: process (pc_reg, id_branch_address, pc_src,pc_cmp) is
    begin
        if pc_src = '0' and pc_cmp = '0' then
            pc_next <= std_logic_vector(unsigned(pc_reg) + 4);
        elsif pc_src = '0' and pc_cmp = '1' then
			pc_next <= std_logic_vector(unsigned(pc_reg) + 2);
		else
            pc_next <= id_branch_address;
        end if;
    end process next_pc_logic;
	
--COMPRESSED MODE <<<<<<<<<<<<<<COMPRESSED MODE<<<<<<<<<<<<<<<<<<COMPRESSED MODE <<<<<<<<<<<<<<COMPRESSED MODE<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<COMPRESSED MODE <<<<<<<<<<<<<<COMPRESSED MODE<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<	
    --------------------------------------
	compressed_detect: process(program_read) is
	begin
	
		if program_read(1 downto 0) = "11" then
			pc_cmp <= '0';
		else
			pc_cmp <= '1';
		end if;
	
	end process;
	--------------------------------------
	if_cmp_logic: process (program_read, pc_cmp)
	begin
    expanded_instruction <= (others => '0');
    
		if program_read (1 downto 0) = "00" then
			if program_read(15 downto 13) = "010" then --C.LW
				expanded_instruction <= "00000" & program_read(5) & program_read(12 downto 10) & program_read(6) & "0000" & program_read(9 downto 7) & program_read(15 downto 13) & "00" & program_read(4 downto 2) & "0000011";
			elsif program_read(15 downto 13) = "110" then --C.SW
				expanded_instruction <= "00000" & program_read(5) & program_read(12) & "00" & program_read(4 downto 2) & "00" & program_read(9 downto 7) & program_read(15 downto 13) & program_read(11 downto 10) & program_read(6) & "00" & "0100011";
			end if;
		elsif program_read (1 downto 0) = "10" then
			if program_read(15 downto 13) = "000" then --C.SLLI
				expanded_instruction <= "000000" & program_read(12) & program_read(6 downto 2) & program_read(11 downto 7) & "001" & program_read(11 downto 7) & "0010011";
			elsif program_read(15 downto 12) = "1000" then --C.mv
				expanded_instruction <= "0000000" & "00000000" & program_read(6 downto 2) & program_read(11 downto 7)   &"0110011";
			elsif program_read(15 downto 12) = "1001" then --c.add
				expanded_instruction <= "0000000" & program_read(6 downto 2) & program_read(11 downto 7) & "000" & program_read(11 downto 7) &  "0110011";
			end if;
		elsif program_read (1 downto 0) = "01" then
			if program_read(15 downto 13) = "000" then --C.ADDI
				expanded_instruction <=  program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)& program_read(12) & program_read(6 downto 2) & program_read(11 downto 7) & "000" & program_read(11 downto 7) & "0010011"; 
			elsif program_read(15 downto 13) = "010" then --C.LI
				expanded_instruction <= program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)& program_read(12) & program_read(6 downto 2)& "00000000"& program_read(11 downto 7) & "0010011"; 
			elsif program_read(15 downto 13) = "011" then --C.LUI
				expanded_instruction <= program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)& program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)& program_read(12) & program_read(12) &program_read(12) & program_read(6 downto 2) & program_read(11 downto 7) &"0110111";
			elsif program_read(15 downto 13) = "100" then 
				if program_read(11 downto 10) = "00" then --C.SRLI
					expanded_instruction <= "000000" & program_read(12)& program_read(6 downto 2) & program_read(11 downto 7) & "101" & program_read(11 downto 7) &"0010011";
 				elsif program_read(11 downto 10) = "01" then --C.SRAI
					expanded_instruction <= "010000" & program_read(12) & program_read(6 downto 2) & "01" & program_read(9 downto 7) & "101"& "01" & program_read(9 downto 7) &"0010011";
				elsif program_read(11 downto 10) = "10" then --C.ANDI
					expanded_instruction <= program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)&program_read(12)& program_read(12) & program_read(6 downto 2) & "01" & program_read(9 downto 7) & "111"& "01" & program_read(9 downto 7) & "0010011"; 
				else 
				 	if program_read(6 downto 5) = "00" then --C.SUB
						expanded_instruction <= "0100000" & "01" & program_read(4 downto 2) & "01" & program_read(9 downto 7) & "000"& "01" & program_read(9 downto 7) & "0110011";
					elsif program_read(6 downto 5) = "01" then --C.XOR
						expanded_instruction <= "0000000" & "01" & program_read(4 downto 2) & "01" & program_read(9 downto 7) & "111"& "01" & program_read(9 downto 7) & "0110011"; 
					elsif program_read(6 downto 5) = "10" then --C.OR
						expanded_instruction <= "0000000" & "01" & program_read(4 downto 2) & "01" & program_read(9 downto 7) & "110"& "01" & program_read(9 downto 7) & "0110011"; 
					else --C.AND
						expanded_instruction <= "0000000" & "01" & program_read(4 downto 2) & "01" & program_read(9 downto 7) & "111"& "01" & program_read(9 downto 7) & "0110011"; 
					end if;
				end if;
			end if;
		end if;

	end process;
--COMPRESSED MODE end<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<COMPRESSED MODE end<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

	--------------------------------------
    id_sign_extended_immediate <= generate_immediate(if_id_reg.instruction);	
   --------------------------------------- 
    control_unit: process (if_id_reg.instruction.opcode) is
        constant R_FORMAT: std_logic_vector(6 downto 0) := "0110011";
        constant I_FORMAT: std_logic_vector(6 downto 0) := "0010011";
		constant U_FORMAT: std_logic_vector(6 downto 0) := "0110111";
        constant LOAD: std_logic_vector(6 downto 0) := "0000011";
        constant STORE: std_logic_vector(6 downto 0) := "0100011";
        constant BRANCH: std_logic_vector(6 downto 0) := "1100011";
	

    begin
        id_control_alu_op <= "00";
        id_control_alu_src <= '0'; --for determining right operand source
        id_control_mem_read <= '0';
        id_control_mem_write <= '0';
        id_control_reg_write <= '0';
        id_control_mem_to_reg <= '0';
        id_control_is_branch <= '0';
        
        if if_id_reg.instruction.opcode = R_FORMAT then
            id_control_alu_op <= "10";
            id_control_reg_write <= '1';
        elsif if_id_reg.instruction.opcode = I_FORMAT then
            id_control_alu_op <= "11";
            id_control_reg_write <= '1';
            id_control_alu_src <= '1';
		elsif if_id_reg.instruction.opcode = U_FORMAT then
			id_control_alu_op <= "01";
            id_control_reg_write <= '1';
            id_control_alu_src <= '1';
        elsif if_id_reg.instruction.opcode = LOAD then
            id_control_alu_src <= '1';
            id_control_mem_read <= '1';
            id_control_reg_write <= '1';
            id_control_mem_to_reg <= '1';
        elsif if_id_reg.instruction.opcode = STORE then
            id_control_alu_src <= '1';
            id_control_mem_write <= '1';
        elsif if_id_reg.instruction.opcode = BRANCH then
            id_control_alu_op <= "01"; 
            id_control_is_branch <= '1';          
        end if;
    end process control_unit;   

    alu_control_process: process (id_ex_reg.alu_control, id_ex_reg.control_alu_op) is
        constant ALU_AND: std_logic_vector(3 downto 0) := "0000"; --and and andi
        constant ALU_OR: std_logic_vector(3 downto 0) := "0001"; --or and ori
        constant ALU_ADD: std_logic_vector(3 downto 0) := "0010"; --add and addi
        constant ALU_SUB: std_logic_vector(3 downto 0) := "0011"; --sub 
		
		constant ALU_XOR: std_logic_vector(3 downto 0) := "0100"; --xor and xori
		constant ALU_SLL: std_logic_vector(3 downto 0) := "0101"; --sll and slli
		constant ALU_SRL: std_logic_vector(3 downto 0) := "0110"; -- srl srli
		
		constant ALU_SRA: std_logic_vector(3 downto 0) := "0111"; -- sra and srai
		constant ALU_SLTU: std_logic_vector(3 downto 0) := "1000"; -- sltu and sltiu
		constant ALU_SLT: std_logic_vector(3 downto 0) := "1001"; -- slti and slt
		
		constant ALU_LUI: std_logic_vector(3 downto 0) := "1010"; -- lui	
    begin 
	
		if id_ex_reg.control_alu_op = "10" then 	
			if(id_ex_reg.alu_control = "0000") then 
				ex_alu_control <= ALU_ADD;
			elsif(id_ex_reg.alu_control = "1000") then
				ex_alu_control <= ALU_SUB;
			elsif(id_ex_reg.alu_control(2 downto 0) = "001") then
				ex_alu_control <= ALU_SLL;
			elsif(id_ex_reg.alu_control(2 downto 0) = "010") then
				ex_alu_control <=ALU_SLT;
			elsif(id_ex_reg.alu_control(2 downto 0) = "011") then
				ex_alu_control <= ALU_SLTU;
			elsif(id_ex_reg.alu_control(2 downto 0) = "100") then
				ex_alu_control <= ALU_XOR;
			elsif(id_ex_reg.alu_control = "0101") then
				ex_alu_control <= ALU_SRL;
			elsif(id_ex_reg.alu_control = "1101") then
				ex_alu_control <= ALU_SRA;
			elsif(id_ex_reg.alu_control(2 downto 0) = "110") then
				ex_alu_control <= ALU_OR;
			elsif(id_ex_reg.alu_control(2 downto 0) = "111") then
				ex_alu_control <= ALU_AND;
			else
				ex_alu_control <= ALU_AND;			
			end if;
		
		
		elsif id_ex_reg.control_alu_op = "11" then 	
			if(id_ex_reg.alu_control(2 downto 0) = "000") then 
				ex_alu_control <= ALU_ADD;
			elsif(id_ex_reg.alu_control(2 downto 0) = "001") then
				ex_alu_control <= ALU_SLL;
			elsif(id_ex_reg.alu_control(2 downto 0) = "010") then
				ex_alu_control <= ALU_SLT;
			elsif(id_ex_reg.alu_control(2 downto 0) = "011") then
				ex_alu_control <= ALU_SLTU;
			elsif(id_ex_reg.alu_control(2 downto 0) = "100") then
				ex_alu_control <= ALU_XOR;
			elsif(id_ex_reg.alu_control = "0101") then
				ex_alu_control <= ALU_SRL;
			elsif(id_ex_reg.alu_control = "1101") then
				ex_alu_control <= ALU_SRA;
			elsif(id_ex_reg.alu_control(2 downto 0) = "110") then
				ex_alu_control <= ALU_OR;
			elsif(id_ex_reg.alu_control(2 downto 0) = "111") then
				ex_alu_control <= ALU_AND;
			else
				ex_alu_control <= ALU_AND;			
			end if;	
			
		elsif id_ex_reg.control_alu_op = "01" then 	
				ex_alu_control <= ALU_LUI;	
		else
			 ex_alu_control <= ALU_LUI; 
		end if;
	
    end process alu_control_process;
 ----------------------------------------------------------------------------------- forwarding function }}}}}}}}}}}}}}}}}}
    forward_controls <= control_forwarding(
        ex_mem_reg_write => ex_mem_reg.control_reg_write,
        ex_mem_rd => ex_mem_reg.register_file_rd,
        mem_wb_reg_write => mem_wb_reg.control_reg_write,
        mem_wb_rd => mem_wb_reg.register_file_rd,
        if_id_rs1 => if_id_reg.instruction.rs1,
        if_id_rs2 => if_id_reg.instruction.rs2,
        id_ex_rs1 => id_ex_reg.register_file_rs1,
        id_ex_rs2 => id_ex_reg.register_file_rs2
    ); -------------------------------------------------------------------------------------------------- }}}}}}}}}}}}}}}}}}}}}}}
    ex_forward_mux_left_operand <= forward_controls.ex_forward_mux_left_operand;
    ex_forward_mux_right_operand <= forward_controls.ex_forward_mux_right_operand;
    id_forward_mux_r1 <= forward_controls.id_forward_mux_r1; --flag 1
    id_forward_mux_r2 <= forward_controls.id_forward_mux_r2; --flag 2

------------------------------------------------------------------------------------------[FW MUX1 LEFT]

    alu_and_forwarding_left_mux: process (
        ex_forward_mux_left_operand, id_ex_reg.register_file_data1, 
        ex_mem_reg.alu_result, wb_register_file_write_data) 
    begin
        ex_alu_left_operand <= (others => '0');
        
        if ex_forward_mux_left_operand = FORWARD_NONE then
            ex_alu_left_operand <= id_ex_reg.register_file_data1; --ALU gets data from id_ex_reg (previous stage)
        elsif ex_forward_mux_left_operand = FORWARD_EX_MEM then
            ex_alu_left_operand <= ex_mem_reg.alu_result; --ALU gets data from ex_mem reg (prev ALU result)
        elsif ex_forward_mux_left_operand = FORWARD_MEM_WB then
            ex_alu_left_operand <= wb_register_file_write_data;  --ALU gets data from forwarded value (LOAD)    
        end if;  
    end process alu_and_forwarding_left_mux;
------------------------------------------------------------------------------------------[FW MUX2 RIGHT]
    alu_and_forwarding_right_mux: process (
        ex_forward_mux_right_operand, id_ex_reg.control_alu_src, id_ex_reg.register_file_data2, 
        ex_mem_reg.alu_result, id_ex_reg.sign_extended_immediate, wb_register_file_write_data
    ) 
        variable mux_1: std_logic_vector(CPU_DATA_WIDTH-1 downto 0);
    begin
        ex_alu_right_operand <= (others => '0');
        mux_1 := (others => '0');
        
        if ex_forward_mux_right_operand = FORWARD_NONE then --ALU gets data from id_ex_reg (previous stage)
            mux_1 := id_ex_reg.register_file_data2;
        elsif ex_forward_mux_right_operand = FORWARD_EX_MEM then --ALU gets data from ex_mem reg (prev ALU result)
            mux_1 := ex_mem_reg.alu_result;
        elsif ex_forward_mux_right_operand = FORWARD_MEM_WB then --ALU gets data from forwarded value (LOAD)   
            mux_1 := wb_register_file_write_data;            
        end if; 
        
        if id_ex_reg.control_alu_src = '0' then --not load, store or addi       
            ex_alu_right_operand <= mux_1;
        else 
            ex_alu_right_operand <= id_ex_reg.sign_extended_immediate; --sign extended address or immediate (addi/immediate covered here)
        end if;
        
        ex_read2_final_data <= mux_1; --(for store and load)
    end process alu_and_forwarding_right_mux;
    
    id_read1_final_data <= wb_register_file_write_data when id_forward_mux_r1 else id_register_file_read1_data; --get data from input to reg file (forward from load) or read from reg file
    id_read2_final_data <= wb_register_file_write_data when id_forward_mux_r2 else id_register_file_read2_data;
	
	----------------------Branching process
	branching_decision: process (id_sign_extended_immediate,if_id_reg.pc,id_control_is_branch,comparator_equal,comparator_less,comparator_great,comparator_less_s,comparator_great_s,id_sign_extended_immediate_shifted_1)
	
	    constant BEQ: std_logic_vector(2 downto 0) := "000"; 
        constant BNE: std_logic_vector(2 downto 0) := "001";
        constant BLT: std_logic_vector(2 downto 0) := "100"; 
        constant BGE: std_logic_vector(2 downto 0) := "101"; 
		constant BLTU: std_logic_vector(2 downto 0) := "110"; 
		constant BGEU: std_logic_vector(2 downto 0) := "111"; 
		
	begin
	
	id_control_branch_taken <= '0'; --DIP
	id_sign_extended_immediate_shifted_1 <= id_sign_extended_immediate(CPU_DATA_WIDTH-2 downto 0) & '0'; -----------------
	id_branch_address <= std_logic_vector(signed(if_id_reg.pc) + signed(id_sign_extended_immediate_shifted_1(PROGRAM_ADDRESS_WIDTH-1 downto 0))); ----------------
	
	if if_id_reg.instruction.funct3 = BEQ then
		id_control_branch_taken <= comparator_equal; 
	elsif if_id_reg.instruction.funct3 = BNE then --bne
		id_control_branch_taken <= not comparator_equal; 
	elsif if_id_reg.instruction.funct3 = BLT then --blt
		id_control_branch_taken <= comparator_less_s;
	elsif if_id_reg.instruction.funct3 = BGE then --bge
		id_control_branch_taken <= comparator_great_s;
	elsif if_id_reg.instruction.funct3 = BLTU then --bltu
		id_control_branch_taken <= comparator_less;
	elsif if_id_reg.instruction.funct3 = BGEU then --bgeu
		id_control_branch_taken <= comparator_great; 
	end if;
				
	end process;
	
	pc_src <= id_control_branch_taken and id_control_is_branch; ---------------BRANCH	
	
	--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~flushing logic~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	flush_instruction <= pc_src;

	flush_instruction_process: process(program_read,flush_instruction,expanded_instruction,pc_cmp) is
	begin
	
		if( flush_instruction = '1') then
			input_instruction <= (others => (others => '0'));

		elsif( pc_cmp= '1') then
			input_instruction <= (
				expanded_instruction(31 downto 25), expanded_instruction(24 downto 20), expanded_instruction(19 downto 15), 
				expanded_instruction(14 downto 12), expanded_instruction(11 downto 7), expanded_instruction(6 downto 0)
			);

		else
			input_instruction <= (
				program_read(31 downto 25), program_read(24 downto 20), program_read(19 downto 15), 
				program_read(14 downto 12), program_read(11 downto 7), program_read(6 downto 0)
			);
		end if;
	end process;	
	--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	
	
    ---------------------------------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    -- Pipeline registers next state logic
    if_id_next <= (
        pc => pc_reg, 
		instruction => input_instruction
        --instruction => (
          --  program_read(31 downto 25), program_read(24 downto 20), program_read(19 downto 15), 
           -- program_read(14 downto 12), program_read(11 downto 7), program_read(6 downto 0)
        --)
    );

    id_ex_next <= (
        control_alu_op => id_control_alu_op,
        control_alu_src => id_control_alu_src,
        control_mem_read => id_control_mem_read,
        control_mem_write => id_control_mem_write,
        control_reg_write => id_control_reg_write,
        control_mem_to_reg => id_control_mem_to_reg,
        register_file_data1 => id_read1_final_data, 
        register_file_data2 => id_read2_final_data, 
        sign_extended_immediate => id_sign_extended_immediate, 
        alu_control => if_id_reg.instruction.funct7(5) & if_id_reg.instruction.funct3, -- FUNCT7(5) & FUNCT3
        register_file_rs1 => if_id_reg.instruction.rs1,
        register_file_rs2 => if_id_reg.instruction.rs2,
        register_file_rd => if_id_reg.instruction.rd
    );
 
    ex_mem_next <= (
        control_mem_read => id_ex_reg.control_mem_read, 
        control_mem_write => id_ex_reg.control_mem_write, 
        control_reg_write => id_ex_reg.control_reg_write, 
        control_mem_to_reg => id_ex_reg.control_mem_to_reg,
        alu_result => ex_alu_result, 
        register_store_addr => ex_read2_final_data, --
        register_file_rd => id_ex_reg.register_file_rd
    );
        
    mem_wb_next <= (
        control_reg_write => ex_mem_reg.control_reg_write,
        control_mem_to_reg => ex_mem_reg.control_mem_to_reg,
        memory_data => data_read, 
        alu_result => ex_mem_reg.alu_result,
        register_file_rd => ex_mem_reg.register_file_rd
    );
  ---------------------------------------------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
   
    pc <= pc_reg;
	--input to reg file
    wb_register_file_write_data <= mem_wb_reg.alu_result when mem_wb_reg.control_mem_to_reg = '0' else mem_wb_reg.memory_data; -- INPUT TO REGFILE. LOAD or REG STORE (alu operation)
    --input to data memory
    data_address <= ex_mem_reg.alu_result(DATA_ADDRESS_WIDTH-1 downto 0); --input address to data mem    
    data_write <= ex_mem_reg.register_store_addr;  --STORE --input data to data mem    
    data_write_en <= ex_mem_reg.control_mem_write;  
    
end behavioral;
