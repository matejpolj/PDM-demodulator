----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 29.04.2024 18:40:43
-- Design Name: 
-- Module Name: dc_blocker - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dc_blocker is
    Generic (   BIN_width : integer := 10;
                FIXED_LEN : integer := 9;
                GAIN      : integer := 3);
    Port ( clk : in STD_LOGIC;
           nrst : in STD_LOGIC;
           D_in : in STD_LOGIC_VECTOR (15 downto 0);
           D_out : out STD_LOGIC_VECTOR (15 downto 0));
end dc_blocker;

architecture Behavioral of dc_blocker is

    subtype FIXED_T is  signed(BIN_width-1+FIXED_LEN downto 0);
    subtype MULT_T  is  signed(BIN_width*2-1+FIXED_LEN*2 downto 0);
    
    signal inp      : FIXED_T   := (others => '0');
    signal sum_i    : FIXED_T   := (others => '0');
    signal sum_b    : FIXED_T   := (others => '0');
    signal sum_n    : FIXED_T   := (others => '0');
    signal sum_t    : FIXED_T   := (others => '0');
    signal sum_s    : std_logic_vector(BIN_width-1+FIXED_LEN*2 downto 0)  := (others => '0');
    signal sum_m    : MULT_T    := (others => '0');
    signal sum_r    : signed(BIN_width-1+FIXED_LEN*2 downto 0);
    signal outp     : FIXED_T   := (others => '0');
    signal outn     : std_logic_vector(BIN_width-1+FIXED_LEN downto 0)  := (others => '0');
    signal outs     : signed(BIN_width-1+FIXED_LEN downto 0)  := (others => '0');

    constant filler : std_logic_vector(FIXED_LEN-1 downto 0) := (others => '0');
    constant coef   : signed(BIN_width-1+FIXED_LEN downto 0) := b"0000000000000000111111110";
    
begin

    inp <= signed (D_in&filler);
    
    sum_i <= inp+sum_t;
    
    --sum_n <= sum_b*(-1);
    sum_n <= -sum_b;
    
    buff : process(clk, nrst)
    begin
        if (nrst = '0') then
            sum_b <= (others => '0');
        elsif (rising_edge(clk)) then
            sum_b <= sum_i;
        end if;
    end process;
    
    sum_m <= sum_b*coef;
    sum_r <= resize(sum_m, 2*FIXED_LEN+BIN_width);
    
    sum_s <= std_logic_vector(sum_r);
    sum_t <= signed(sum_s(BIN_WIDTH-1+FIXED_LEN*2 downto FIXED_LEN));
    
    outp <= sum_i+sum_n;
    
    
    outn <= std_logic_vector(outp);
    outs <= shift_left(outp, GAIN);
    D_out <= outn(BIN_width-1+FIXED_LEN downto FIXED_LEN);

end Behavioral;
