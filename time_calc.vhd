library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity time_calc is
    Port(
        clk: in std_logic;
        state: in Integer Range 0 to 2;
        up_flag: in std_logic;
        down_flag: in std_logic;
        min_hr_flag: in std_logic_vector(1 downto 0);
        clk_display_min_1: out std_logic_vector(3 downto 0);
        clk_display_min_2: out std_logic_vector(3 downto 0);
        clk_display_hr_1: out std_logic_vector(3 downto 0);
        clk_display_hr_2: out std_logic_vector(3 downto 0)
        );
end time_calc;

architecture Behavioral of time_calc is
  --signals for the entity
    --signal for making a slow clock that is 1 Hz
    signal clkCnt: Integer := 0;
    signal slowClk: std_logic; 
    
   --signal for min clock(needed to use for transition from 60 seconds to 1 min)
   signal min_clk: std_logic;
   
   --signal for hour clock
   signal hour_clk: std_logic;
   
   --signal for min_clk process(will be used as a counter inside the process)
   signal minCount: Integer := 0;
    
    --signal for minutes digit counter
    signal minute_1: Integer range 0 to 10;
    signal minute_2: Integer range 0 to 10;
    
    --signal for hours digit counter
    signal hour_1: Integer range 0 to 10;
    signal hour_2: Integer range 0 to 10;
    
   --signal for debounce counter
   signal debounce_counter: Integer := 0;
   signal debounce_clk: std_logic;
   
   --signals for up button and down button for minute
   signal up_minute: std_logic;
   signal down_minute: std_logic;
   
   --signals for up button and down button for minute
   signal up_hour: std_logic;
   signal down_hour: std_logic;
   
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

    --process for debounce delay on up and down buttons
    debounce_delay: Process(clk)
        begin
            if(rising_edge(clk)) then
                if(debounce_counter = 40000000) then
                    debounce_counter <= 0;
                    debounce_clk <= '1';
                else
                    debounce_counter <= debounce_counter + 1;
                    debounce_clk <= '0';
                end if;
            end if;
    end Process debounce_delay;


    --process that counts and increments the minutes of the clock
    mins_counter: Process(clk, slowClk, min_clk, state, up_minute, down_minute)
        begin
            --when 60 seconds increment 1 min
            if(rising_edge(clk)) then
                --requiring synchronization of different clocks
                hour_clk <= '0'; --setting hour_clk to zero
                if(slowClk = '1' and min_clk = '1') then    
                        --when hits 60 mins increment back
                        --reason for number being 59 is because how statement is written
                        if(minute_2 = 5 and minute_1 = 9) then
                            minute_1 <= 0;
                            minute_2 <= 0;
                            hour_clk <= '1';
                        elsif(minute_1 = 9) then    --when hits 10 then increment second digit
                                    minute_1 <= 0;
                                    minute_2 <= minute_2 + 1; 
                        else
                            minute_1 <= minute_1 + 1;  --increment by 1 minute   
                        end if;
                end if;          
                
             --condition that the minute/hour switch is set for minutes 
             --if statement for incrementing by 1 when increase button is pressed
                if(up_minute = '1') then
                        --when hits 60 mins increment back to 0
                        --reason for number being 59 is because how statement is written
                    if(minute_2 = 5 and minute_1 = 9) then
                                minute_1 <= 0;
                                minute_2 <= 0;
                                hour_clk <= '1';
                    elsif(minute_1 = 9) then    --when hits 10 then increment second digit
                                minute_1 <= 0;
                                minute_2 <= minute_2 + 1; 
                    else
                        minute_1 <= minute_1 + 1;  --increment by 1 minute   
                    end if;  
                end if;
                
             --if statement for decrementing by 1 when the decrease button is pressed
               if(down_minute = '1') then
                        --when hits 0 decrements back to 59
                        --reason for number being 59 is because how statement is written
                    if(minute_1 = 0 and minute_2 = 0) then
                                minute_2 <= 5;
                                minute_1 <= 9;
                    elsif(minute_1 = 0) then    --when hits 10 then increment second digit
                                minute_1 <= 9;
                                minute_2 <= minute_2 - 1; 
                    else
                        minute_1 <= minute_1 - 1;  --increment by 1 minute   
                    end if;  
               end if;     
               
               --reseting minutes off reset input
               if(state = 0) then
                    minute_1 <= 0;
                    minute_2 <= 0;
               end if;
            end if;
         
    end Process mins_counter;

    --process that counters and increments the hours of the clock
     hours_counter: Process(clk, hour_clk, state, up_hour, down_hour)
        begin
            --when 60 minutes increment 1 hour
           if(rising_edge(clk)) then
           --synchronization of different clocks to make sure it triggers correctly
                if(hour_clk = '1') then 
                            --when reach number ten then increment second digit
                            if(hour_1 = 9) then
                                hour_1 <= 0;
                                hour_2 <= hour_2 + 1;
                            
                            --when hits 23 hours then reset back to 0
                            elsif(hour_2 = 2 and hour_1 = 3) then
                                hour_1 <= 0;
                                hour_2 <= 0;
                            
                            --increment normally 
                            else 
                                hour_1 <= hour_1 + 1;
                            end if;
                end if;
                            
                --if the min/hour switch is set for hour
                --if statement for incrementing by 1 when increase button is pressed
                if(up_hour = '1') then
                                --when reach number ten then increment second digit
                                if(hour_1 = 9) then
                                    hour_1 <= 0;
                                    hour_2 <= hour_2 + 1;
                                
                                --when hits 23 hours then reset back to 0
                                elsif(hour_2 = 2 and hour_1 = 3) then
                                    hour_1 <= 0;
                                    hour_2 <= 0;
                               
                               --increment normally     
                                else
                                    hour_1 <= hour_1 + 1;
                                end if;
            
                end if;
                
                --if statement for decrementing by 1 when the decrease button is pressed
                if(down_hour = '1') then

                                --when reach number 9 then decrement second digit
                                if(hour_1 = 0 and hour_2 /= 0) then
                                    hour_1 <= 9;
                                    hour_2 <= hour_2 - 1;
                                
                                --when hits 0 hours then reset back to 23
                                elsif(hour_1 = 0 and hour_2 = 0) then
                                    hour_2 <= 2;
                                    hour_1 <= 3;
                                    
                                --decrement normally
                                else
                                    hour_1 <= hour_1 - 1;
                                end if;
                end if;
                
                --reseting seconds off reset input
                if(state = 0) then
                    hour_1 <= 0;
                    hour_2 <= 0;
                
                end if;
           end if;    
     end Process hours_counter; 

 --Concurrent Logic CODE:
    --this would be the slowclk that converts 100Mhz to 1Hz  
    slowClk <= '1' when clkCnt = 100000000 - 1 else '0';
    
    --this wouild be the minuites that triggers off slowClk
    min_clk <= '1' when minCount = 60 - 1 else '0';
    
    
    --setting conditions for up/down button for mins
    up_minute <= '1' when state = 2 and up_flag = '1' and min_hr_flag = "00" and debounce_clk = '1' else '0';
    down_minute <= '1'when state = 2 and down_flag = '1' and min_hr_flag = "00" and debounce_clk = '1' else '0';
    
    --setting conditions for up/down button for mins
    up_hour <= '1' when state = 2 and up_flag = '1' and min_hr_flag = "01" and debounce_clk = '1' else '0';
    down_hour <= '1' when state = 2 and down_flag = '1' and min_hr_flag = "01" and debounce_clk = '1' else '0';
    
    
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
                         "1001" when minute_1 = 9 else
                         "1111"; --F as in error 
                         
    clk_display_min_2 <= "0000" when minute_2 = 0 else
                         "0001" when minute_2 = 1 else
                         "0010" when minute_2 = 2 else
                         "0011" when minute_2 = 3 else
                         "0100" when minute_2 = 4 else
                         "0101" when minute_2 = 5 else
                         "0110" when minute_2 = 6 else
                         "0111" when minute_2 = 7 else
                         "1000" when minute_2 = 8 else
                         "1001" when minute_2 = 9 else
                         "1111"; --F as in error 
                         
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
                        "1001" when hour_1 = 9 else
                        "1111"; --F as in error 
    
    clk_display_hr_2 <= "0000" when hour_2 = 0 else
                        "0001" when hour_2 = 1 else
                        "0010" when hour_2 = 2 else
                        "0011" when hour_2 = 3 else
                        "0100" when hour_2 = 4 else
                        "0101" when hour_2 = 5 else
                        "0110" when hour_2 = 6 else
                        "0111" when hour_2 = 7 else
                        "1000" when hour_2 = 8 else
                        "1001" when hour_2 = 9 else
                        "1111"; --F as in error 
    
    
end Behavioral;
