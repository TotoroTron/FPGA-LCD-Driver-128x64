library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_arith.all;

entity lcd_control is
    generic(mystring : string := "ABCDE");
    port(
        clk : in std_logic; --50Mhz Clock
        RS : out std_logic; --Instruction / Data Register Selection
        RW : buffer std_logic; --Read/Write Selection
        EN : out std_logic; --LCD Enable
        DB : out std_logic_vector(7 downto 0); --Data Bus
        PSB : out std_logic; --Serial/Parallel Selection
        RST : out std_logic --Reset
    );
end lcd_control;

architecture Behavioral of lcd_control is
    type LCD_STATES IS (
        FUNCTION_SET, DISPLAY_ONOFF_CTRL, DISPLAY_CLEAR, ENTRY_MODE_SET,
        WRITE_CHAR, RETURN_HOME, STALL, toggle_e
    );
    signal state : LCD_STATES := FUNCTION_SET;
    signal next_state: LCD_STATES;
    signal data_bus: STD_LOGIC_VECTOR(7 downto 0);
    signal clk_400: std_logic;
    signal clk_count: integer range 0 to 62500;
    signal index : integer range 1 to mystring'length;
begin

DB <= data_bus when RW = '0' else "ZZZZZZZZ";
PSB <= '1'; --parallel data mode
RST <= '1';

CLK_DIV_540KHZ: process(clk)
begin
    if rising_edge(clk) then
        if clk_count < 62500 then
            clk_count <= clk_count + 1;
        else
            clk_count <= 0;
            clk_400 <= NOT clk_400;
        end if;
    end if;
end process;


STATE_MACHINE: process (clk_400)
begin
    if rising_edge(clk_400) then
    case state is
    when FUNCTION_SET =>
        RS <= '0'; RW <= '0'; EN <= '1';
        data_bus <= "00110000";
        state <= toggle_e;
        next_state <= DISPLAY_ONOFF_CTRL;
    when DISPLAY_ONOFF_CTRL =>
        RS <= '0'; RW <= '0'; EN <= '1';
        data_bus <= "00001100"; --disp, cursor, blink all ON
        state <= toggle_e;
        next_state <= DISPLAY_CLEAR;
    when DISPLAY_CLEAR =>
        RS <= '0'; RW <= '0'; EN <= '1';
        data_bus <= "00000001";
        state <= toggle_e;
        next_state <= ENTRY_MODE_SET;
    when ENTRY_MODE_SET =>
        RS <= '0'; RW <= '0'; EN <= '1';
        data_bus <= "00000110";
        state <= toggle_e;
        next_state <= WRITE_CHAR;
    when WRITE_CHAR =>
        RS <= '1'; RW <= '0'; EN <= '1';
        data_bus <= std_logic_vector(to_unsigned( natural( character'pos( mystring(index) ) ), 8) ) ;
        state <= toggle_e;
        if (index < mystring'length) then
            index <= index + 1;
            next_state <= WRITE_CHAR;
        else
            index <= 1;
            next_state <= RETURN_HOME;
        end if;
    when RETURN_HOME =>
        RS <= '0'; RW <= '0'; EN <= '1';
        data_bus <= "00000010";
        state <= toggle_e;
        next_state <= WRITE_CHAR;
    when toggle_e =>
        EN <= '0';
        state <= STALL;
    when STALL =>
        state <= next_state;
    end case;
    end if;
end process;

end Behavioral;
