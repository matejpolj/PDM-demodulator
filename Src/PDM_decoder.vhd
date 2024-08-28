----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 18.03.2024 18:47:06
-- Design Name: 
-- Module Name: PDM_decoder - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PDM_decoder is
    Generic (   BIN_width : integer := 1;       -- input size register 
                BOUT_width :integer := 16;      -- output size register 
                M :         integer := 3;       -- number of integer and comb stages
                R :         integer := 8;       -- decimation factor
                N :         integer := 2;       -- diferential delay
                NUM_COEF :  integer := 14;      -- number of coeficients in halfband filters
                FIXED_LEN : integer := 5;       -- length of fixed point for multiplication
                RH :        integer := 2);      -- decimation factor 
    Port (      clk_i : in STD_LOGIC;
                clk_o : out STD_LOGIC;
                nrst :  in STD_LOGIC;
                D_in :  in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
                D_out : out STD_LOGIC_VECTOR (BOUT_width-1 downto 0));
end PDM_decoder;

architecture cic_hbfx3 of PDM_decoder is

    component cic_filter is
        Generic (   BIN_width : integer := 1;       -- input size register 
                    BOUT_width :integer := 10;      -- output size register 
                    M :         integer := 3;       -- number of integer and comb stages
                    R :         integer := 8;       -- recimation factor
                    N :         integer := 2);      -- diferential delay
        Port (      clk_i : in STD_LOGIC;
                    clk_o : out STD_LOGIC;
                    nrst :  in STD_LOGIC;
                    D_in :  in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
                    D_out : out STD_LOGIC_VECTOR (BOUT_width-1 downto 0));
    end component;
    
    component halfband_filter is
        Generic (   BIN_width : integer := 10;
                    NUM_COEF :  integer := 12;
                    FIXED_LEN : integer := 5;
                    R :         integer := 2);
        Port ( clk_i : in STD_LOGIC;
               nrst : in STD_LOGIC;
               clk_o : out STD_LOGIC;
               D_in : in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
               D_out : out STD_LOGIC_VECTOR (BIN_width-1 downto 0));
    end component;
    
    component dc_blocker is
        Generic (   BIN_width : integer := 10;
                    FIXED_LEN : integer := 9;
                    GAIN      : integer := 3);
        Port ( clk : in STD_LOGIC;
               nrst : in STD_LOGIC;
               D_in : in STD_LOGIC_VECTOR (15 downto 0);
               D_out : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    signal clk_o_cic :  std_logic   := '0';
    signal clk_o_HB1 :  std_logic   := '0';
    signal clk_o_HB2 :  std_logic   := '0';
    signal clk_o_HB3 :  std_logic   := '0';
    
    signal D_cic_o :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    signal D_HB1_o :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    signal D_HB2_o :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    signal D_HB3_o :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    signal D_DC_o  :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    
    
begin

CIC_stage: cic_filter
    generic map(
        BIN_width   => BIN_width,
        BOUT_width  => BOUT_width,
        M           => M,
        R           => R,
        N           => N
    )
    port map(
       clk_i    => clk_i,
       clk_o    => clk_o_cic,
       nrst     => nrst,
       D_in     => D_in,
       D_out    => D_cic_o
    );
    
    HB_stage_1: entity work.halfband_filter(folded)
    generic map(
        BIN_width   => BOUT_width,
        NUM_COEF    => NUM_COEF,
        FIXED_LEN   => FIXED_LEN,
        R           => RH
    )
    port map(
       clk_i    => clk_o_cic,
       clk_o    => clk_o_HB1,
       nrst     => nrst,
       D_in     => D_cic_o,
       D_out    => D_HB1_o
    );

    HB_stage_2: entity work.halfband_filter(folded)
    generic map(
        BIN_width   => BOUT_width,
        NUM_COEF    => NUM_COEF,
        FIXED_LEN   => FIXED_LEN,
        R           => RH
    )
    port map(
       clk_i    => clk_o_HB1,
       clk_o    => clk_o_HB2,
       nrst     => nrst,
       D_in     => D_HB1_o,
       D_out    => D_HB2_o
    );

    HB_stage_3: entity work.halfband_filter(folded)
    generic map(
        BIN_width   => BOUT_width,
        NUM_COEF    => NUM_COEF,
        FIXED_LEN   => FIXED_LEN,
        R           => RH
    )
    port map(
       clk_i    => clk_o_HB2,
       clk_o    => clk_o_HB3,
       nrst     => nrst,
       D_in     => D_HB2_o,
       D_out    => D_HB3_o
    );
    
    DC_block_stage: dc_blocker
    generic map(
        BIN_width   => BOUT_width,
        FIXED_LEN   => 9,
        GAIN        => 3
    )
    port map(
        clk     => clk_o_HB3,
        nrst    => nrst,
        D_in    => D_HB3_o,
        D_out   => D_DC_o
    );
        
    
    clk_o <= clk_o_HB3;
    D_out <= D_DC_o;
    
    
end cic_hbfx3;

--architecture cic_fir_dec of PDM_decoder is

--    component cic_filter is
--        Generic (   BIN_width : integer := 1;       -- input size register 
--                    BOUT_width :integer := 10;      -- output size register 
--                    M :         integer := 3;       -- number of integer and comb stages
--                    R :         integer := 8;       -- recimation factor
--                    N :         integer := 2);      -- diferential delay
--        Port (      clk_i : in STD_LOGIC;
--                    clk_o : out STD_LOGIC;
--                    nrst :  in STD_LOGIC;
--                    D_in :  in STD_LOGIC_VECTOR (BIN_width-1 downto 0);
--                    D_out : out STD_LOGIC_VECTOR (BOUT_width-1 downto 0));
--    end component;
    
--    component fir_dec is
--        Port ( clk_i : in STD_LOGIC;
--               nrst : in STD_LOGIC;
--               D_in : in STD_LOGIC_VECTOR (15 downto 0);
--               D_out : out STD_LOGIC_VECTOR (15 downto 0);
--               clk_o : out STD_LOGIC);
--    end component;
    
--    signal clk_o_cic :  std_logic   := '0';
--    signal clk_o_fir :  std_logic   := '0';
    
--    signal D_cic_o :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
--    signal D_fir_o :    std_logic_vector(BOUT_width-1 downto 0) := (others => '0');
    
    
--begin

--CIC_stage: cic_filter
--    generic map(
--        BIN_width   => BIN_width,
--        BOUT_width  => BOUT_width,
--        M           => M,
--        R           => R,
--        N           => N
--    )
--    port map(
--       clk_i    => clk_i,
--       clk_o    => clk_o_cic,
--       nrst     => nrst,
--       D_in     => D_in,
--       D_out    => D_cic_o
--    );
    
--fir_dec_stage: fir_dec
--    port map(
--       clk_i    => clk_o_cic,
--       clk_o    => clk_o_fir,
--       nrst     => nrst,
--       D_in     => D_cic_o,
--       D_out    => D_fir_o
--    );
        

--    clk_o <= clk_o_fir;
--    D_out <= D_fir_o;


--end cic_fir_dec; 

