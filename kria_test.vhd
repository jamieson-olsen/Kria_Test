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
    port (

    sysclk_p, sysclk_n: in std_logic; -- system clock LVDS 100MHz
    --clk625_p, clk625_n: in std_logic; -- the system clock LVDS 62.5MHz is not used
    
    -- Two GTH channels for 10G optical links to DAQ...

    --gth_refclk0_p, gth_refclk0_n: in std_logic;  -- GTH quad refclk, 156.25MHz, LVDS
    --gth_refclk1_p, gth1_refclk1_n: in std_logic; -- optional secondary GTH refclk, LVDS

    --sfp_gth0_los: in std_logic; -- high = loss of optical signal, 3.3V logic
    --sfp_gth0_abs: in std_logic; -- high = sfp module absent, 3.3V logic
    --sfp_gth0_tx_dis: out std_logic; -- high to disable sfp transmitter, 3.3V logic
    --tx0_gth_p, tx0_gth_n: out std_logic; -- GTH CML
    --rx0_gth_p, rx0_gth_n: in std_logic; -- GTH CML

    --sfp_gth1_los: in std_logic; -- high = loss of optical signal, 3.3V logic
    --sfp_gth1_abs: in std_logic; -- high = sfp module absent, 3.3V logic
    --sfp_gth1_tx_dis: out std_logic; -- high to disable sfp transmitter, 3.3V logic
    --tx1_gth_p, tx1_gth_n: out std_logic; -- GTH CML
    --rx1_gth_p, rx1_gth_n: in std_logic; -- GTH CML

    -- Timing interface optical SFP (note: does not use MGT)

    sfp_tmg_los: in std_logic; -- high = loss of optical signal
    sfp_tmg_abs: in std_logic; -- high = sfp module absent
    sfp_tmg_tx_dis: out std_logic; -- high to disable sfp transmitter
    tx0_tmg_p, tx0_tmg_n: out std_logic; -- LVDS to the timing SFP
    rx0_tmg_p, rx0_tmg_n: in std_logic; -- LVDS from the timing SFP, has external 100 ohm termination resistor

    -- I2C master interface drives mux/buffer and clock generator, 3.3V logic

    --pl_sda: inout std_logic;
    --pl_scl: out std_logic;
    --pl_i2c_resetn: out std_logic;

    -- SPI master, two daisy chained DAC chips, 3.3V logic

    --dac_spi_din: in std_logic;    
    --dac_spi_sclk: out std_logic;
    --dac_spi_syncn: out std_logic;
    --dac_spi_ldacn: out std_logic;

    -- some status LEDs, 3.3V logic, active LOW

    pl_stat_led: out std_logic_vector(3 downto 0)

  );

    attribute CORE_GENERATION_INFO : string;
    attribute CORE_GENERATION_INFO of kria_test : entity is "DAPHNE_V3_1E,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=DAPHNE_V3_1E,x_ipVersion=1.00.a,x_ipLanguage=VHDL,numBlks=4,numReposBlks=4,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=1,numPkgbdBlks=0,bdsource=USER,da_zynq_ultra_ps_e_cnt=1,synth_mode=OOC_per_IP}";
    attribute HW_HANDOFF : string;
    attribute HW_HANDOFF of kria_test : entity is "DAPHNE_V3_1E.hwdef";

end kria_test;

architecture kria_test_arch of kria_test is

-- declare components

    component daphne_v3_1e_vio_0_0 is
    port (
        clk : in std_logic;
        probe_out0 : out std_logic_vector ( 0 to 0 );
        probe_out1 : out std_logic_vector ( 0 to 0 );
        probe_out2 : out std_logic_vector ( 0 to 0 );
        probe_out3 : out std_logic_vector ( 0 to 0 );
        probe_out4 : out std_logic_vector ( 15 downto 0 )
    );
    end component daphne_v3_1e_vio_0_0;
  
    component endpoint
    port (
        sysclk_p : in std_logic;
        sysclk_n : in std_logic;
        reset_async : in std_logic;
        sfp_tmg_los : in std_logic;
        rx0_tmg_p : in std_logic;
        rx0_tmg_n : in std_logic;
        sfp_tmg_tx_dis : out std_logic;
        tx0_tmg_p : out std_logic;
        tx0_tmg_n : out std_logic;
        ep_reset : in std_logic;
        ep_addr : in std_logic_vector ( 15 downto 0 );
        ep_ts_rdy : out std_logic;
        ep_stat : out std_logic_vector ( 3 downto 0 );
        mmcm1_reset : in std_logic;
        mmcm1_locked : out std_logic;
        mmcm0_locked : out std_logic;
        use_ep : in std_logic;
        mclk : out std_logic;
        sclk200 : out std_logic;
        sclk100 : out std_logic;
        timestamp : out std_logic_vector ( 63 downto 0 );
        
        chip_clk_debug : out std_logic;
        rx_tmg_debug : out std_logic;
        tx_tmg_debug : out std_logic;
        sfp_dis_debug : out std_logic;
        sfp_los_debug : out std_logic
    );
    end component endpoint;

    component daphne_v3_1e_ila_0_0 is
    port (
        clk : in std_logic;
        probe0 : in std_logic_vector ( 0 to 0 );
        probe1 : in std_logic_vector ( 3 downto 0 );
        probe2 : in std_logic_vector ( 0 to 0 );
        probe3 : in std_logic_vector ( 0 to 0 );
        probe4 : in std_logic_vector ( 0 to 0 );
        probe5 : in std_logic_vector ( 63 downto 0 );
        probe6 : in std_logic_vector ( 0 to 0 );
        probe7 : in std_logic_vector ( 0 to 0 );
        probe8 : in std_logic_vector ( 0 to 0 );
        probe9 : in std_logic_vector ( 0 to 0 );
        probe10 : in std_logic_vector ( 0 to 0 );
        probe11 : in std_logic_vector ( 0 to 0 );
        probe12 : in std_logic_vector ( 0 to 0 )
    );
    end component daphne_v3_1e_ila_0_0;
    
    component daphne_v3_1e_zynq_ultra_ps_e_0_0 is
    port (
        pl_clk0 : out std_logic
    );
    end component daphne_v3_1e_zynq_ultra_ps_e_0_0;

