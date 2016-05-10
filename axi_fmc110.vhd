-------------------------------------------------------------------------------------
-- FILE NAME : .vhd
-- AUTHOR    : Luis F. Munoz
-- COMPANY   : 4DSP
-- UNITS     : Entity       - toplevel_template
--             Architecture - Behavioral
-- LANGUAGE  : VHDL
-- DATE      : May 21, 2014
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- This entity converts from an AXI-Lite interface to a 4DSP StellarIP Command interface.
--  
-- A StellarIP command has the following format
-- [ Command word (4-bits) | Address  (28-bits) | Data (32-bits) ]
--
-------------------------------------------------------------------------------------
 
-------------------------------------------------------------------------------------
-- LIBRARIES
-------------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_misc.all;
    use ieee.std_logic_arith.all; 

library xil_defaultlib;  

library unisim;
  use unisim.vcomponents.all;

-------------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------------
entity axi_fmc110 is
port (

   --___ AXI-Lite Register Interface __---

   -- axi-lite: global
   s_axi_aclk              : in  std_logic;
   s_axi_aresetn           : in  std_logic;
   -- axi-lite: write address channel
   s_axi_awaddr            : in  std_logic_vector(31 downto 0);
   s_axi_awvalid           : in  std_logic;
   s_axi_awready           : out std_logic;
   -- axi-lite: write data channel 
   s_axi_wdata             : in  std_logic_vector(31  downto 0);						
   s_axi_wstrb             : in  std_logic_vector(3  downto 0);						
   s_axi_wvalid            : in  std_logic;
   s_axi_wready            : out std_logic;
   -- axi-lite: write response channel
   s_axi_bresp             : out std_logic_vector(1 downto 0);
   s_axi_bvalid            : out std_logic;
   s_axi_bready            : in  std_logic;
   -- axi-lite: read address channel
   s_axi_araddr            : in  std_logic_vector(31  downto 0); 								
   s_axi_arvalid           : in  std_logic;
   s_axi_arready           : out std_logic;
   -- axi-lite: read channel
   s_axi_rdata             : out std_logic_vector(31 downto 0);
   s_axi_rresp             : out std_logic_vector(1 downto 0);
   s_axi_rvalid            : out std_logic;
   s_axi_rready            : in  std_logic;

   --___ AXI-Stream Slave DAC0 ___---

   dac0_tdata             : in std_logic_vector(63 downto 0); 
   dac0_tkeep             : out std_logic_vector(3 downto 0); 
   dac0_tlast             : in std_logic; 
   dac0_tready            : out std_logic;
   dac0_tstrb             : out std_logic;
   dac0_tuser             : in std_logic_vector(31 downto 0);
   dac0_tvalid            : in std_logic;

  --___ AXI-Stream Master ADC0 ___---

   adc0_tdata             : out std_logic_vector(63 downto 0); 
   adc0_tkeep             : in std_logic_vector(3 downto 0); 
   adc0_tlast             : out std_logic; 
   adc0_tready            : in std_logic;
   adc0_tstrb             : in std_logic;
   adc0_tuser             : out std_logic_vector(31 downto 0);
   adc0_tvalid            : out std_logic;

   --___ FMC110 External Signals  __---

   fmc_to_cpld           : inout std_logic_vector(3 downto 0);
   front_io_fmc          : inout std_logic_vector(3 downto 0);
   
   clk_to_fpga_p         : in    std_logic;
   clk_to_fpga_n         : in    std_logic;
   ext_trigger_p         : in    std_logic;
   ext_trigger_n         : in    std_logic;
   sync_from_fpga_p      : out   std_logic;
   sync_from_fpga_n      : out   std_logic;
   
   adc0_clka_p           : in    std_logic;
   adc0_clka_n           : in    std_logic;
   adc0_da_p             : in    std_logic_vector(11 downto 0);
   adc0_da_n             : in    std_logic_vector(11 downto 0);
   adc0_ovra_p           : in    std_logic;
   adc0_ovra_n           : in    std_logic;
   adc0_db_p             : in    std_logic_vector(11 downto 0);
   adc0_db_n             : in    std_logic_vector(11 downto 0);
   adc0_ovrb_p           : in    std_logic;
   adc0_ovrb_n           : in    std_logic;
   
   adc1_clka_p           : in    std_logic;
   adc1_clka_n           : in    std_logic;
   adc1_da_p             : in    std_logic_vector(11 downto 0);
   adc1_da_n             : in    std_logic_vector(11 downto 0);
   adc1_ovra_p           : in    std_logic;
   adc1_ovra_n           : in    std_logic;
   
   dac_sync_p            : out   std_logic;
   dac_sync_n            : out   std_logic;
   
   dac0_dclk_p           : out   std_logic;
   dac0_dclk_n           : out   std_logic;
   dac0_data_p           : out   std_logic_vector(15 downto 0);
   dac0_data_n           : out   std_logic_vector(15 downto 0);
   
   dac1_dclk_p           : out   std_logic;
   dac1_dclk_n           : out   std_logic;
   dac1_data_p           : out   std_logic_vector(15 downto 0);
   dac1_data_n           : out   std_logic_vector(15 downto 0);
   
   pg_m2c                : in    std_logic;
   prsnt_m2c_l           : in    std_logic
);
end axi_fmc110;

