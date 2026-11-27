library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.hangman_pkg.all;

entity tb_hangman is
end entity tb_hangman;

architecture sim of tb_hangman is
    constant CLK_PERIOD : time := 40 ns; 

    signal clk           : std_logic := '0';
    signal rst           : std_logic := '1';
    signal breadboard_sw : std_logic := '1'; 

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

    signal capture_en    : boolean := false;
    signal capture_done  : boolean := false;
begin

    clk <= not clk after CLK_PERIOD / 2 when not capture_done else '0';

    u_btn : entity work.button_1key_ctrl
        generic map (
            CLK_FREQ_HZ   => 10_000,
            DEBOUNCE_MS   => 1,      
            LONG_PRESS_MS => 5,   
            ACTIVE_LOW    => true
        )
        port map (
            clk           => clk,
            rst           => rst,
            btn_raw       => breadboard_sw,
            shuffle_pulse => shuffle_pulse,
            confirm_pulse => confirm_pulse,
            btn_held      => btn_held
        );

    u_fsm : entity work.hangman_fsm
        port map (
            clk           => clk,
            rst           => rst,
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
            pclk  => clk,
            rst   => rst,
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

    p_stim : process
        procedure short_press is
        begin
            breadboard_sw <= '0'; 
            for i in 1 to 25 loop
                wait until rising_edge(clk);
            end loop;
            breadboard_sw <= '1'; 
            for i in 1 to 25 loop
                wait until rising_edge(clk);
            end loop;
        end procedure;

        procedure long_press is
        begin
            breadboard_sw <= '0'; 
            for i in 1 to 80 loop
                wait until rising_edge(clk);
            end loop;
            breadboard_sw <= '1'; 
            for i in 1 to 25 loop
                wait until rising_edge(clk);
            end loop;
        end procedure;
    begin
        rst <= '1';
        for i in 1 to 10 loop
            wait until rising_edge(clk);
        end loop;
        rst <= '0';
        for i in 1 to 10 loop
            wait until rising_edge(clk);
        end loop;

        long_press;
        assert wrong_count = 1
            report "Harusnya wrong_count = 1 setelah menebak A" severity error;

        for k in 1 to 15 loop
            short_press;
        end loop;
        assert cursor_idx = 15
            report "Harusnya cursor_idx = 15 (huruf P)" severity error;
        long_press;
        assert guessed_mask(15) = '1' and wrong_count = 1
            report "Harusnya huruf P tertebak benar" severity error;

        for k in 1 to 9 loop
            short_press;
        end loop;
        long_press;

        report "Simulasi input selesai! Mulai merekam 1 frame 640x480 ke hangman_frame.ppm...";
        capture_en <= true;

        wait until capture_done;
        report "Selesai! File hangman_frame.ppm berhasil dibuat." severity note;
        wait;
    end process;

    p_capture : process
        file img_file : text;
        variable l    : line;
    begin
        wait until capture_en;

        wait until rising_edge(clk) and px_x = 0 and px_y = 0;

        file_open(img_file, "hangman_frame.ppm", write_mode);
        write(l, string'("P3"));
        writeline(img_file, l);
        write(l, string'("640 480"));
        writeline(img_file, l);
        write(l, string'("255"));
        writeline(img_file, l);

        for y in 0 to 479 loop
            for x in 0 to 639 loop
                write(l, integer'image(to_integer(unsigned(rgb_r))) & " " &
                         integer'image(to_integer(unsigned(rgb_g))) & " " &
                         integer'image(to_integer(unsigned(rgb_b))));
                writeline(img_file, l);
                wait until rising_edge(clk);
            end loop;
            
            if y < 479 then
                wait until rising_edge(clk) and px_x = 0 and px_y = y + 1;
            end if;
        end loop;

        file_close(img_file);
        capture_done <= true;
        wait;
    end process;

end architecture sim;