-- declare signals

    signal pl_clk0 : STD_LOGIC;
    signal mclk, sclk200, sclk100: std_logic;

    signal reset_async: std_logic;
    signal ep_reset: std_logic;
    signal mmcm1_reset: std_logic;

    signal use_ep: std_logic;
    signal ep_addr: std_logic_vector(15 downto 0);
    signal ep_stat: std_logic_vector(3 downto 0);
    signal mmcm1_locked, mmcm0_locked: std_logic;

    signal timestamp: std_logic_vector(63 downto 0);
    signal ep_ts_rdy: std_logic;

    signal count_reg: std_logic_vector(23 downto 0);
    signal edge_reg: std_logic;
    signal led_temp, led0_reg, led1_reg: std_logic_vector(3 downto 0);

    signal chip_clk_debug : std_logic;
    signal rx_tmg_debug : std_logic;
    signal sfp_dis_debug : std_logic;
    signal sfp_los_debug : std_logic;
    signal tx_tmg_debug : std_logic;

begin

-- this clock comes from the Zynq PS side and it is always present
-- what frequency is this anyway?

zynq_ultra_ps_e_0: DAPHNE_V3_1E_zynq_ultra_ps_e_0_0
port map( pl_clk0 => pl_clk0 );

-- timing endpoint

endpoint_inst: endpoint
port map(
      sysclk_n => sysclk_n,
      sysclk_p => sysclk_p,
      ep_addr => ep_addr,
      ep_reset => ep_reset,
      ep_stat => ep_stat,
      ep_ts_rdy => ep_ts_rdy,
      mclk => mclk,
      mmcm0_locked => mmcm0_locked,
      mmcm1_locked => mmcm1_locked,
      mmcm1_reset => mmcm1_reset,
      reset_async => reset_async,
      rx0_tmg_n => rx0_tmg_n,
      rx0_tmg_p => rx0_tmg_p,
      sclk100 => sclk100,
      sclk200 => sclk200,
      sfp_tmg_los => sfp_tmg_los,
      sfp_tmg_tx_dis => sfp_tmg_tx_dis,
      timestamp => timestamp,
      tx0_tmg_n => tx0_tmg_n,
      tx0_tmg_p => tx0_tmg_p,
      use_ep => use_ep,

      rx_tmg_debug => rx_tmg_debug,
      tx_tmg_debug => tx_tmg_debug,
      chip_clk_debug => chip_clk_debug,
      sfp_dis_debug => sfp_dis_debug,
      sfp_los_debug => sfp_los_debug
    );

ila_0: DAPHNE_V3_1E_ila_0_0
port map (
      clk => pl_clk0,
      probe0(0) => ep_ts_rdy,
      probe1(3 downto 0) => ep_stat(3 downto 0),
      probe2(0) => mclk,
      probe3(0) => sclk200,
      probe4(0) => sclk100,
      probe5(63 downto 0) => timestamp(63 downto 0),
      probe6(0) => mmcm1_locked,
      probe7(0) => mmcm0_locked,
      probe8(0) => chip_clk_debug,
      probe9(0) => rx_tmg_debug,
      probe10(0) => tx_tmg_debug,
      probe11(0) => sfp_dis_debug,
      probe12(0) => sfp_los_debug
    );

vio_0: DAPHNE_V3_1E_vio_0_0
port map (
      clk => pl_clk0,
      probe_out0(0) => reset_async,
      probe_out1(0) => ep_reset,
      probe_out2(0) => use_ep,
      probe_out3(0) => mmcm1_reset,
      probe_out4(15 downto 0) => ep_addr
    );

-- LED Blinker ------------------------------------------------------------

	led_temp(0) <= mmcm0_locked;
    led_temp(1) <= mmcm1_locked;
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
   
    -- Kria_Test PL status LEDs are ACTIVE LOW!

    pl_stat_led <= not led1_reg;

end kria_test_arch;
