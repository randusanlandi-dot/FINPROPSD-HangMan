library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_timing_640x480 is
    port (
        pclk  : in  std_logic;
        rst   : in  std_logic;
        hsync : out std_logic;
        vsync : out std_logic;
        vde   : out std_logic;
        px_x  : out integer range 0 to 799;
        px_y  : out integer range 0 to 524
    );
end entity vga_timing_640x480;

architecture rtl of vga_timing_640x480 is
    constant H_ACTIVE : integer := 640;
    constant H_FP     : integer := 16;
    constant H_SYNC   : integer := 96;
    constant H_BP     : integer := 48;
    constant H_TOTAL  : integer := H_ACTIVE + H_FP + H_SYNC + H_BP; -- 800

    constant V_ACTIVE : integer := 480;
    constant V_FP     : integer := 10;
    constant V_SYNC   : integer := 2;
    constant V_BP     : integer := 33;
    constant V_TOTAL  : integer := V_ACTIVE + V_FP + V_SYNC + V_BP; -- 525

    signal h_cnt : integer range 0 to H_TOTAL - 1 := 0;
    signal v_cnt : integer range 0 to V_TOTAL - 1 := 0;
begin

    process(pclk)
    begin
        if rising_edge(pclk) then
            if rst = '1' then
                h_cnt <= 0;
                v_cnt <= 0;
            else
                if h_cnt = H_TOTAL - 1 then
                    h_cnt <= 0;
                    if v_cnt = V_TOTAL - 1 then
                        v_cnt <= 0;
                    else
                        v_cnt <= v_cnt + 1;
                    end if;
                else
                    h_cnt <= h_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    hsync <= '0' when (h_cnt >= H_ACTIVE + H_FP) and (h_cnt < H_ACTIVE + H_FP + H_SYNC) else '1';
    vsync <= '0' when (v_cnt >= V_ACTIVE + V_FP) and (v_cnt < V_ACTIVE + V_FP + V_SYNC) else '1';
    vde   <= '1' when (h_cnt < H_ACTIVE) and (v_cnt < V_ACTIVE) else '0';
    px_x  <= h_cnt;
    px_y  <= v_cnt;

end architecture rtl;
