//Write 4 bytes with DUMMY 8 CYCLES
`timescale 1ns/1ps

module tb_spi_write;

    // APB Interface Signals
    logic        HCLK;
    logic        HRESETn;
    logic [11:0] PADDR;
    logic [31:0] PWDATA; // Standard 32-bit width vector
    logic        PWRITE;
    logic        PSEL; 
    logic        PENABLE;
    logic [31:0] PRDATA;
    logic        PREADY;   // Managed via protocol tasks
    logic        PSLVERR;

    logic [1:0]  events_o;

    // SPI Interface Signals
    logic        spi_clk;
    logic        spi_sdo0, spi_sdo1, spi_sdo2, spi_sdo3;
    logic        spi_csn0, spi_csn1, spi_csn2, spi_csn3;
    logic        spi_sdi0, spi_sdi1, spi_sdi2, spi_sdi3;
    logic [1:0]  spi_mode;

    // Device Under Test (DUT)
    apb_spi_master dut (.*);

    // Register Mapping Offsets (Explicit 12-bit width matching PADDR)
    localparam logic [11:0] REG_STATUS = 12'h000; 
    localparam logic [11:0] REG_CLKDIV = 12'h004; 
    localparam logic [11:0] REG_SPICMD = 12'h008; 
    localparam logic [11:0] REG_SPIADR = 12'h00C; 
    localparam logic [11:0] REG_SPILEN = 12'h010; 
    localparam logic [11:0] REG_SPIDUM = 12'h014; 
    localparam logic [11:0] REG_TXFIFO = 12'h018; 
    localparam logic [11:0] REG_RXFIFO = 12'h020; 
    localparam logic [11:0] REG_INTCFG = 12'h024; 
    localparam logic [11:0] REG_INTSTA = 12'h028;

    // Global variable to catch reads
    logic [31:0] read_data;

    // ========================================================
    // 1. STABLE CLOCK & ENVIRONMENT SETUP
    // ========================================================
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK; // 100 MHz Clock Generation
    end

    initial begin
        $dumpfile("tb_spi.vcd");
        $dumpvars(0, tb_spi);
    end

    // ========================================================
    // 2. FIXED PROTOCOL DRIVING TASKS
    // ========================================================
    
    // Fixed: Clean 2-cycle sequence avoiding edge race conditions
    task automatic apb_write(
        input logic [11:0] addr,
        input logic [31:0] data
    );
    begin
        // Cycle 1: Setup Phase
        @(posedge HCLK);
        PADDR   = addr;
        PWDATA  = data;
        PSEL    = 1'b1;
        PWRITE  = 1'b1;
        PENABLE = 1'b0;
        
        // Cycle 2: Access Phase
        @(posedge HCLK);
        PENABLE = 1'b1;

        // End of Cycle 2: Hold lines until next edge for clean DUT sampling
        @(posedge HCLK);
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        
        $display("[WRITE] Addr = 0x%h Data = 0x%h", addr, data);
    end
    endtask

    // Fixed: Samples PRDATA exactly at the close of the Access window
    task automatic apb_read(
        input  logic [11:0] addr,
        output logic [31:0] data_out
    );
    begin
        // Cycle 1: Setup Phase
        @(posedge HCLK);
        PADDR   = addr;
        PSEL    = 1'b1;
        PWRITE  = 1'b0;
        PENABLE = 1'b0;
        
        // Cycle 2: Access Phase
        @(posedge HCLK);
        PENABLE = 1'b1;

        // End of Cycle 2: Capture PRDATA on the clock edge, then drop control lines
        @(posedge HCLK);
        data_out = PRDATA; 
        PSEL     = 1'b0;
        PENABLE  = 1'b0;
        
        $display("[READ] Addr = 0x%h Data = 0x%h", addr, data_out);
    end
    endtask

    task automatic reset_dut;
    begin
        $display("======== Resetting DUT =======");
        @(posedge HCLK);
        HRESETn = 1'b0;
        repeat(5) @(posedge HCLK);
        @(posedge HCLK);
        HRESETn = 1'b1;
        repeat(2) @(posedge HCLK);
        $display("======== Reset DUT complete =======");
    end
    endtask

    task automatic init;
    begin
        $display("======== Initializing DUT =======");
        PADDR   = 12'b0;
        PWDATA  = 32'b0;
        PWRITE  = 1'b0;
        PSEL    = 1'b0; 
        PENABLE = 1'b0;
        HRESETn = 1'b1;
        $display("======== Initialization complete =======");
    end
    endtask
  
  always@(posedge HCLK)begin
    $display("CMD = %h ADR = %h CMD_LEN = %h ADR_LEN = %h DATA_LEN = %h WR = %b RD = %b STAT = %h",
      dut.spi_cmd,
dut.spi_addr,
dut.spi_cmd_len,
dut.spi_addr_len,
dut.spi_data_len,
dut.spi_wr,
dut.spi_rd,
      dut.spi_ctrl_status);
  end

    // ========================================================
    // 3. MASTER CENTRALIZED EXECUTION TIMELINE
    // ========================================================
    initial begin
        $display("TB STARTED @ %0t", $time);
        
        // Step 1: Establish baseline driving states at time #0
        init();
        
        // Step 2: Let clock lines stabilize for 10ns before pulsing reset
        #10; 
        reset_dut();

        // Step 3: Run Register Configuration Commands
        apb_write(REG_CLKDIV, 32'h0000000F);
        apb_write(REG_SPICMD, 32'hA5000000);
      	apb_read(REG_SPICMD, read_data);
		$display("SPICMD = %h", read_data);
        apb_write(REG_SPIADR, 32'h5A000000);
      	apb_write(REG_TXFIFO, 32'HF0F0F0F0);
        apb_write(REG_SPILEN, 32'h0010_08_08); // CMD_LEN=16, ADR_LEN=8, DATA_LEN=8
        apb_write(REG_SPIDUM, 32'h0008_0000); //DUMMY 8 CYCLES 
      
      	apb_write(REG_STATUS, 32'h00000102);

        // Step 4: Safely await the core event return signal from the DUT
        $display("Awaiting transaction completion...");
        @(posedge HCLK); 
        wait(events_o[1] == 1'b1);
        
        $display("SPI transaction completed at time %0t", $time);
        #50;
        $finish;
    end

endmodule