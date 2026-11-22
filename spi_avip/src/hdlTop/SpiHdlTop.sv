`ifndef SPIHDLTOP_INCLUDED_
`define SPIHDLTOP_INCLUDED_

//--------------------------------------------------------------------------------------------
// Module      : HDL Top
// Description : DUT-level top. APB driver interface -> apb_spi_master (DUT) -> SPI slave BFM.
//               The SPI master BFM is not used: the DUT is the SPI master.
//--------------------------------------------------------------------------------------------

module SpiHdlTop;

  import uvm_pkg::*;
  import SpiGlobalsPkg::*;     // NO_OF_SLAVES

  //-------------------------------------------------------
  // Clock Reset Initialization
  //-------------------------------------------------------
  bit clk;
  bit rst;

  //-------------------------------------------------------
  // Display statement for SpiHdlTop
  //-------------------------------------------------------
  initial begin
    $display("SpiHdlTop");
  end

  //-------------------------------------------------------
  // System Clock Generation
  //-------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  //-------------------------------------------------------
  // System Reset Generation
  // Active low reset
  //-------------------------------------------------------
  initial begin
    rst = 1'b1;

    repeat (2) begin
      @(posedge clk);
    end
    rst = 1'b0;

    repeat (2) begin
      @(posedge clk);
    end
    rst = 1'b1;
  end

  //-------------------------------------------------------
  // Interfaces
  //-------------------------------------------------------
  // SPI interface (pin level, shared with the slave BFM)
  SpiInterface spiInterface(.pclk(clk),
                            .areset(rst));

  // APB interface (driven from the UVM test through blocking tasks)
  ApbSimpleIf #(.ADDR_W(12)) apbIf(.pclk(clk),
                                   .presetn(rst));

  //-------------------------------------------------------
  // SPI Slave BFM Agent Instantiation
  // (SPI master BFM intentionally not instantiated)
  //-------------------------------------------------------
  SpiSlaveAgentBFM spiSlaveAgentBFM(spiInterface);

  //-------------------------------------------------------
  // DUT : apb_spi_master
  //-------------------------------------------------------
  logic       [1:0] events_o;

  logic             spi_clk;
  logic             spi_csn0;
  logic             spi_csn1;
  logic             spi_csn2;
  logic             spi_csn3;
  logic       [1:0] spi_mode;

  logic             spi_sdo0;
  logic             spi_sdo1;
  logic             spi_sdo2;
  logic             spi_sdo3;

  logic             spi_sdi0;
  logic             spi_sdi1;
  logic             spi_sdi2;
  logic             spi_sdi3;

  apb_spi_master #(
    .BUFFER_DEPTH   (10),
    .APB_ADDR_WIDTH (12)
  ) dut (
    .HCLK      (clk),
    .HRESETn   (rst),
    .PADDR     (apbIf.paddr),
    .PWDATA    (apbIf.pwdata),
    .PWRITE    (apbIf.pwrite),
    .PSEL      (apbIf.psel),
    .PENABLE   (apbIf.penable),
    .PRDATA    (apbIf.prdata),
    .PREADY    (apbIf.pready),
    .PSLVERR   (apbIf.pslverr),
    .events_o  (events_o),
    .spi_clk   (spi_clk),
    .spi_csn0  (spi_csn0),
    .spi_csn1  (spi_csn1),
    .spi_csn2  (spi_csn2),
    .spi_csn3  (spi_csn3),
    .spi_mode  (spi_mode),
    .spi_sdo0  (spi_sdo0),
    .spi_sdo1  (spi_sdo1),
    .spi_sdo2  (spi_sdo2),
    .spi_sdo3  (spi_sdo3),
    .spi_sdi0  (spi_sdi0),
    .spi_sdi1  (spi_sdi1),
    .spi_sdi2  (spi_sdi2),
    .spi_sdi3  (spi_sdi3)
  );

  //-------------------------------------------------------
  // DUT outputs -> SpiInterface (seen by the slave BFM)
  // Single driver per signal: nothing else may drive these (master BFM removed).
  //-------------------------------------------------------
  wire [3:0] spiCsn = {spi_csn3, spi_csn2, spi_csn1, spi_csn0};   // requires NO_OF_SLAVES <= 4

  assign spiInterface.sclk  = spi_clk;
  assign spiInterface.cs    = spiCsn[NO_OF_SLAVES-1:0];
  assign spiInterface.mosi0 = spi_sdo0;
  assign spiInterface.mosi1 = spi_sdo1;
  assign spiInterface.mosi2 = spi_sdo2;
  assign spiInterface.mosi3 = spi_sdo3;

  //-------------------------------------------------------
  // SpiInterface (slave BFM MISO) -> DUT inputs
  // Standard (single-lane) mode: spi_sdi1 is MISO in the Pulpino SPI master.
  // If reads come back all zeros, check spi_master_rx.sv and try spi_sdi0 instead.
  //-------------------------------------------------------
  assign spi_sdi0 = spiInterface.miso0;
  assign spi_sdi1 = 1'b0;
  assign spi_sdi2 = 1'b0;
  assign spi_sdi3 = 1'b0;

  //-------------------------------------------------------
  // Make the APB interface visible to the UVM tests
  // (the slave BFMs register themselves, as in the stock hdlTop)
  //-------------------------------------------------------
  initial begin
    uvm_config_db #(virtual ApbSimpleIf)::set(null, "*", "ApbSimpleIf", apbIf);
  end

  //-------------------------------------------------------
  // Waveform dump
  //-------------------------------------------------------
  initial begin
    $dumpfile("waveform.vcd");
    $dumpvars(0, SpiHdlTop);
  end

  initial begin
    $shm_open("waves.shm");
    $shm_probe("AS");
  end

endmodule : SpiHdlTop

`endif
