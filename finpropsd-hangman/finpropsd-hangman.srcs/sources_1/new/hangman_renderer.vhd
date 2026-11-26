library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hangman_pkg.all;
use work.font5x7_pkg.all;

entity hangman_renderer is
    port (
        px_x         : in  integer range 0 to 799;
        px_y         : in  integer range 0 to 524;
        vde          : in  std_logic;
        word_idx     : in  integer range 0 to NUM_WORDS - 1;
        cursor_idx   : in  letter_idx_t;
        guessed_mask : in  std_logic_vector(25 downto 0);
        wrong_count  : in  integer range 0 to MAX_WRONG;
        score        : in  integer range 0 to 999;
        game_state   : in  game_state_t;
        rgb_r        : out std_logic_vector(7 downto 0);
        rgb_g        : out std_logic_vector(7 downto 0);
        rgb_b        : out std_logic_vector(7 downto 0)
    );
end entity hangman_renderer;

architecture rtl of hangman_renderer is
    type code_arr6_t is array (0 to 5) of font_code_t;
    type code_arr7_t is array (0 to 6) of font_code_t;
    type code_arr9_t is array (0 to 8) of font_code_t;
    type wrong_arr_t is array (0 to MAX_WRONG - 1) of font_code_t;

 
    constant TITLE_STR : code_arr7_t := (7, 0, 13, 6, 12, 0, 13);
    constant SCORE_LBL : code_arr6_t := (18, 2, 14, 17, 4, CH_COLON);
    constant WRONG_LBL : code_arr6_t := (22, 17, 14, 13, 6, CH_COLON);
    constant WIN_STR   : code_arr9_t := (24, 14, 20, CH_SPACE, 22, 8, 13, CH_EXCL, CH_SPACE);
    constant LOSE_STR  : code_arr9_t := (6, 0, 12, 4, CH_SPACE, 14, 21, 4, 17);

    function is_in_word(entry : word_entry_t; ltr : letter_idx_t) return boolean is
    begin
        for i in 0 to MAX_WORD_LEN - 1 loop
            if i < entry.len and entry.letters(i) = ltr then
                return true;
            end if;
        end loop;
        return false;
    end function is_in_word;
