-- KRIA_TEST.vhd
-- FPGA / PL Top Level
-- Target: Kria K26 Zynq Ultrascale+

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;

use work.kria_test_package.all;

entity kria_test is
generic(version: std_logic_vector(27 downto 0) := X"1234567"); -- git commit number is passed in from tcl build script
port(

    sysclk_p, sysclk_n: in std_logic; -- system clock LVDS 100MHz
    -- clk625_p, clk625_n: in std_logic; -- system clock LVDS 62.5MHz not used here
    
    -- Two GTH channels for 10G optical links to DAQ...

    gth_refclk0_p, gth_refclk0_n: in std_logic;  -- GTH quad refclk, 156.25MHz, LVDS
    gth_refclk1_p, gth1_refclk1_n: in std_logic; -- optional secondary GTH refclk, LVDS

    sfp_gth0_los: in std_logic; -- high = loss of optical signal, 3.3V logic
    sfp_gth0_abs: in std_logic; -- high = sfp module absent, 3.3V logic
    sfp_gth0_tx_dis: out std_logic; -- high to disable sfp transmitter, 3.3V logic
    tx0_gth_p, tx0_gth_n: out std_logic; -- GTH CML
    rx0_gth_p, rx0_gth_n: in std_logic; -- GTH CML

    sfp_gth1_los: in std_logic; -- high = loss of optical signal, 3.3V logic
    sfp_gth1_abs: in std_logic; -- high = sfp module absent, 3.3V logic
    sfp_gth1_tx_dis: out std_logic; -- high to disable sfp transmitter, 3.3V logic
    tx1_gth_p, tx1_gth_n: out std_logic; -- GTH CML
    rx1_gth_p, rx1_gth_n: in std_logic; -- GTH CML

    -- Timing interface optical SFP (note: does not use MGT)

    sfp_tmg_los: in std_logic; -- high = loss of optical signal
    sfp_tmg_abs: in std_logic; -- high = sfp module absent
    sfp_tmg_tx_dis: out std_logic; -- high to disable sfp transmitter
    tx0_tmg_p, tx0_tmg_n: out std_logic; -- LVDS
    rx0_tmg_p, rx0_tmg_n: in std_logic; -- LVDS

    -- I2C master interface drives mux/buffer and clock generator, 3.3V logic

    pl_sda: inout std_logic;
    pl_scl: out std_logic;
    pl_i2c_resetn: out std_logic;

    -- SPI master, two daisy chained DAC chips, 3.3V logic

    dac_spi_din: in std_logic;    
    dac_spi_sclk: out std_logic;
    dac_spi_syncn: out std_logic;
    dac_spi_ldacn: out std_logic;

    -- status LEDs, 3.3V logic, active LOW

    pl_stat_led: out std_logic_vector(3 downto 0)

    -- AXI lite inteface(s) to PS

        -- signals TBD
        -- can the PS supply a reset signal?

  );
end kria_test;

