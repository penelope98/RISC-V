library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart is
generic (
        CHARACTER_SIZE: natural := 8
    );
port(
    clk: in std_logic;
    reset: in std_logic;
    rx: in std_logic;
    char_out: out std_logic_vector(CHARACTER_SIZE-1 downto 0);
	char_flag: out std_logic
);
end uart;


architecture uart_arch of uart is


	constant BAUD: integer := 115200;
	constant BAUD_COUNT_CHECK: integer := 8680;
	
    --constant BAUD: unsigned(19 downto 0) := "00011100001000000000"; --115200;
    --constant FREQUENCY_IN_HZ = 100_000_000; "0011 1011 1001 1010 1100 1010 0000 0000"
    --constant BAUD_COUNT_CHECK = FREQUENCY_IN_HZ / BAUD; --8,680
    --constant BAUD_COUNT_CHECK: unsigned(19 downto 0) := "00000010000111101000";
    type state_type is (standby, wait_half_start_bit, wait_full_data_bit, capture_data_bit, wait_full_last_bit);
    
    
    signal uart_state, uart_state_next: state_type;
    signal cycle_count, cycle_count_next: unsigned(16 downto 0); --highest baudrate in uart: 115200 : 0001 1100 0010 0000 0000
    signal data_bit_count, data_bit_count_next: unsigned(CHARACTER_SIZE-1 downto 0);
    
    signal char_next,char_reg: std_logic_vector (CHARACTER_SIZE-1 downto 0) ;
    signal uart_bin: std_logic_vector(2 downto 0);
    
    -- component ila_0 port(
      --  clk: in std_logic;
       -- probe0: in std_logic_vector(0 downto 0);
        --probe1: in std_logic_vector(2 downto 0) );
   -- end component;
    
    
    begin 
	
	sequential_process: process(clk) is
	begin
		if rising_edge(clk) then
			if( reset = '0' ) then
				uart_state <= standby;
				char_reg <= (others => '0');
				cycle_count <= (others => '0');
				data_bit_count <= (others => '0');	
			else 
				uart_state <= uart_state_next;
				char_reg <= char_next;
				cycle_count <= cycle_count_next;
				data_bit_count <= data_bit_count_next;
			end if;
		end if;
	end process;
	
	
	
    UART_FSM: process(uart_state,cycle_count,char_reg,data_bit_count,rx ) is
	begin
        uart_state_next <= uart_state;
        cycle_count_next <= cycle_count;
        char_next <= char_reg;
        data_bit_count_next <= data_bit_count;
		char_flag <= '0';
      
        case uart_state is
            when standby =>
                if (rx = '0') then 
                    uart_state_next <= wait_half_start_bit;
                end if;  
                                      
            when wait_half_start_bit => 
                cycle_count_next <= cycle_count + 1;
                if (cycle_count = BAUD_COUNT_CHECK/2) then
                    cycle_count_next <= (others => '0');
                    uart_state_next <= wait_full_data_bit;
                end if;  
                              
            when wait_full_data_bit =>
                cycle_count_next <= cycle_count + 1; 
                if (cycle_count = BAUD_COUNT_CHECK) then
                    cycle_count_next <= (others => '0');
                    uart_state_next <= capture_data_bit;
                end if;
            
            when capture_data_bit => 
                char_next <= rx & char_reg(CHARACTER_SIZE-1 downto 1); --get new bit and add to char
                data_bit_count_next <= data_bit_count + 1;
                if( data_bit_count = CHARACTER_SIZE ) then
                    uart_state_next <= wait_full_last_bit;
                else
                    uart_state_next <= wait_full_data_bit;
                end if;
                           
            when wait_full_last_bit =>            
                cycle_count_next <= cycle_count + 1;
				char_flag <= '1';
                if (cycle_count = BAUD_COUNT_CHECK) then 
                    uart_state_next <= standby;
                    data_bit_count_next <= (others => '0');
                    cycle_count_next <= (others => '0'); 
					
                 end if;
                 
            when others =>
                uart_state_next <= uart_state;
                cycle_count_next <= cycle_count;
                char_next <= char_reg;
                data_bit_count_next <= data_bit_count;
                char_flag <= '0';
                                      
        end case;
    end process;
	
	char_out<= char_reg;
	
	--process(uart_state) is
	--begin
	  -- case(uart_state) is
         --   when standby =>
          --      uart_bin<="000";
          --  when wait_half_start_bit => 
           --     uart_bin<="001";
          --  when wait_full_data_bit =>
                --uart_bin<="010";
          --- when capture_data_bit => 
           --     uart_bin<="011";
          --  when wait_full_last_bit =>            
           --     uart_bin<="100";
          --  when others =>
           --     uart_bin<="111";
	  -- end case;
	
	--end process;
	
	
	--ILA_UART: ila_0 port map(clk=>clk,probe0(0)=>rx,probe1=>uart_bin);

end uart_arch;