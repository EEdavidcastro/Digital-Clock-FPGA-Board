library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sevseg_display is
    Port(
        clk: in std_logic;
        clk_display_min_1: in std_logic_vector(3 downto 0);
        clk_display_min_2: in std_logic_vector(3 downto 0);
        clk_display_hr_1: in std_logic_vector(3 downto 0);
        clk_display_hr_2: in std_logic_vector(3 downto 0);
--        alarm_display_min: in std_logic_vector(5 downto 0);
--        alarm_display_hr: in std_logic_vector(4 downto 0);
        SEVSEG: out std_logic_vector(7 downto 0);
        ANODE: out std_logic_vector(7 downto 0)
    );
end sevseg_display;

architecture Behavioral of sevseg_display is
    --signal for display
    signal code: std_logic_vector(3 downto 0);

    --creating a type for the states 
    type eg_state_type is (s0, s1, s2, s3);     
    
    --signals for states
    signal state_reg, state_next: eg_state_type;    --for FSM 

begin
    --internal clock is at 100MHZ
    --wanna refresh at 60 Hz which is 0.016 sec
    -- there are 8 sevseg therefore we want each on for 0.002 sec
    -- 0.002 sec = 500 HZ
    -- 100MHZ/550 HZ = 200,000
    -- therefore have to count up to 200,000
    --for simulation change counter to 1
        timer: Process(clk)
            variable counter: integer := 0;          -- setting counter to implement a cycle
            begin
                if(rising_edge(clk)) then
                    if(counter = 400000) then   --CURRENTLY SET FOR 4 SEVSEGS
                        state_reg <= state_next;
                        counter := 0;
                    else
                        counter := counter + 1;
                    end if;
                end if;
        end Process timer;

   --on simulation the AN will appear wrong because we have the LED refreshing right to left here and not basesd off numbers     
   --Process for switching the 7SEG Light (AN)
   LED: Process(state_reg)
       begin
          case state_reg is
                when s0 => --for displaying first sevseg (clk min_1)
                    code <= clk_display_min_1;
                    state_next <= s1; -- go to next 7SEG
                    ANODE <= "11111110";    --enabling first LED
                
                when s1 => --for displaying second sevseg (clk min_2)
                    code <= clk_display_min_2;
                    state_next <= s2; -- go to next 7SEG
                    ANODE <= "11111101";    --enabling second LED
                    
                when s2 => --for displaying third sevseg(clk hr_1)
                    code <= clk_display_hr_1;
                    state_next <= s3; -- go to next 7SEG
                    ANODE <= "11111011";    --enabling third LED
                    
                when s3 => --for displaying fourth sevseg(clk hr_2)
                    code <= clk_display_hr_2;
                    state_next <= s0; -- go back to first 7SEG
                    ANODE <= "11110111";    --enabling fourth LED
                    
--                when s4 => --for displaying 5th sevseg (alarm min_1)
--                     code <= alarm_display_min(3 downto 0);
                    
--                when s5 => --for displaying 6th sevseg (alarm min_2)
--                    code <= "00" & alarm_display_min(5 downto 4);
                
--                when s6 => --for displaying 7th sevseg (alarm hr_1)
--                    code <= alarm_display_hr(3 downto 0);
                
--                when s7 => --for displaying 8th sevseg (alarm hr_2)
--                    code <= "000" & alarm_display_hr(4);
                    
          end case;
    end Process LED;
    
    --SEVSEG = | CA | CB | CC | CD | CE | CF | CG | DP 
    SEVSEG <= "00000011" when code <= "0000" else   -- display 0
            "10011111" when code <= "0001" else   -- display 1
            "00100101" when code <= "0010" else   -- display 2
            "00001101" when code <= "0011" else   -- display 3
            "10011001" when code <= "0100" else   -- display 4
            "01001001" when code <= "0101" else   -- display 5
            "01000001" when code <= "0110" else   -- display 6
            "00011111" when code <= "0111" else   -- display 7
            "00000001" when code <= "1000" else   -- display 8
            "00001001" when code <= "1001" else   -- display 9
            "11111111";

end Behavioral;