architecture kria_test_arch of kria_test is

    component endpoint
    port(
        sysclk_p, sysclk_n: in std_logic; -- system clock LVDS 100MHz from local oscillator
        reset_async: in std_logic; -- from the PS side
        sfp_tmg_los: in std_logic; -- loss of signal
        sfp_tmg_tx_dis: out std_logic; -- high to disable timing SFP TX
        tx0_tmg_p, tx0_tmg_n: out std_logic; -- send data upstream (optional)
        rx0_tmg_p, rx0_tmg_n: in std_logic; -- LVDS recovered serial data 
        ep_reset: in std_logic; -- soft reset endpoint logic
        ep_ts_rdy: out std_logic; -- endpoint timestamp is good
        ep_stat: out std_logic_vector(3 downto 0); -- endpoint state bits
        ep_addr: in std_logic_vector(15 downto 0); 
        mmcm1_reset: in std_logic;
        mmcm1_locked: out std_logic;
        mmcm0_locked: out std_logic;
        use_ep: in std_logic; -- 0 = run on local clocks with fake timestamp, 1 = use endpoint clocks and real timestamp
        mclk: out std_logic;  -- master clock 62.5MHz
        sclk200: out std_logic; -- system clock 200MHz
        timestamp: out std_logic_vector(63 downto 0) -- sync to mclk
    );
    end component;

    component sender is
    port(
        mclk: in std_logic; -- master clock 62.5MHz
        reset: in std_logic;
        timestamp: in std_logic_vector(63 downto 0);
        gth_refclk0_p, gth_refclk0_n: in std_logic;  -- GTH quad refclk, 156.25MHz, LVDS
        sfp_gth0_los: in std_logic; -- high = loss of optical signal, 3.3V logic
        sfp_gth0_abs: in std_logic; -- high = sfp module absent, 3.3V logic
        sfp_gth0_tx_dis: out std_logic; -- high to disable sfp transmitter, 3.3V logic
        tx0_gth_p, tx0_gth_n: out std_logic; -- GTH CML
        rx0_gth_p, rx0_gth_n: in std_logic; -- GTH CML
        sfp_gth1_los: in std_logic; -- high = loss of optical signal, 3.3V logic
        sfp_gth1_abs: in std_logic; -- high = sfp module absent, 3.3V logic
        sfp_gth1_tx_dis: out std_logic; -- high to disable sfp transmitter, 3.3V logic
        tx1_gth_p, tx1_gth_n: out std_logic; -- GTH CML
        rx1_gth_p, rx1_gth_n: in std_logic -- GTH CML
      );
    end component;

    signal reset_async: std_logic;
    signal reset_ep: std_logic;
    signal use_ep: std_logic;
    signal ep_addr: std_logic_vector(15 downto 0);
    signal ep_stat: std_logic_vector(3 downto 0);
    signal reset_mmcm1, mmcm1_locked, mmcm0_locked: std_logic;
    signal mclk, sclk200: std_logic;
    signal timestamp: std_logic_vector(63 downto 0);
    signal ep_ts_rdy: std_logic;

    signal count_reg: std_logic_vector(23 downto 0);
    signal edge_reg: std_logic;
    signal led_temp, led0_reg, led1_reg: std_logic_vector(3 downto 0);

