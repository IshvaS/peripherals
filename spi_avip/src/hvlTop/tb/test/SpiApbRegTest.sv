`ifndef SPIAPBREGTEST_INCLUDED_
`define SPIAPBREGTEST_INCLUDED_

//--------------------------------------------------------------------------------------------
// Class: SpiApbRegTest
//  First sanity test for the DUT: APB register write/read-back (no SPI traffic yet).
//  If this passes, clock, reset and the APB timing in ApbSimpleIf are correct.
//--------------------------------------------------------------------------------------------
class SpiApbRegTest extends SpiBaseTest;
  `uvm_component_utils(SpiApbRegTest)

  virtual ApbSimpleIf apbVif;

  // Register offsets (verify against spi_master_apb_if.sv)
  localparam logic [11:0] SPI_CLKDIV = 12'h004;
  localparam logic [11:0] SPI_ADR    = 12'h00C;

  extern function new(string name = "SpiApbRegTest", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task checkReg(input logic [11:0] addr, input logic [31:0] wdata, input logic [31:0] mask);
endclass : SpiApbRegTest

function SpiApbRegTest::new(string name = "SpiApbRegTest", uvm_component parent = null);
  super.new(name, parent);
endfunction : new

function void SpiApbRegTest::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db #(virtual ApbSimpleIf)::get(this, "", "ApbSimpleIf", apbVif))
    `uvm_fatal(get_type_name(), "ApbSimpleIf not found in config_db (set in SpiHdlTop)")
endfunction : build_phase

task SpiApbRegTest::checkReg(input logic [11:0] addr, input logic [31:0] wdata, input logic [31:0] mask);
  logic [31:0] rdata;
  apbVif.write(addr, wdata);
  apbVif.read (addr, rdata);
  if ((rdata & mask) !== (wdata & mask))
    `uvm_error(get_type_name(), $sformatf("Reg 0x%0h: wrote 0x%0h, read 0x%0h (mask 0x%0h)", addr, wdata, rdata, mask))
  else
    `uvm_info(get_type_name(), $sformatf("Reg 0x%0h OK: 0x%0h", addr, rdata & mask), UVM_NONE)
endtask : checkReg

task SpiApbRegTest::run_phase(uvm_phase phase);
  phase.raise_objection(this, "SpiApbRegTest");

  // Wait until reset has been released
  repeat (10) @(posedge apbVif.pclk);

  checkReg(SPI_CLKDIV, 32'h0000_0005, 32'h0000_00FF);
  checkReg(SPI_ADR,    32'hA5A5_5A5A, 32'hFFFF_FFFF);

  #100;
  phase.drop_objection(this, "SpiApbRegTest");
endtask : run_phase

`endif
