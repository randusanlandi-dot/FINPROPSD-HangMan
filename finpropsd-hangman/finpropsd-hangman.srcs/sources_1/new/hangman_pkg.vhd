library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package hangman_pkg is

    constant MAX_WORD_LEN : positive := 15;
    constant NUM_WORDS    : positive := 11;
    constant MAX_WRONG    : positive := 6;

    subtype letter_idx_t is integer range 0 to 25;
    type word_t is array (0 to MAX_WORD_LEN - 1) of letter_idx_t;

    type word_entry_t is record
        len     : integer range 1 to MAX_WORD_LEN;
        letters : word_t;
    end record word_entry_t;

    type word_rom_t is array (0 to NUM_WORDS - 1) of word_entry_t;

    type game_state_t is (ST_PLAYING, ST_WIN, ST_LOSE);

    function char_to_idx(c : character) return letter_idx_t;

    function make_word(s : string) return word_entry_t;

    constant WORD_DICT : word_rom_t := (
        0  => make_word("PYTHON"),          --  6 words
        1  => make_word("APPLE"),           --  5 
        2  => make_word("MONITOR"),         --  7 sic sebeeennn
        3  => make_word("KEYBOARD"),        --  8 
        4  => make_word("ALGORITHM"),       --  9
        5  => make_word("SIMULATION"),      -- 10
        6  => make_word("ELECTRONICS"),     -- 11
        7  => make_word("ARCHITECTURE"),    -- 12
        8  => make_word("SEMICONDUCTOR"),   -- 13
        9  => make_word("MICROPROCESSOR"),  -- 14
        10 => make_word("INSTRUMENTATION")  -- 15
    );

end package hangman_pkg;

package body hangman_pkg is

    function char_to_idx(c : character) return letter_idx_t is
    begin
        return character'pos(c) - character'pos('A');
    end function char_to_idx;

    function make_word(s : string) return word_entry_t is
        variable res : word_entry_t := (len => 1, letters => (others => 0));
        variable idx : integer := 0;
    begin
        res.len := s'length;
        for i in s'range loop
            if idx < MAX_WORD_LEN then
                res.letters(idx) := char_to_idx(s(i));
                idx := idx + 1;
            end if;
        end loop;
        return res;
    end function make_word;

end package body hangman_pkg;
