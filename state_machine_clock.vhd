library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;


entity state_machine_clock is
    Port(
        --clk input for hardware
        clk: in std_logic;
        --flag inputs
        reset_flag: in std_logic;
        set_flag: in std_logic;
        confirm_flag: in std_logic;
      --led status (RGB)
        LED_status: out std_logic_vector(2 downto 0);
      --second display for LEDS
        LED_seconds: out std_logic_vector(5 downto 0);
        LED_seconds_countdown: out std_logic_vector(5 downto 0);
        state_output: out Integer Range 0 to 2
    );
end state_machine_clock;


architecture Behavioral of state_machine_clock is
    
    --signal  for states
    signal state: Integer range 0 to 2;
    signal next_state: Integer range 0 to 2;
    
    --signal for making a slow clock that is 1 Hz
    signal clkCnt: Integer := 0;
    signal slowClk: std_logic; 
     
    --signal for seconds counter
    signal seconds: std_logic_vector(5 downto 0);
   
    --signal for two second delay in reset state 
    signal two_seconds: Integer := 0; 
   
    --signal for 20 seconds delay in set/change state
    signal twenty_seconds: std_logic_vector(5 downto 0);
   
begin

  --clk scaler with 100 MHz clk (make 1 Hz clock)
  second_Prescaler: Process(clk)
   begin
    if rising_edge(clk) then
        if (clkCnt = 100000000 - 1) then -- if counts up to 100 million  
            clkCnt <= 0;    -- when one second passes reset counter
        else 
            clkCnt <= clkCnt + 1; --incrementing counter to simulate seconds
        end if;
    end if;
  end process second_Prescaler;
  
  
   --process that counts the seconds of each minute
    seconds_counter: Process(clk, slowClk, state) 
        begin
            if(rising_edge(clk)) then
                if(slowClk = '1') then
                    --reason for being 59 is because of how statement is written
                    if(seconds ="111011") then    --reset back to 0 when 60 seconds pass
                        seconds <= "000000";
                    else 
                        seconds <= seconds + "000001"; --increment seconds counter
                    end if;             
                end if;
            end if;    
            
            --reseting seconds off reset input
            if(state = 0 or state = 2) then
                seconds <= "000000";
            end if;
     end Process seconds_counter;
  
    --process that counts 2 seconds
    two_second_delay: Process(clk, slowClk, state) 
        begin
            if(rising_edge(clk)) then
                if(slowClk = '1' and state = 0) then
                    --incrementing by 1 second
                    two_seconds <= two_seconds + 1; 
                end if;
            end if;    
            
            --reseting seconds after done with reset state
            if(state = 1 or state = 2) then
                two_seconds <= 0;
            end if;
     end Process two_second_delay;
    
    --process that counts to 20 seconds
    twenty_second_delay: Process(clk, slowClk, state) 
        begin
            if(rising_edge(clk)) then
                if(slowClk = '1' and state = 2) then
                    --incrementing by 1 second
                    twenty_seconds <= twenty_seconds + "000001"; 
                end if;
            end if;    
            
            --reseting seconds after done with reset state
            if(state = 0 or state = 1) then
                twenty_seconds <= "000000";
            end if;
     end Process twenty_second_delay;
    
    --Process that will tranistion the state to the nextstate
    --using slowClk to act as a slight debounce
    transition_next_state: Process(clk) 
        begin
            if(rising_edge(clk)) then
                if(slowClk = '1') then
                    state <= next_state;
                end if;    
            end if;     
     end Process transition_next_state;
    
    --Process for entering next state
    next_state_condition: Process(clk)
        begin
            if(rising_edge(clk)) then
                if(reset_flag = '1') then
                    next_state <= 0;
                end if;
                
                if(two_seconds = 1 and state = 0) then
                    next_state <= 1;
                end if;
                
                if(set_flag = '1') then
                    next_state <= 2;
                end if;
                
                if(state = 2 and (confirm_flag = '1' or twenty_seconds = "010100")) then
                    next_state <= 1;
                end if;
            end if;
        end Process;
    
    
     
    --process for state outputs
    states: Process(state)
        begin
            case state is 
                when 0 => --reset state
                    LED_status <= "001"; --outputting blue (RGB)
                
                when 1 => --clock running state
                    LED_status <= "000"; --outputting black (RGB)
                
                when 2 =>
                    LED_status <= "100"; --outputtting red (RGB) 
                end case;
    end Process states;
    
    
 --Concurrent Logic CODE BELOW:

    --this would be the slowclk that converts 100Mhz to 1Hz  
    slowClk <= '1' when clkCnt = 100000000 - 1 else '0';
    
    --setting the output for the seconds counter to be displayed
    LED_seconds <= seconds;
    
    --setting the set/change counter 
    LED_seconds_countdown <= twenty_seconds;
    
    --setting the state output for transfering to other entity
    state_output <= state;
    
end Behavioral;
