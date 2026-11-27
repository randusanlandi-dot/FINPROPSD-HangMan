library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.hangman_pkg.all;

entity hangman_top is
    port (
        sysclk        : in  std_logic;                    
        rst_btn       : in  std_logic;                    
        breadboard_sw : in  std_logic;                    
        led           : out std_logic_vector(3 downto 0); 
        hdmi_tx_clk_p : out std_logic;
        hdmi_tx_clk_n : out std_logic;
        hdmi_tx_p     : out std_logic_vector(2 downto 0);
        hdmi_tx_n     : out std_logic_vector(2 downto 0)
    );
end entity hangman_top;

architecture rtl of hangman_top is
    component rgb2dvi is
        generic (
            kGenerateSerialClk : boolean := false;
            kClkPrimitive      : string  := "PLL";
            kClkRange          : natural := 3;
            kRstActiveHigh     : boolean := true;
            kD0Swap            : boolean := false;
            kD1Swap            : boolean := false;
            kD2Swap            : boolean := false;
            kClkSwap           : boolean := false
        );
        port (
            TMDS_Clk_p  : out std_logic;
            TMDS_Clk_n  : out std_logic;
            TMDS_Data_p : out std_logic_vector(2 downto 0);
            TMDS_Data_n : out std_logic_vector(2 downto 0);
            aRst        : in  std_logic;
            aRst_n      : in  std_logic;
            vid_pData   : in  std_logic_vector(23 downto 0); 
            vid_pVDE    : in  std_logic;
            vid_pHSync  : in  std_logic;
            vid_pVSync  : in  std_logic;
            PixelClk    : in  std_logic;
            SerialClk   : in  std_logic
        );
    end component rgb2dvi;

    signal clk_fb       : std_logic;
    signal pclk_unbuf   : std_logic;
    signal sclk_unbuf   : std_logic;
    signal pixel_clk    : std_logic;
    signal serial_clk   : std_logic;
    signal pll_locked   : std_logic;
    signal sys_rst      : std_logic;
    signal sys_rst_n    : std_logic;

    signal shuffle_pulse : std_logic;
    signal confirm_pulse : std_logic;
    signal btn_held      : std_logic;

    signal word_idx      : integer range 0 to NUM_WORDS - 1;
    signal cursor_idx    : letter_idx_t;
    signal guessed_mask  : std_logic_vector(25 downto 0);
    signal wrong_count   : integer range 0 to MAX_WRONG;
    signal score         : integer range 0 to 999;
    signal game_state    : game_state_t;

    signal hsync         : std_logic;
    signal vsync         : std_logic;
    signal vde           : std_logic;
    signal px_x          : integer range 0 to 799;
    signal px_y          : integer range 0 to 524;
    signal rgb_r         : std_logic_vector(7 downto 0);
    signal rgb_g         : std_logic_vector(7 downto 0);
    signal rgb_b         : std_logic_vector(7 downto 0);
    signal vid_pData_rbg : std_logic_vector(23 downto 0);

begin
    u_pll : PLLE2_BASE
        generic map (
            BANDWIDTH          => "OPTIMIZED",
            CLKFBOUT_MULT      => 8,       
            CLKIN1_PERIOD      => 8.0,    
            CLKOUT0_DIVIDE     => 40,    
            CLKOUT1_DIVIDE     => 8,       
            DIVCLK_DIVIDE      => 1
        )
        port map (
            CLKOUT0  => pclk_unbuf,
            CLKOUT1  => sclk_unbuf,
            CLKOUT2  => open,
            CLKOUT3  => open,
            CLKOUT4  => open,
            CLKOUT5  => open,
            CLKFBOUT => clk_fb,
            LOCKED   => pll_locked,
            CLKIN1   => sysclk,
            PWRDWN   => '0',
            RST      => rst_btn,
            CLKFBIN  => clk_fb
        );

    u_bufg_pclk : BUFG port map (I => pclk_unbuf, O => pixel_clk);
    u_bufg_sclk : BUFG port map (I => sclk_unbuf, O => serial_clk);

    sys_rst   <= rst_btn or (not pll_locked);
    sys_rst_n <= not sys_rst;

    u_btn : entity work.button_1key_ctrl
        generic map (
            CLK_FREQ_HZ   => 25_000_000,
            DEBOUNCE_MS   => 20,
            LONG_PRESS_MS => 700,
            ACTIVE_LOW    => true  
        )
        port map (
            clk           => pixel_clk,
            rst           => sys_rst,
            btn_raw       => breadboard_sw,
            shuffle_pulse => shuffle_pulse,
            confirm_pulse => confirm_pulse,
            btn_held      => btn_held
        );

    u_fsm : entity work.hangman_fsm
        port map (
            clk           => pixel_clk,
            rst           => sys_rst,
            shuffle_pulse => shuffle_pulse,
            confirm_pulse => confirm_pulse,
            word_idx      => word_idx,
            cursor_idx    => cursor_idx,
            guessed_mask  => guessed_mask,
            wrong_count   => wrong_count,
            score         => score,
            game_state    => game_state
        );

    u_timing : entity work.vga_timing_640x480
        port map (
            pclk  => pixel_clk,
            rst   => sys_rst,
            hsync => hsync,
            vsync => vsync,
            vde   => vde,
            px_x  => px_x,
            px_y  => px_y
        );

    u_render : entity work.hangman_renderer
        port map (
            px_x         => px_x,
            px_y         => px_y,
            vde          => vde,
            word_idx     => word_idx,
            cursor_idx   => cursor_idx,
            guessed_mask => guessed_mask,
            wrong_count  => wrong_count,
            score        => score,
            game_state   => game_state,
            rgb_r        => rgb_r,
            rgb_g        => rgb_g,
            rgb_b        => rgb_b
        );

    u_rgb2dvi : rgb2dvi
        generic map (
            kGenerateSerialClk => false, 
            kClkPrimitive      => "PLL",
            kClkRange          => 3,
            kRstActiveHigh     => true
        )
        port map (
            TMDS_Clk_p  => hdmi_tx_clk_p,
            TMDS_Clk_n  => hdmi_tx_clk_n,
            TMDS_Data_p => hdmi_tx_p,
            TMDS_Data_n => hdmi_tx_n,
            aRst        => sys_rst,
            aRst_n      => sys_rst_n,
            vid_pData   => vid_pData_rbg,
            vid_pVDE    => vde,
            vid_pHSync  => hsync,
            vid_pVSync  => vsync,
            PixelClk    => pixel_clk,
            SerialClk   => serial_clk
        );

    led(0) <= btn_held;
    led(1) <= '1' when game_state = ST_WIN else '0';
    led(2) <= '1' when game_state = ST_LOSE else '0';
    led(3) <= pll_locked;

end architecture rtl;
