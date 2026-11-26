library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hangman_pkg.all;

entity hangman_fsm is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        shuffle_pulse : in  std_logic;
        confirm_pulse : in  std_logic;
        word_idx      : out integer range 0 to NUM_WORDS - 1;
        cursor_idx    : out letter_idx_t;
        guessed_mask  : out std_logic_vector(25 downto 0);
        wrong_count   : out integer range 0 to MAX_WRONG;
        score         : out integer range 0 to 999;
        game_state    : out game_state_t
    );
end entity hangman_fsm;

architecture rtl of hangman_fsm is
    signal s_word_idx     : integer range 0 to NUM_WORDS - 1 := 0;
    signal s_cursor_idx   : letter_idx_t := 0;
    signal s_guessed_mask : std_logic_vector(25 downto 0) := (others => '0');
    signal s_wrong_count  : integer range 0 to MAX_WRONG := 0;
    signal s_score        : integer range 0 to 999 := 0;
    signal s_game_state   : game_state_t := ST_PLAYING;
begin

    word_idx     <= s_word_idx;
    cursor_idx   <= s_cursor_idx;
    guessed_mask <= s_guessed_mask;
    wrong_count  <= s_wrong_count;
    score        <= s_score;
    game_state   <= s_game_state;

    process(clk)
        variable cur_entry     : word_entry_t;
        variable letter_found  : boolean;
        variable all_revealed  : boolean;
        variable next_mask     : std_logic_vector(25 downto 0);
        variable next_wrong    : integer range 0 to MAX_WRONG;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                s_word_idx     <= 0;
                s_cursor_idx   <= 0;
                s_guessed_mask <= (others => '0');
                s_wrong_count  <= 0;
                s_score        <= 0;
                s_game_state   <= ST_PLAYING;
            else
                cur_entry := WORD_DICT(s_word_idx);

                case s_game_state is
                    when ST_PLAYING =>
                        if shuffle_pulse = '1' then
                            if s_cursor_idx = 25 then
                                s_cursor_idx <= 0;
                            else
                                s_cursor_idx <= s_cursor_idx + 1;
                            end if;
                        end if;

                        if confirm_pulse = '1' then
                            if s_guessed_mask(s_cursor_idx) = '0' then
                                next_mask               := s_guessed_mask;
                                next_mask(s_cursor_idx) := '1';
                                s_guessed_mask          <= next_mask;

                                letter_found := false;
                                for i in 0 to MAX_WORD_LEN - 1 loop
                                    if i < cur_entry.len and cur_entry.letters(i) = s_cursor_idx then
                                        letter_found := true;
                                    end if;
                                end loop;

                                next_wrong := s_wrong_count;
                                if not letter_found then
                                    if s_wrong_count < MAX_WRONG then
                                        next_wrong := s_wrong_count + 1;
                                    end if;
                                end if;
                                s_wrong_count <= next_wrong;

                                all_revealed := true;
                                for i in 0 to MAX_WORD_LEN - 1 loop
                                    if i < cur_entry.len and next_mask(cur_entry.letters(i)) = '0' then
                                        all_revealed := false;
                                    end if;
                                end loop;

                                if all_revealed then
                                    s_game_state <= ST_WIN;
                                    if s_score <= 989 then
                                        s_score <= s_score + 10;
                                    end if;
                                elsif next_wrong = MAX_WRONG then
                                    s_game_state <= ST_LOSE;
                                end if;
                            end if;
                        end if;

                    when ST_WIN | ST_LOSE =>
                        if confirm_pulse = '1' then
                            if s_word_idx = NUM_WORDS - 1 then
                                s_word_idx <= 0;
                            else
                                s_word_idx <= s_word_idx + 1;
                            end if;
                            s_cursor_idx   <= 0;
                            s_guessed_mask <= (others => '0');
                            s_wrong_count  <= 0;
                            s_game_state   <= ST_PLAYING;
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture rtl;
