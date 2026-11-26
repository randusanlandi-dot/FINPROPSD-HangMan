library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity button_1key_ctrl is
    generic (
        CLK_FREQ_HZ   : positive := 25_000_000;
        DEBOUNCE_MS   : positive := 20;
        LONG_PRESS_MS : positive := 700;
        ACTIVE_LOW    : boolean  := true
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        btn_raw       : in  std_logic;
        shuffle_pulse : out std_logic;
        confirm_pulse : out std_logic;
        btn_held      : out std_logic
    );
end entity button_1key_ctrl;

architecture rtl of button_1key_ctrl is
    constant DEBOUNCE_MAX   : natural := (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    constant LONG_PRESS_MAX : natural := (CLK_FREQ_HZ / 1000) * LONG_PRESS_MS;

    signal sync_ff       : std_logic_vector(1 downto 0) := (others => '0');
    signal btn_norm      : std_logic := '0';
    signal btn_debounced : std_logic := '0';
    signal btn_prev      : std_logic := '0';

    signal db_cnt        : natural range 0 to DEBOUNCE_MAX := 0;
    signal hold_cnt      : natural range 0 to LONG_PRESS_MAX := 0;
    signal long_fired    : std_logic := '0';
begin

    btn_norm <= (not sync_ff(1)) when ACTIVE_LOW else sync_ff(1);
    btn_held <= btn_debounced;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sync_ff       <= (others => '1') when ACTIVE_LOW else (others => '0');
                btn_debounced <= '0';
                btn_prev      <= '0';
                db_cnt        <= 0;
                hold_cnt      <= 0;
                long_fired    <= '0';
                shuffle_pulse <= '0';
                confirm_pulse <= '0';
            else

                sync_ff <= sync_ff(0) & btn_raw;

                if btn_norm /= btn_debounced then
                    if db_cnt = DEBOUNCE_MAX then
                        btn_debounced <= btn_norm;
                        db_cnt        <= 0;
                    else
                        db_cnt <= db_cnt + 1;
                    end if;
                else
                    db_cnt <= 0;
                end if;

                shuffle_pulse <= '0';
                confirm_pulse <= '0';
                btn_prev      <= btn_debounced;

                if btn_debounced = '1' then
                    if hold_cnt < LONG_PRESS_MAX then
                        hold_cnt <= hold_cnt + 1;
                    elsif long_fired = '0' then

                        confirm_pulse <= '1';
                        long_fired    <= '1';
                    end if;
                else

                    if btn_prev = '1' and long_fired = '0' then

                        shuffle_pulse <= '1';
                    end if;
                    hold_cnt   <= 0;
                    long_fired <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
