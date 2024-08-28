----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11.03.2024 19:20:48
-- Design Name: 
-- Module Name: halfband_filter - Behavioral
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

--use ieee.fixed_float_types.all;
--use ieee.fixed_pkg.all;

entity halfband_filter is
    Generic (   BIN_width : integer := 10;
                NUM_COEF :  integer := 12;
                FIXED_LEN : integer := 5;
                R :         integer := 2);
    Port ( clk_i : in STD_LOGIC;
           nrst : in STD_LOGIC;
           clk_o : out STD_LOGIC;
           D_in : in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
           D_out : out STD_LOGIC_VECTOR (BIN_width-1 downto 0));
end halfband_filter;

architecture regular of halfband_filter is
    
    signal  clk_d   : std_logic                     := '0';
    signal  count   : integer range 0 to (R-1)      := 0;
    
    subtype FIXED_T is   signed(BIN_width-1+FIXED_LEN downto 0);
    subtype MULT_T  is   signed(BIN_width*2-1+FIXED_LEN*2 downto 0);
    type COEF_ARRAY is array (0 to NUM_COEF/2) of FIXED_T;
    type BUFF_ARRAY is array (0 to NUM_COEF) of MULT_T;
    type MULT_ARRAY is array (0 to NUM_COEF) of MULT_T;
    
    constant coeficients: COEF_ARRAY := (b"000000000000000000000",
                                        b"000000000000000000000",
                                        b"000000000000000000001",
                                        b"000000000000000000000",
                                        b"111111111111111111110",
                                        b"000000000000000000000",
                                        b"000000000000000001010",
                                        b"000000000000000010000");
    signal store_buffer : BUFF_ARRAY := (others => (others => '0'));
    signal mult_buffer  : MULT_ARRAY := (others => (others => '0'));
    
    signal input        : FIXED_T := (others => '0');
    signal output       : std_logic_vector(BIN_width*2-1+FIXED_LEN*2 downto 0);
    
    constant filler     : std_logic_vector(FIXED_LEN-1 downto 0) := (others => '0');
    
begin
    
    input <= signed(D_in&filler);
    
    mult_proc: process(input)
    begin
        for ll in 0 to NUM_COEF/2 loop
            mult_buffer(ll)    <= input*coeficients(ll);
        end loop;
        for ll in NUM_COEF/2+1 to NUM_COEF loop
            mult_buffer(ll)    <= input*coeficients(ll-(NUM_COEF/2+1));
        end loop;
    end process;
    
    sum_proc: process(clk_i, nrst)
    begin
        if (nrst = '0') then
            store_buffer <= (others => (others => '0'));
        elsif (rising_edge(clk_i)) then
            for kk in 0 to NUM_COEF-1 loop
                store_buffer(kk) <= mult_buffer(kk)+store_buffer(kk+1);
            end loop;
            store_buffer(NUM_COEF) <= mult_buffer(NUM_COEF);
        end if;
    end process;
    

    decimator: process(clk_i, nrst)
    begin
        if (nrst = '0') then
            clk_d   <= '0';
            count   <= 0;
        elsif (rising_edge(clk_i)) then
            if (count = (R-1)) then
                count   <= 0;
                clk_d   <= '0';
             elsif (count = (R/2-1)) then
                count   <= count+1;
                clk_d   <= '1';
             else
                count   <= count+1;
             end if;
        end if;
    end process;
   
    output_buff: process(clk_d, nrst)
    begin
        if (nrst = '0') then
            output <= (others => '0');
        elsif (rising_edge(clk_d)) then
            output  <= std_logic_vector(store_buffer(0));
        end if;
    end process;
   
    
    clk_o   <= clk_d;
    D_out   <= output(BIN_WIDTH-1+FIXED_LEN*2 downto FIXED_LEN*2);

end regular;