begin

    process(all)
        variable r, g, b    : std_logic_vector(7 downto 0);
        variable cur_entry  : word_entry_t;
        variable wrong_list : wrong_arr_t;
        variable w_cnt      : integer range 0 to MAX_WRONG;
        variable dx, dy     : integer;
        variable dist_sq    : integer;
        variable char_idx   : integer;
        variable local_x    : integer;
        variable local_y    : integer;
        variable f_col      : integer range 0 to 4;
        variable f_row      : integer range 0 to 6;
        variable f_code     : font_code_t;
        variable grid_row   : integer range 0 to 1;
        variable grid_col   : integer range 0 to 12;
        variable ltr_idx    : letter_idx_t;
        variable revealed   : boolean;
        variable d_hun      : integer range 0 to 9;
        variable d_ten      : integer range 0 to 9;
        variable d_one      : integer range 0 to 9;
    begin
        r := x"14";
        g := x"1B";
        b := x"2D";

        cur_entry := WORD_DICT(word_idx);

        wrong_list := (others => CH_SPACE);
        w_cnt      := 0;
        for i in 0 to 25 loop
            if guessed_mask(i) = '1' and not is_in_word(cur_entry, i) then
                if w_cnt < MAX_WRONG then
                    wrong_list(w_cnt) := i;
                    w_cnt             := w_cnt + 1;
                end if;
            end if;
        end loop;

        if vde = '0' then
            r := x"00";
            g := x"00";
            b := x"00";
        else
            -- =================================================================
            -- 1. JUDUL "HANGMAN" (x: 236..403, y: 20..47, 7 huruf x 24px)
            -- =================================================================
            if (px_x >= 236 and px_x < 404) and (px_y >= 20 and px_y < 48) then
                char_idx := (px_x - 236) / 24;
                local_x  := (px_x - 236) mod 24;
                local_y  := px_y - 20;
                if local_x < 20 then
                    f_col := local_x / 4;
                    f_row := local_y / 4;
                    if font_pixel(TITLE_STR(char_idx), f_col, f_row) = '1' then
                        r := x"38";
                        g := x"BD";
                        b := x"F8"; -- Cyan terang
                    end if;
                end if;
            end if;

            if (px_x >= 458 and px_x < 620) and (px_y >= 24 and px_y < 45) then
                char_idx := (px_x - 458) / 18;
                local_x  := (px_x - 458) mod 18;
                local_y  := px_y - 24;
                if local_x < 15 then
                    f_col := local_x / 3;
                    f_row := local_y / 3;
                    d_hun := score / 100;
                    d_ten := (score / 10) mod 10;
                    d_one := score mod 10;

                    if char_idx < 6 then
                        f_code := SCORE_LBL(char_idx);
                    elsif char_idx = 6 then
                        f_code := CH_ZERO + d_hun;
                    elsif char_idx = 7 then
                        f_code := CH_ZERO + d_ten;
                    else
                        f_code := CH_ZERO + d_one;
                    end if;

                    if font_pixel(f_code, f_col, f_row) = '1' then
                        r := x"FA";
                        g := x"CC";
                        b := x"15"; 
                    end if;
                end if;
            end if;

            if ((px_x >= 70 and px_x <= 200) and (px_y >= 285 and px_y <= 295)) or
               ((px_x >= 100 and px_x <= 110) and (px_y >= 90 and px_y <= 285)) or
               ((px_x >= 100 and px_x <= 185) and (px_y >= 90 and px_y <= 100)) or
               ((px_x >= 180 and px_x <= 184) and (px_y >= 100 and px_y <= 130))
            then
                r := x"CB";
                g := x"D5";
                b := x"E1";
            end if;

            if wrong_count >= 1 then
                dx      := px_x - 182;
                dy      := px_y - 148;
                dist_sq := dx * dx + dy * dy;
                if dist_sq >= 196 and dist_sq <= 324 then
                    r := x"F8"; g := x"71"; b := x"71";
                end if;
            end if;

            if wrong_count >= 2 then
                if (px_x >= 180 and px_x <= 184) and (px_y >= 166 and px_y <= 225) then
                    r := x"F8"; g := x"71"; b := x"71";
                end if;
            end if;

            if wrong_count >= 3 then
                if (px_x >= 155 and px_x <= 180) and (px_y >= 176 and px_y <= 205) then
                    if abs((px_y - 178) - (180 - px_x)) <= 2 then
                        r := x"F8"; g := x"71"; b := x"71";
                    end if;
                end if;
            end if;

            if wrong_count >= 4 then
                if (px_x >= 184 and px_x <= 209) and (px_y >= 176 and px_y <= 205) then
                    if abs((px_y - 178) - (px_x - 184)) <= 2 then
                        r := x"F8"; g := x"71"; b := x"71";
                    end if;
                end if;
            end if;

            if wrong_count >= 5 then
                if (px_x >= 155 and px_x <= 180) and (px_y >= 223 and px_y <= 252) then
                    if abs((px_y - 225) - (180 - px_x)) <= 2 then
                        r := x"F8"; g := x"71"; b := x"71";
                    end if;
                end if;
            end if;

            if wrong_count >= 6 then
                if (px_x >= 184 and px_x <= 209) and (px_y >= 223 and px_y <= 252) then
                    if abs((px_y - 225) - (px_x - 184)) <= 2 then
                        r := x"F8"; g := x"71"; b := x"71";
                    end if;
                end if;
            end if;

            if (px_x >= 240 and px_x < 240 + cur_entry.len * 24) and
               (px_y >= 120 and px_y < 160)
            then
                char_idx := (px_x - 240) / 24;
                local_x  := (px_x - 240) mod 24;
                local_y  := px_y - 120;

                if (local_x >= 2 and local_x < 21) and (local_y >= 32 and local_y < 36) then
                    r := x"94"; g := x"A3"; b := x"B8";
                end if;

                if (local_x >= 4 and local_x < 19) and (local_y >= 8 and local_y < 29) then
                    revealed := (guessed_mask(cur_entry.letters(char_idx)) = '1') or (game_state = ST_LOSE);
                    if revealed then
                        f_code := cur_entry.letters(char_idx);
                        f_col  := (local_x - 4) / 3;
                        f_row  := (local_y - 8) / 3;
                        if font_pixel(f_code, f_col, f_row) = '1' then
                            if guessed_mask(cur_entry.letters(char_idx)) = '1' then
                                r := x"FF"; g := x"FF"; b := x"FF";
                            else
                                r := x"FB"; g := x"71"; b := x"85";
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if (px_x >= 240 and px_x < 474) and (px_y >= 175 and px_y < 196) then
                char_idx := (px_x - 240) / 18;
                local_x  := (px_x - 240) mod 18;
                local_y  := px_y - 175;
                if local_x < 15 then
                    f_col := local_x / 3;
                    f_row := local_y / 3;
                    if char_idx < 6 then
                        f_code := WRONG_LBL(char_idx);
                        if font_pixel(f_code, f_col, f_row) = '1' then
                            r := x"94"; g := x"A3"; b := x"B8";
                        end if;
                    elsif char_idx = 6 then
                        f_code := CH_SPACE;
                    else
                        f_code := wrong_list(char_idx - 7);
                        if font_pixel(f_code, f_col, f_row) = '1' then
                            r := x"F8"; g := x"71"; b := x"71";
                        end if;
                    end if;
                end if;
            end if;

            if game_state /= ST_PLAYING then
                if (px_x >= 312 and px_x < 528) and (px_y >= 225 and px_y < 253) then
                    char_idx := (px_x - 312) / 24;
                    local_x  := (px_x - 312) mod 24;
                    local_y  := px_y - 225;
                    if local_x < 20 then
                        f_col := local_x / 4;
                        f_row := local_y / 4;
                        if game_state = ST_WIN then
                            f_code := WIN_STR(char_idx);
                            if font_pixel(f_code, f_col, f_row) = '1' then
                                r := x"4A"; g := x"DE"; b := x"80";
                            end if;
                        else
                            f_code := LOSE_STR(char_idx);
                            if font_pixel(f_code, f_col, f_row) = '1' then
                                r := x"EF"; g := x"44"; b := x"44";
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if (px_x >= 112 and px_x < 528) and
               ((px_y >= 336 and px_y < 376) or (px_y >= 384 and px_y < 424))
            then
                grid_col := (px_x - 112) / 32;
                local_x  := (px_x - 112) mod 32;
                if px_y < 376 then
                    grid_row := 0;
                    local_y  := px_y - 336;
                else
                    grid_row := 1;
                    local_y  := px_y - 384;
                end if;

                ltr_idx := grid_row * 13 + grid_col;

                if ltr_idx = cursor_idx and game_state = ST_PLAYING then
                    if local_x < 2 or local_x >= 30 or local_y < 2 or local_y >= 38 then
                        r := x"FA"; g := x"CC"; b := x"15";
                    else
                        r := x"33"; g := x"41"; b := x"55";
                    end if;
                end if;

                if (local_x >= 6 and local_x < 26) and (local_y >= 6 and local_y < 34) then
                    f_col := (local_x - 6) / 4;
                    f_row := (local_y - 6) / 4;
                    if font_pixel(ltr_idx, f_col, f_row) = '1' then
                        if guessed_mask(ltr_idx) = '1' then
                            if is_in_word(cur_entry, ltr_idx) then
                                r := x"4A"; g := x"DE"; b := x"80";
                            else
                                r := x"99"; g := x"1B"; b := x"1B";
                            end if;
                        elsif ltr_idx = cursor_idx and game_state = ST_PLAYING then
                            r := x"FA"; g := x"CC"; b := x"15";
                        else
                            r := x"E2"; g := x"E8"; b := x"F0";
                        end if;
                    end if;
                end if;
            end if;
        end if;

        rgb_r <= r;
        rgb_g <= g;
        rgb_b <= b;
    end process;

end architecture rtl;
