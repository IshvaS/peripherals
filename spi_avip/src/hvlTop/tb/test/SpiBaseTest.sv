`ifndef SPIBASETEST_INCLUDED_
`define SPIBASETEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: SpiBaseTest
//  Base test for verifying apb_spi_master (DUT = SPI master).
//  Only the SPI slave agent is used; the SPI master agent has been removed.
//--------------------------------------------------------------------------------------------
class SpiBaseTest extends uvm_test;
  `uvm_component_utils(SpiBaseTest)
  // Variable: spiEnvConfig
  // Declaring environment config handle
  SpiEnvConfig spiEnvConfig;

  // Variable: spiEnv
  // Handle for environment 
  SpiEnv spiEnv;

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name = "SpiBaseTest", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void setupSpiEnvConfig();
  extern virtual function void setupSpiSlaveAgentConfig();
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);

endclass : SpiBaseTest

//--------------------------------------------------------------------------------------------
// Construct: new
//--------------------------------------------------------------------------------------------
function SpiBaseTest::new(string name = "SpiBaseTest",uvm_component parent = null);
  super.new(name, parent);
endfunction : new

//--------------------------------------------------------------------------------------------
// Function: build_phase
//--------------------------------------------------------------------------------------------
function void SpiBaseTest::build_phase(uvm_phase phase);
  super.build_phase(phase);
  // Setup the environemnt cfg 
  spiEnvConfig = SpiEnvConfig::type_id::create("spiEnvConfig");
  setupSpiEnvConfig();
  // Create the environment
  spiEnv = SpiEnv::type_id::create("spiEnv",this);
endfunction : build_phase

//--------------------------------------------------------------------------------------------
// Function: setupSpiEnvConfig
// Setup the environment configuration and store the handles into the config_db
//--------------------------------------------------------------------------------------------
function void SpiBaseTest::setupSpiEnvConfig();
  spiEnvConfig.noOfSlaves = NO_OF_SLAVES;

  // The stock scoreboard compares master vs slave packets; with the DUT as master
  // there is no master agent, so keep it off until the DUT scoreboard is written.
  spiEnvConfig.hasScoreboard = 0;
  spiEnvConfig.hasVirtualSequencer = 1;

  // Setup the slave agent(s) cfg 
  spiEnvConfig.spiSlaveAgentConfig = new[spiEnvConfig.noOfSlaves];
  foreach(spiEnvConfig.spiSlaveAgentConfig[i]) begin
    spiEnvConfig.spiSlaveAgentConfig[i] = SpiSlaveAgentConfig::type_id::create($sformatf("spiSlaveAgentConfig[%0d]",i));
  end
  setupSpiSlaveAgentConfig();
  foreach(spiEnvConfig.spiSlaveAgentConfig[i]) begin
    uvm_config_db #(SpiSlaveAgentConfig)::set(this,$sformatf("*spiSlaveAgent[%0d]*",i),
                                             "SpiSlaveAgentConfig", spiEnvConfig.spiSlaveAgentConfig[i]);
    `uvm_info(get_type_name(),$sformatf("SpiSlaveAgentConfig = \n %0p",
    spiEnvConfig.spiSlaveAgentConfig[i].sprint()),UVM_NONE)
  end

  // set method for env_cfg
  uvm_config_db #(SpiEnvConfig)::set(this,"*","SpiEnvConfig",spiEnvConfig);
  `uvm_info(get_type_name(),$sformatf("env_cfg = \n %0p", spiEnvConfig.sprint()),UVM_NONE)
endfunction: setupSpiEnvConfig

//--------------------------------------------------------------------------------------------
// Function: setupSpiSlaveAgentConfig
// Slave settings must match what apb_spi_master generates:
//   SPI mode 0 (CPOL=0, CPHA=0), MSB first, single-lane (standard) SPI.
//--------------------------------------------------------------------------------------------
function void SpiBaseTest::setupSpiSlaveAgentConfig();
  foreach(spiEnvConfig.spiSlaveAgentConfig[i]) begin
    spiEnvConfig.spiSlaveAgentConfig[i].slaveID         = i;
    spiEnvConfig.spiSlaveAgentConfig[i].isActive        = uvm_active_passive_enum'(UVM_ACTIVE);
    spiEnvConfig.spiSlaveAgentConfig[i].spiMode         = operationModesEnum'(CPOL0_CPHA0);
    spiEnvConfig.spiSlaveAgentConfig[i].shiftDirection  = shiftDirectionEnum'(MSB_FIRST);
    spiEnvConfig.spiSlaveAgentConfig[i].hasCoverage     = 1;
    spiEnvConfig.spiSlaveAgentConfig[i].spiType         = spiTypeEnum'(SIMPLE_SPI);
  end
endfunction: setupSpiSlaveAgentConfig

//--------------------------------------------------------------------------------------------
// Function: end_of_elaboration_phase
//--------------------------------------------------------------------------------------------
function void SpiBaseTest::end_of_elaboration_phase(uvm_phase phase);
  uvm_top.print_topology();
endfunction : end_of_elaboration_phase

//--------------------------------------------------------------------------------------------
// Task: run_phase
//--------------------------------------------------------------------------------------------
task SpiBaseTest::run_phase(uvm_phase phase);
  phase.raise_objection(this, "SpiBaseTest");
  `uvm_info(get_type_name(), $sformatf("Inside SpiBaseTest"), UVM_NONE);
  super.run_phase(phase);
  #100;
  `uvm_info(get_type_name(), $sformatf("Done SpiBaseTest"), UVM_NONE);
  phase.drop_objection(this);
endtask : run_phase

`endif