begin

    -- New Timing Endpoint ------------------------------------------------------

    -- the timing endpoint logic includes some extra MMCMs to generate local system clocks too

    endpoint_inst: endpoint 
    port map(
        sysclk_p => sysclk_p,
        sysclk_n => sysclk_n,
        reset_async => reset_async,
        sfp_tmg_los => sfp_tmg_los,
        sfp_tmg_tx_dis => sfp_tmg_tx_dis,
        tx0_tmg_p => tx0_tmg_p, 
        tx0_tmg_n => tx0_tmg_n,
        rx0_tmg_p => rx0_tmg_p,
        rx0_tmg_n => rx0_tmg_n,
        ep_reset => reset_ep,
        ep_addr => ep_addr,
        ep_ts_rdy => ep_ts_rdy,
        ep_stat => ep_stat,
        mmcm1_reset => reset_mmcm1,
        mmcm1_locked => mmcm1_locked,
        mmcm0_locked => mmcm0_locked,
        use_ep => use_ep,
        mclk => mclk,
        sclk200 => sclk200,
        timestamp => timestamp
    );

    -- AXI Lite Interface to PS -----------------------------------------------

        -- the AXI lite interface should have register(s) so that we can write (and read back): 
        --      reset_async, ep_reset, mmcm1_reset
        --      use_ep
        --      ep_addr(15..0)
    
        -- the AXI lite interface should have register(s) so that we can read:
        --      ep_ts_rdy, ep_stat(3..0)
        --      sfp_tmg_los, sfp_tmg_abs
        --      sfp_gth0_los, sfp_gth0_abs
        --      sfp_gth1_los, sfp_gth1_abs
        --      timestamp(63..0) 


    -- Fake Sender ------------------------------------------------------------

    -- this module drives the two 10G optical output links to DAQ. for now
    -- we will generate a periodic, fixed, repeating fake output record that
    -- has a real time stamp. placeholder for now, still need to figure out what 
    -- this custom IP block looks like. Developed by the Bristol (UK) guys.

    sender_inst: sender
    port map(
        mclk => mclk,
        reset => reset_async,
        timestamp => timestamp,
        gth_refclk0_p => gth_refclk0_p, -- 156.25MHz
        gth_refclk0_n => gth_refclk0_n, 
        sfp_gth0_los => sfp_gth0_los,
        sfp_gth0_abs => sfp_gth0_abs,
        sfp_gth0_tx_dis => sfp_gth0_tx_dis,
        tx0_gth_p => tx0_gth_p,
        tx0_gth_n => tx0_gth_n,
        rx0_gth_p => rx0_gth_p,
        rx0_gth_n => rx0_gth_n,
        sfp_gth1_los => sfp_gth1_los,
        sfp_gth1_abs => sfp_gth1_abs,
        sfp_gth1_tx_dis => sfp_gth1_tx_dis,
        tx1_gth_p => tx1_gth_p,
        tx1_gth_n => tx1_gth_n,
        rx1_gth_p => rx1_gth_p,
        rx1_gth_n => rx1_gth_n
      );

    -- I2C Master ------------------------------------------------------------

    -- this I2C master controls a the PL I2C bus this bus communicates with:
    --
    --  I2C fanout mux/buffer TCA9546APWR 
    --      This active mux is controlled by writing to address 113. 
    --      It selects which SFP is connected. This is optional 
    --      for now and not needed at this time.
    --
    --  Clock Generator SI5332B
    --      This device is at address 106. We will need to write to this 
    --      device to configure it to generate the clock frequencies we 
    --      need: OUT1 = 100MHz LVDS, OUT3 = 156.25MHz LVDS
    --      (OUT0 and OUT2 are not used)
    
    -- (is this another axi lite interface?)
    




    -- SPI Master for DACs ---------------------------------------------------

    -- this SPI master is used to write to the DAC chips, which can generate
    -- eight analog voltages. this is optional for now.

    dac_spi_sclk <= '0';
    dac_spi_syncn <= '1';
    dac_spi_ldacn <= '1';

    -- LED Blinker ------------------------------------------------------------

	led_temp(0) <= mmcm1_locked;
    led_temp(1) <= mmcm0_locked;
	led_temp(2) <= ep_ts_rdy; -- timestamp is valid
	led_temp(3) <= '1' when (ep_stat="1000") else '0'; -- endpoint status "good to go!"

	-- LED driver logic. pulse stretch fast signals so they are visible (aka a "one shot")
	-- Use a fast clock to sample the signal led_temp. whenever led_temp is HIGH, led0_reg
	-- goes high and stays high. periodically (200MHz / 2^24 = 11Hz) copy led0_reg into led1_reg 
	-- and reset led0_reg. this insures that the output signal led1_reg is HIGH for a whole
	-- 11Hz cycle, regardless of when the blip on the led_temp occurs.

    oneshot_proc: process(sclk200)
    begin
        if rising_edge(sclk200) then
            if (reset_async='1') then
                count_reg <= (others=>'0');
                edge_reg  <= '0';
                led0_reg <= (others=>'0');
				led1_reg <= (others=>'0');
            else
                count_reg <= std_logic_vector(unsigned(count_reg) + 1);
                edge_reg  <= count_reg(23);

                if (edge_reg='0' and count_reg(23)='1') then -- MSB of the counter was JUST set
                    led1_reg <= led0_reg;
                    led0_reg <= (others=>'0');
                else
                    led0_reg <= led0_reg or led_temp;
                end if;
            end if;
        end if;
    end process oneshot_proc;
   
    -- Kria_Test LEDs are ACTIVE LOW

    pl_stat_led <= not led1_reg;

end kria_test_arch;