-------------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------------
architecture Behavioral of axi_fmc110 is

-------------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------------
  
-------------------------------------------------------------------------------------
-- SIGNALS
-------------------------------------------------------------------------------------
signal rst                     : std_logic;
signal rst_rstin               : std_logic_vector(31 downto 0);

-- 4DSP StellarIP Command Interface
signal cmdclk_out              :  std_logic;
signal cmd_out                 :  std_logic_vector(63 downto 0); 
signal cmd_out_val             :  std_logic;  
signal cmd_in                  :  std_logic_vector(63 downto 0);  
signal cmd_in_val              :  std_logic;

signal dac0_in_stop            : std_logic; 
signal dac0_in_dval            : std_logic; 
signal dac0_in_data            : std_logic_vector(63 downto 0); 
signal dac1_in_stop            : std_logic; 
signal dac1_in_dval            : std_logic; 
signal dac1_in_data            : std_logic_vector(63 downto 0); 

signal adc0_out_stop            : std_logic; 
signal adc0_out_dval            : std_logic; 
signal adc0_out_data            : std_logic_vector(63 downto 0); 
signal adc1_out_stop            : std_logic; 
signal adc1_out_dval            : std_logic; 
signal adc1_out_data            : std_logic_vector(63 downto 0); 

--***********************************************************************************
begin
--***********************************************************************************

-------------------------------------------------------------------------------
-- Invert the reset coming from AXI
-------------------------------------------------------------------------------
process (S_AXI_ACLK) is
begin
   if rising_edge(S_AXI_ACLK) then
      rst <=  not S_AXI_ARESETN;
   end if;
end process;

rst_rstin <= (2=>rst, others=>'0');


-----------------------------------------------------------------------------------
-- 4DSP FMC110 IP w/ StellarIP Interface
-----------------------------------------------------------------------------------
sip_fmc110_0: 
entity xil_defaultlib.sip_fmc110
generic map
 (
   global_start_addr_gen     =>   x"0000000",
   global_stop_addr_gen      =>   x"0001FFF",
   private_start_addr_gen    =>   x"0002404",
   private_stop_addr_gen     =>   x"0003403"
)
port map
 (
    --Wormhole 'clk' of type 'clkin':
   clk_clkin                 =>   (others=>'0'), -- Not Used
   --Wormhole 'rst' of type 'rst_in':
   rst_rstin                 =>   rst_rstin,-- Only  rst_rstin(2) is used
   --Wormhole 'cmdclk_in' of type 'cmdclk_in':
   cmdclk_in_cmdclk          =>   cmdclk_out,
   --Wormhole 'cmd_in' of type 'cmd_in':
   cmd_in_cmdin              =>   cmd_out,
   cmd_in_cmdin_val          =>   cmd_out_val,
   --Wormhole 'cmd_out' of type 'cmd_out':
   cmd_out_cmdout            =>   cmd_in,
   cmd_out_cmdout_val        =>   cmd_in_val,
   --Wormhole 'adc0' of type 'wh_out':
   adc0_out_stop             => adc0_out_stop, 
   adc0_out_dval             => adc0_out_dval,             
   adc0_out_data             => adc0_out_data,
   --Wormhole 'adc1' of type 'wh_out':
   adc1_out_stop             => adc1_out_stop, 
   adc1_out_dval             => adc1_out_dval, 
   adc1_out_data             => adc1_out_data,  
   --Wormhole 'dac0' of type 'wh_in':
   dac0_in_stop              => dac0_in_stop, 
   dac0_in_dval              => dac0_in_dval, 
   dac0_in_data              => dac0_in_data, 
   --Wormhole 'dac1' of type 'wh_in':
   dac1_in_stop              => dac1_in_stop,
   dac1_in_dval              => dac1_in_dval,
   dac1_in_data              => dac1_in_data,
   --Wormhole 'ext_fmc110' of type 'ext_fmc110':  
   fmc_to_cpld               =>   fmc_to_cpld,
   front_io_fmc              =>   front_io_fmc,
   clk_to_fpga_p             =>   clk_to_fpga_p,
   clk_to_fpga_n             =>   clk_to_fpga_n,
   ext_trigger_p             =>   ext_trigger_p,
   ext_trigger_n             =>   ext_trigger_n,
   sync_from_fpga_p          =>   sync_from_fpga_p,
   sync_from_fpga_n          =>   sync_from_fpga_n,
   dac_sync_p                =>   dac_sync_p,
   dac_sync_n                =>   dac_sync_n,
   dac0_data_p               =>   dac0_data_p,
   dac0_data_n               =>   dac0_data_n,
   dac0_dclk_p               =>   dac0_dclk_p,
   dac0_dclk_n               =>   dac0_dclk_n,
   dac1_data_p               =>   dac1_data_p,
   dac1_data_n               =>   dac1_data_n,
   dac1_dclk_p               =>   dac1_dclk_p,
   dac1_dclk_n               =>   dac1_dclk_n,
   
   adc0_da_p                 =>   adc0_da_p,
   adc0_da_n                 =>   adc0_da_n,
   adc0_ovra_p               =>   adc0_ovra_p,
   adc0_ovra_n               =>   adc0_ovra_n,
   adc0_db_p                 =>   adc0_db_p,
   adc0_db_n                 =>   adc0_db_n,
   adc0_ovrb_p               =>   adc0_ovrb_p,
   adc0_ovrb_n               =>   adc0_ovrb_n,
   adc0_clka_p               =>   adc0_clka_p,
   adc0_clka_n               =>   adc0_clka_n,
   adc1_da_p                 =>   adc1_da_p,
   adc1_da_n                 =>   adc1_da_n,
   adc1_ovra_p               =>   adc1_ovra_p,
   adc1_ovra_n               =>   adc1_ovra_n,
   adc1_clka_p               =>   adc1_clka_p,
   adc1_clka_n               =>   adc1_clka_n,
   pg_m2c                    =>   pg_m2c, --'0',
   prsnt_m2c_l               =>   prsnt_m2c_l
);

