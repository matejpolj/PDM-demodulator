----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02.05.2024 12:00:19
-- Design Name: 
-- Module Name: fir_dec - Behavioral
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

entity fir_dec is
    Port ( clk_i : in STD_LOGIC;
           nrst : in STD_LOGIC;
           D_in : in STD_LOGIC_VECTOR (15 downto 0);
           D_out : out STD_LOGIC_VECTOR (15 downto 0);
           clk_o : out STD_LOGIC);
end fir_dec;

architecture Behavioral of fir_dec is

    component fir_dec_8 IS
       PORT( clk_i                           :   IN    std_logic; 
             clk_enable                      :   IN    std_logic; 
             nrst                            :   IN    std_logic; 
             D_in                            :   IN    std_logic_vector(15 DOWNTO 0); -- sfix16
             D_out                           :   OUT   std_logic_vector(26 DOWNTO 0)  -- sfix27_En10
             );
    
    END component;
    component dc_blocker is
        Generic (   BIN_width : integer := 10;
                    FIXED_LEN : integer := 9;
                    GAIN      : integer := 3);
        Port ( clk : in STD_LOGIC;
               nrst : in STD_LOGIC;
               D_in : in STD_LOGIC_VECTOR (15 downto 0);
               D_out : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    signal clk_d :  std_logic                           := '0';
    signal count :  integer range 0 to (8-1)            := 0;
    
    signal d_fir_out :  std_logic_vector(26 downto 0)   := (others => '0');  
    signal d_fir_red :  signed(17 downto 0)             := (others => '0');
    signal d_fir_shf :  signed(17 downto 0)             := (others => '0');
    signal d_fir_res :  std_logic_vector(15 downto 0)   := (others => '0');
    signal D_DC_o    :  std_logic_vector(15 downto 0)   := (others => '0');
   
begin

fir_stage: fir_dec_8
    port map(
       clk_i        => clk_i,
       clk_enable   => '1',
       nrst         => nrst,
       D_in         => D_in,
       D_out        => d_fir_out
    );
    
    d_fir_red   <= signed(d_fir_out(26 downto 9));
    d_fir_shf   <= shift_right(d_fir_red, 2);
    
    output_buff: process(clk_d, nrst)
    begin
        if (nrst = '0') then
            d_fir_res <= (others => '0');
        elsif (rising_edge(clk_d)) then
            d_fir_res  <= std_logic_vector(d_fir_shf(15 downto 0));
        end if;
    end process;
    
    DEC:    process(clk_i)
    begin
        if (nrst = '0') then
            clk_d   <= '0';
            count   <= 0;
        elsif (rising_edge(clk_i)) then
            if (count = (8-1)) then
                count   <= 0;
                clk_d   <= '0';
             elsif (count = (8/2-1)) then
                count   <= count+1;
                clk_d   <= '1';
             else
                count   <= count+1;
             end if;
        end if;
    end process;
    
    DC_block_stage: dc_blocker
    generic map(
        BIN_width   => 16,
        FIXED_LEN   => 9,
        GAIN        => 3
    )
    port map(
        clk     => clk_d,
        nrst    => nrst,
        D_in    => d_fir_res,
        D_out   => D_DC_o
    );
    
    
    
    D_out <= D_DC_o;
    
    clk_o <= clk_d;

end Behavioral;