architecture folded of halfband_filter is
    
    signal  clk_d   : std_logic                     := '0';
    signal  count   : integer range 0 to (R-1)      := 0;
    
    subtype FIXED_T is   signed(BIN_width-1+FIXED_LEN downto 0);
    subtype MULT_T  is   signed(BIN_width*2-1+FIXED_LEN*2 downto 0);
    type COEF_ARRAY is array (0 to NUM_COEF/2) of FIXED_T;
    type BUFF_ARRAY is array (0 to NUM_COEF) of MULT_T;
    type MULT_ARRAY is array (0 to NUM_COEF) of MULT_T;
    
    --   111111111111111111110   000000000000000000000   000000000000000000010   000000000000000000000   111111111111111111101   000000000000000000000   000000000000000001010   000000000000000010000   000000000000000001010   000000000000000000000   111111111111111111101   000000000000000000000   000000000000000000010   000000000000000000000   111111111111111111110'
    constant coeficients: COEF_ARRAY := (b"111111111111111111110",
                                        b"000000000000000000000",
                                        b"000000000000000000010",
                                        b"000000000000000000000",
                                        b"111111111111111111101",
                                        b"000000000000000000000",
                                        b"000000000000000001010",
                                        b"000000000000000010000");
                                        
--                                        000000000000000000000",
--                                        b"000000000000000000000",
--                                        b"000000000000000000001",
--                                        b"000000000000000000000",
--                                        b"111111111111111111110",
--                                        b"000000000000000000000",
--                                        b"000000000000000001010",
--                                        b"000000000000000010000");
    signal store_buffer : BUFF_ARRAY := (others => (others => '0'));
    signal mult_buffer  : MULT_ARRAY := (others => (others => '0'));
    
    signal input        : FIXED_T := (others => '0');
    signal output       : std_logic_vector(BIN_width*2-1+FIXED_LEN*2 downto 0);
    
    constant filler     : std_logic_vector(FIXED_LEN-1 downto 0) := (others => '0');
    
begin
    
    input <= signed(D_in&filler);
    
    mult_proc: process(input)
    begin
        for ll in 0 to NUM_COEF/2 loop
            mult_buffer(ll)    <= input*coeficients(ll);
        end loop;
--        for ll in NUM_COEF/2+1 to NUM_COEF loop
--            mult_buffer(ll)    <= input*coeficients(ll-(NUM_COEF/2+1));
--        end loop;
    end process;
    
    sum_proc: process(clk_i, nrst)
    begin
        if (nrst = '0') then
            store_buffer <= (others => (others => '0'));
        elsif (rising_edge(clk_i)) then
            for kk in 0 to NUM_COEF/2 loop
                store_buffer(kk) <= mult_buffer(NUM_COEF/2-kk)+store_buffer(kk+1);
            end loop;
            for kk in NUM_COEF/2+1 to NUM_COEF-1 loop
                store_buffer(kk) <= mult_buffer(kk)+store_buffer(kk+1);
            end loop;
            store_buffer(NUM_COEF) <= mult_buffer(NUM_COEF);
        end if;
    end process;
    

    decimator: process(clk_i, nrst)
    begin
        if (nrst = '0') then
            clk_d   <= '0';
            count   <= 0;
        elsif (rising_edge(clk_i)) then
            if (count = (R-1)) then
                count   <= 0;
                clk_d   <= '0';
             elsif (count = (R/2-1)) then
                count   <= count+1;
                clk_d   <= '1';
             else
                count   <= count+1;
             end if;
        end if;
    end process;
   
    output_buff: process(clk_d, nrst)
    begin
        if (nrst = '0') then
            output <= (others => '0');
        elsif (rising_edge(clk_d)) then
            output  <= std_logic_vector(store_buffer(0));         
        end if;
    end process;
   
    
    clk_o   <= clk_d;
    D_out   <= output(BIN_WIDTH-1+FIXED_LEN*2 downto FIXED_LEN*2);

end folded;

