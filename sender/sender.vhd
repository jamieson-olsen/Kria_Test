-- sender.vhd
-- Target: Kria_Test K26 Zynq Ultrascale+

-- sender to generate periodic fake output records to DAQ
-- will use real timestamp
-- uses 10G Ethernet frames and custom IP block developed by Bristol UK guys

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library unimacro;
use unimacro.vcomponents.all;

use work.kria_test_package.all;

entity sender is
port(

    mclk: in std_logic; -- master clock 62.5MHz
    reset: in std_logic;  -- async reset from PS
    timestamp: in std_logic_vector(63 downto 0); -- sync to mclk

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
end sender;

architecture sender_arch of sender is

begin

-- placeholder will add IP block and other glue logic later...    

sfp_gth0_tx_dis <= sfp_gth0_los or sfp_gth0_abs;
sfp_gth1_tx_dis <= sfp_gth1_los or sfp_gth1_abs;

tx0_gth_p <= '1';
tx0_gth_n <= '0';

tx1_gth_p <= '1';
tx1_gth_n <= '0';

end sender_arch;
