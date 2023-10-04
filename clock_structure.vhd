library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clock_structure is
    Port(
        clk: in std_logic;
        reset_button: in std_logic;
        up_button: in std_logic;
        down_button: in std_logic;
        confirm_button: in std_logic;
        set_button: in std_logic;
        min_hr_switch: in std_logic_vector(1 downto 0);
        SEVSEG: out std_logic_vector(7 downto 0);
        ANODE: out std_logic_vector(7 downto 0);
        --led status (RGB)
        LED_status: out std_logic_vector(2 downto 0);
      --second display for LEDS
        LED_seconds: out std_logic_vector(5 downto 0);
        LED_seconds_countdown: out std_logic_vector(5 downto 0)
    );
end clock_structure;

architecture Behavioral of clock_structure is
    --signals to interconnect the entities together
        signal signal_reset_flag: std_logic;
        signal signal_up_flag: std_logic;
        signal signal_down_flag: std_logic;
        signal signal_set_flag: std_logic;
        signal signal_confirm_flag: std_logic;
        signal signal_min_hr_flag: std_logic_vector(1 downto 0);
        signal signal_clk_display_min_1: std_logic_vector(3 downto 0);
        signal signal_clk_display_min_2: std_logic_vector(3 downto 0);
        signal signal_clk_display_hr_1: std_logic_vector(3 downto 0);
        signal signal_clk_display_hr_2: std_logic_vector(3 downto 0);
        signal signal_LED_status: std_logic_vector(2 downto 0);
        
        
        --intiailzing a counter for the slow clock
        signal counter: Integer := 0;
        
        --intializing a slow clock for 100 HZ
        signal slw_clk: std_logic;
        
        
  --entities being used
    Component flags
        Port(
        reset_button: in std_logic;
        up_button: in std_logic;
        down_button: in std_logic;
        confirm_button: in std_logic;
        set_button: in std_logic;
        min_hr_switch: in std_logic_vector(1 downto 0);
        reset_flag: out std_logic;
        up_flag: out std_logic;
        down_flag: out std_logic;
        set_flag: out std_logic;
        confirm_flag: out std_logic;
        min_hr_flag: out std_logic_vector(1 downto 0)
    );
    end Component;
  
    Component state_machine_clock
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
    end Component;
    
    Component sevseg_display
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
    end Component;

begin  
    
    --Process for implementing a slow clock
    --Internal CLK is 100MHZ
    --want a 100 HZ clk
    --therefore 100MHZ / 1MHZ = 100 HZ clk
    SLOW_CLK: Process(clk)
        begin
            --act as a counter for the clock
            if(rising_edge(clk)) then
                if(counter = 1000000) then  --resets back to 0 when 1MHZ
                    counter <= 0;
                else
                    counter <= counter + 1;
                end if;   
            end if;
           
    end Process SLOW_CLK;


  --connecting the entities together (structure)
    intial_inputs: flags Port Map
        (
            reset_button => reset_button,
            up_button => up_button,
            down_button => down_button,
            confirm_button => confirm_button,
            set_button => set_button,
            min_hr_switch => min_hr_switch,
            reset_flag => signal_reset_flag,
            up_flag => signal_up_flag,
            down_flag => signal_down_flag,
            set_flag => signal_set_flag,
            confirm_flag => signal_confirm_flag,
            min_hr_flag => signal_min_hr_flag
        );
     
    FSM: state_machine_clock Port Map
        (
            clk => clk,
            reset_flag => signal_reset_flag,
            up_flag => signal_up_flag,
            down_flag => signal_down_flag,
            set_flag => signal_set_flag,
            confirm_flag => signal_confirm_flag,
            min_hr_flag => signal_min_hr_flag,
            clk_display_min_1 => signal_clk_display_min_1,
            clk_display_min_2 => signal_clk_display_min_2,
            clk_display_hr_1 => signal_clk_display_hr_1,
            clk_display_hr_2 => signal_clk_display_hr_2,
            LED_status => signal_LED_status,
            LED_seconds => LED_seconds,
            LED_seconds_countdown => LED_seconds_countdown
        );        
    
    SevenSegment_dipslay: sevseg_display Port Map
        (
            clk => clk,
            clk_display_min_1 => signal_clk_display_min_1,
            clk_display_min_2 => signal_clk_display_min_2,
            clk_display_hr_1 => signal_clk_display_hr_1,
            clk_display_hr_2 => signal_clk_display_hr_2,
            SEVSEG => SEVSEG,
            ANODE => ANODE
        );
        
    
    --in order to get 10% duty cycle we want the slow clock on for 10%    
    --10% of the slow_clock is 10% of the counter (100,000)
    slw_clk <= '1' when counter <= 100000 else '0';
    LED_status <= signal_LED_status when slw_clk = '1' else "000";
        
end Behavioral;
