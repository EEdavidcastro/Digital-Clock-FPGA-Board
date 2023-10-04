library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity flags is
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
end flags;

architecture Behavioral of flags is

begin

    --setting the flags based off inputs
    reset_flag <= '1' when reset_button = '1' else '0';
    up_flag <= '1' when up_button = '1' else '0';
    down_flag <= '1' when down_button = '1' else '0';
    confirm_flag <= '1' when confirm_button = '1' else '0';
    set_flag <= '1' when set_button = '1' else '0';
    
    min_hr_flag <= "00" when min_hr_switch = "00" else
                   "01" when min_hr_switch = "01" else
                   "10" when min_hr_switch = "10" else
                   "11";
                  
end Behavioral;
