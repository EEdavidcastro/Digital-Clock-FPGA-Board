--this is a basic version for just running a basic clock

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity state_machine_clock is
    Port(
        --clk input for hardware
        clk: in std_logic;
        --flag inputs
        reset_flag: in std_logic;
        up_flag: in std_logic;
        down_flag: in std_logic;
        set_flag: in std_logic;
        confirm_flag: in std_logic;
        min_hr_flag: in std_logic_vector(1 downto 0);
     --outputs for 7-Seg display   
        clk_display_min_1: out std_logic_vector(3 downto 0);
        clk_display_min_2: out std_logic_vector(3 downto 0);
        clk_display_hr_1: out std_logic_vector(3 downto 0);
        clk_display_hr_2: out std_logic_vector(3 downto 0);
--        alarm_display_min: out std_logic_vector(5 downto 0);
--        alarm_display_hr: out std_logic_vector(4 downto 0);
      --led status (RGB)
        LED_status: out std_logic_vector(2 downto 0);
      --second display for LEDS
        LED_seconds: out std_logic_vector(5 downto 0);
        LED_seconds_countdown: out std_logic_vector(5 downto 0)
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
    
    --signal for minutes digit counter
    signal minute_1: Integer range 0 to 10;
    signal minute_2: Integer range 0 to 10;
    
    --signal for hours digit counter
    signal hour_1: Integer range 0 to 10;
    signal hour_2: Integer range 0 to 10;
   
   --signal for min clock(needed to use for transition from 60 seconds to 1 min)
   signal min_clk: std_logic;
   
   --signal for min_clk process(will be used as a counter inside the process)
   signal minCount: Integer := 0;
   
   --signal for hour clock (needed to use for transition from 60 mins to 1 hour)
   signal hour_clk: std_logic;
   
   --signal for hours_clk process(will be used as a counter inside the process)
   signal hoursCount: Integer := 0;
    
   --signal for two second delay in reset state 
   signal two_seconds: Integer := 0; 
   
   --signal for 20 seconds delay in set/change state
   signal twenty_seconds: std_logic_vector(5 downto 0);
   
   --signal for debounce counter
   signal debounce_counter: Integer := 0;
   signal debounce_clk: std_logic;
   
begin
  
   --clk scaler with 100 MHz clk (make 1 Hz clock)
  Prescaler: Process(clk)
   begin
    if rising_edge(clk) then
        if (clkCnt = 100000000 - 1) then -- if counts up to 100 million  
            clkCnt <= 0;    -- when one second passes reset counter
        else 
            clkCnt <= clkCnt + 1; --incrementing counter to simulate seconds
        end if;
    end if;
  end process Prescaler;
  
  --triggering 1 min clk cycle (making it so it trigger for a single clock rising)
  min_Prescaler: Process(clk)
   begin
    if rising_edge(clk) then
        if(slowClk = '1') then
            --reason for the minus 1 is because there's a 1 second delay otheriwse
            if (minCount = 60 - 1) then -- 60 seconds in 1 in minute
                minCount <= 0;    -- when one hour passes reset counter
            else 
                minCount <= minCount + 1; --incrementing counter to simulate seconds
            end if;
        end if;
    end if;
    
    --reseting minute counter upon reset state because of the two second delay (will make an error otherwise)
    if(state = 0 or state = 2) then
        minCount <= 0;
    end if;
  end process min_Prescaler;
  
    --triggering 1 hour clk cycle (making it so it trigger for a single clock rising)
  Hour_Prescaler: Process(clk)
   begin
    if rising_edge(clk) then
        if(slowClk = '1') then
            --reason for the minus 1 is because there's a 1 min delay otherwise
            if (hoursCount = 3600 - 1) then -- 60 seconds in 60 minutes  
                hoursCount <= 0;    -- when one hour passes reset counter
            else 
                hoursCount <= hoursCount + 1; --incrementing counter to simulate seconds
            end if;
        end if;
    end if;
    
    --reseting hour counter upon reset state because of the two second delay (will make an error otherwise)
    if(state = 0 or state = 2) then
        hoursCount <= 0;
    end if;     
  end process Hour_Prescaler;
  
    --process for setting states
--    setting_states: Process(reset_flag, two_seconds, set_flag, confirm_flag, twenty_seconds) 
--     begin
              
--          if(reset_flag = '1' and confirm_flag = '0' and set_flag = '0') then
--            next_state <= 0;    --reset state
--          end if;
          
--          --after 2 seconds in reset state go to clock running state  
--          --have it equal to 1 because the way things are setup this acts as two seconds
--          --because the order things are triggered it would be 3 seconds if I did 2
--          if(two_seconds = 1 and state = 0) then
--            next_state <= 1;
          
--          --for entering the set/change state
--          elsif(set_flag = '1') then
--            next_state <= 2;
          
--          elsif(confirm_flag = '1' or twenty_seconds = "010100") then
--            next_state <= 1;
--          end if;
         
--   end Process setting_states;
    
    --process for debounce delay on up and down buttons
    debounce_delay: Process(clk)
        begin
            if(rising_edge(clk)) then
                if(debounce_counter = 70000000) then
                    debounce_counter <= 0;
                    debounce_clk <= '1';
                else
                    debounce_counter <= debounce_counter + 1;
                    debounce_clk <= '0';
                end if;
            end if;
    end Process debounce_delay;
    
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
    
    
    --process that counts and increments the minutes of the clock
    mins_counter: Process(clk, slowClk, min_clk,  state, up_flag, down_flag)
        begin
            --when 60 seconds increment 1 min
            if(rising_edge(clk)) then
                --requiring synchronization of different clocks
                if(slowClk = '1' and min_clk = '1') then    
                        --when hits 60 mins increment back
                        --reason for number being 59 is because how statement is written
                        if(minute_1 = 5 and minute_2 = 9) then
                            minute_1 <= 0;
                            minute_2 <= 0;
                        elsif(minute_1 = 9) then    --when hits 10 then increment second digit
                                    minute_1 <= 0;
                                    minute_2 <= minute_2 + 1; 
                        else
                            minute_1 <= minute_1 + 1;  --increment by 1 minute   
                        end if;  
             --condition that the minute/hour switch is set for minutes 
             --if statement for incrementing by 1 when increase button is pressed
                elsif(state = 2 and up_flag = '1' and min_hr_flag = "00" and debounce_clk = '1') then
                        --when hits 60 mins increment back to 0
                        --reason for number being 59 is because how statement is written
                    if(minute_1 = 5 and minute_2 = 9) then
                                minute_1 <= 0;
                                minute_2 <= 0;
                    elsif(minute_1 = 9) then    --when hits 10 then increment second digit
                                minute_1 <= 0;
                                minute_2 <= minute_2 + 1; 
                    else
                        minute_1 <= minute_1 + 1;  --increment by 1 minute   
                    end if;  
                
             --if statement for decrementing by 1 when the decrease button is pressed
               elsif(state = 2 and down_flag = '1' and min_hr_flag = "00" and debounce_clk = '1') then
                        --when hits 0 decrements back to 59
                        --reason for number being 59 is because how statement is written
                    if(minute_1 = 0 and minute_2 = 0) then
                                minute_1 <= 5;
                                minute_2 <= 9;
                    elsif(minute_1 = 1) then    --when hits 10 then increment second digit
                                minute_1 <= 0;
                                minute_2 <= minute_2 - 1; 
                    else
                        minute_1 <= minute_1 - 1;  --increment by 1 minute   
                    end if;  
                end if;
            end if;
            
    
            
            --reseting minutes off reset input
            if(state = 0) then
                minute_1 <= 0;
                minute_2 <= 0;
            end if;
         
    end Process mins_counter;
    
    
    --process that counters and increments the hours of the clock
     hours_counter: Process(clk, slowClk, hour_clk, state, up_flag, down_flag)
        begin
            --when 60 minutes increment 1 hour
           if(rising_edge(clk)) then
           --synchronization of different clocks to make sure it triggers correctly
                if(slowClk = '1' and min_clk = '1' and hour_clk = '1') then 
                        hour_1 <= hour_1 + 1;
                            --when reach number ten then increment second digit
                            if(hour_1 = 10) then
                                hour_1 <= 0;
                                hour_2 <= hour_2 + 1;
                            end if;
                            
                            --when hits 25 hours then reset back to 0
                            if(hour_1 = 2 and hour_2 = 5) then
                                hour_1 <= 0;
                                hour_2 <= 0;
                            end if;
                            
                --if the min/hour switch is set for hour
                --if statement for incrementing by 1 when increase button is pressed
                elsif(state = 2 and up_flag = '1' and min_hr_flag = "01" and debounce_clk = '1') then
                     hour_1 <= hour_1 + 1;
                                --when reach number ten then increment second digit
                                if(hour_1 = 10) then
                                    hour_1 <= 0;
                                    hour_2 <= hour_2 + 1;
                                end if;
                                
                                --when hits 25 hours then reset back to 0
                                if(hour_1 = 2 and hour_2 = 5) then
                                    hour_1 <= 0;
                                    hour_2 <= 0;
                                end if;
            
                
--                --if statement for decrementing by 1 when the decrease button is pressed
                elsif(state = 2 and down_flag = '1' and min_hr_flag = "01" and debounce_clk = '1') then
                    hour_1 <= hour_1 - 1;
                                --when reach number ten then increment second digit
                                if(hour_1 = 1) then
                                    hour_1 <= 0;
                                    hour_2 <= hour_2 - 1;
                                end if;
                                
                                --when hits 25 hours then reset back to 0
                                if(hour_1 = 0 and hour_2 = 0) then
                                    hour_1 <= 2;
                                    hour_2 <= 4;
                                end if;
                end if;
           end if;     
            
            --reseting seconds off reset input
            if(state = 0) then
                hour_1 <= 0;
                hour_2 <= 0;
            end if;
         
     end Process hours_counter; 
           
    --setting the output for the seconds counter to be displayed
    LED_seconds <= seconds;
    
    --setting the output for the minutes counter to be displayed
    clk_display_min_1 <= "0000" when minute_1 = 0 else
                         "0001" when minute_1 = 1 else
                         "0010" when minute_1 = 2 else
                         "0011" when minute_1 = 3 else
                         "0100" when minute_1 = 4 else
                         "0101" when minute_1 = 5 else
                         "0110" when minute_1 = 6 else
                         "0111" when minute_1 = 7 else
                         "1000" when minute_1 = 8 else
                         "1001" when minute_1 = 9; 
                         
    clk_display_min_2 <= "0000" when minute_2 = 0 else
                         "0001" when minute_2 = 1 else
                         "0010" when minute_2 = 2 else
                         "0011" when minute_2 = 3 else
                         "0100" when minute_2 = 4 else
                         "0101" when minute_2 = 5 else
                         "0110" when minute_2 = 6 else
                         "0111" when minute_2 = 7 else
                         "1000" when minute_2 = 8 else
                         "1001" when minute_2 = 9;
                         
    --setting the output for the hours counter to be displayed
    clk_display_hr_1 <= "0000" when hour_1 = 0 else
                        "0001" when hour_1 = 1 else
                        "0010" when hour_1 = 2 else
                        "0011" when hour_1 = 3 else
                        "0100" when hour_1 = 4 else
                        "0101" when hour_1 = 5 else
                        "0110" when hour_1 = 6 else
                        "0111" when hour_1 = 7 else
                        "1000" when hour_1 = 8 else
                        "1001" when hour_1 = 9;
    
    clk_display_hr_2 <= "0000" when hour_2 = 0 else
                        "0001" when hour_2 = 1 else
                        "0010" when hour_2 = 2 else
                        "0011" when hour_2 = 3 else
                        "0100" when hour_2 = 4 else
                        "0101" when hour_2 = 5 else
                        "0110" when hour_2 = 6 else
                        "0111" when hour_2 = 7 else
                        "1000" when hour_2 = 8 else
                        "1001" when hour_2 = 9;
    
    next_state <= 0 when reset_flag = '1' else
                  1 when two_seconds = 1 and state = 0 else
                  2 when set_flag = '1' else
                  1 when state = 2 and (confirm_flag = '1' or twenty_seconds = "010100"); 
    
    --this would be the slowclk that converts 100Mhz to 1Hz  
    slowClk <= '1' when clkCnt = 100000000 - 1 else '0';
    
    --this wouild be the minuites that triggers off slowClk
    min_clk <= '1' when minCount = 60 - 1 else '0';
    
    
    --this would be the hours that triggers off slowClk
    hour_clk <= '1' when hoursCount = 3600 - 1 else '0';
    
    --setting the set/change counter 
     LED_seconds_countdown <= twenty_seconds;
    
end Behavioral;