-----------------------------------------------------------------------------------
-- AXI-Lite to StellarIP Command Interface
-----------------------------------------------------------------------------------
inst_stellarcmd_to_axilite:
entity xil_defaultlib.stellarcmd_to_axilite
port map(
   s_axi_aclk      => s_axi_aclk,
   --s_axi_aresetn   => axi_aresetn,
   rst            => rst,
   -- axi-lite: write address channel
   s_axi_awaddr    => s_axi_awaddr,
   s_axi_awvalid   => s_axi_awvalid,
   s_axi_awready   => s_axi_awready,
   -- axi-lite: write data channel 
   s_axi_wdata     => s_axi_wdata,
   s_axi_wstrb     => s_axi_wstrb,	 			
   s_axi_wvalid    => s_axi_wvalid,
   s_axi_wready    => s_axi_wready,
   -- axi-lite: write response channel
   s_axi_bresp     => s_axi_bresp,
   s_axi_bvalid    => s_axi_bvalid,
   s_axi_bready    => s_axi_bready,
   -- axi-lite: read address channel
   s_axi_araddr    => s_axi_araddr,				
   s_axi_arvalid   => s_axi_arvalid,
   s_axi_arready   => s_axi_arready,
   -- axi-lite: read channel
   s_axi_rdata     => s_axi_rdata,
   s_axi_rresp     => s_axi_rresp,
   s_axi_rvalid    => s_axi_rvalid,
   s_axi_rready    => s_axi_rready,
   -- command interface 
   cmd_clk          => cmdclk_out,
   cmd_out          => cmd_out,
   cmd_out_val      => cmd_out_val,
   cmd_in           => cmd_in,
   cmd_in_val       => cmd_in_val
);

-----------------------------------------------------------------------------------
-- DAC Interface
-----------------------------------------------------------------------------------
inst_axistream_to_whin:
entity xil_defaultlib.axistream_to_whin
port map (
   clk                => s_axi_aclk,    
   rst                => rst,  
   data_in_tdata      => dac0_tdata, 
   data_in_tkeep      => dac0_tkeep, 
   data_in_tlast      => dac0_tlast, 
   data_in_tready     => dac0_tready, 
   data_in_tstrb      => dac0_tstrb, 
   data_in_tuser      => dac0_tuser, 
   data_in_tvalid     => dac0_tvalid, 
   data_out_out_stop  => dac0_in_stop, 
   data_out_out_dval  => dac0_in_dval,
   data_out_out_data  => dac0_in_data 
);




-----------------------------------------------------------------------------------
-- ADC Interface
-----------------------------------------------------------------------------------
inst_whout_axistream:
entity xil_defaultlib.whout_to_axistream
port map(
   clk                 => s_axi_aclk,       
   rst                 => rst,        
   data_in_in_stop     => adc0_out_stop,       
   data_in_in_dval     => adc0_out_dval,       
   data_in_in_data     => adc0_out_data,       
   data_out_tdata      => adc0_tdata,
   data_out_tkeep      => adc0_tkeep,
   data_out_tlast      => adc0_tlast,
   data_out_tready     => adc0_tready,
   data_out_tstrb      => adc0_tstrb,     
   data_out_tuser      => adc0_tuser,     
   data_out_tvalid     => adc0_tvalid    
);



--***********************************************************************************
end architecture Behavioral;
--***********************************************************************************

