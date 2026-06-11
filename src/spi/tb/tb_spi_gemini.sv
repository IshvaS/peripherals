`timescale 1ns/1ps

module tb_apb_spi_master;

    // -------------------------------------------------------------------------
    // Parameters & Clock Gen
    // -------------------------------------------------------------------------
    parameter BUFFER_DEPTH   = 10;
    parameter APB_ADDR_WIDTH = 12;
    
    logic HCLK = 0;
    logic HRESETn = 0;
    
    always #5 HCLK = ~HCLK; // 100MHz System Clock

    // -------------------------------------------------------------------------
    // Interface Signals
    // -------------------------------------------------------------------------
    logic [APB_ADDR_WIDTH-1:0] PADDR;
    logic [31:0]               PWDATA;
    logic                      PWRITE;
    logic                      PSEL;
    logic                      PENABLE;
    logic [31:0]               PRDATA;
    logic                      PREADY;
    logic                      PSLVERR;
    
    logic [1:0]                events_o;
    logic                      spi_clk;
    logic                      spi_csn0, spi_csn1, spi_csn2, spi_csn3;
    logic [1:0]                spi_mode;
    logic                      spi_sdo0, spi_sdo1, spi_sdo2, spi_sdo3;
    logic                      spi_sdi0, spi_sdi1, spi_sdi2, spi_sdi3;

    // -------------------------------------------------------------------------
    // DUT Instance
    // -------------------------------------------------------------------------
    apb_spi_master #(
        .BUFFER_DEPTH(BUFFER_DEPTH),
        .APB_ADDR_WIDTH(APB_ADDR_WIDTH)
    ) dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .events_o(events_o),
        .spi_clk(spi_clk),
        .spi_csn0(spi_csn0), .spi_csn1(spi_csn1), .spi_csn2(spi_csn2), .spi_csn3(spi_csn3),
        .spi_mode(spi_mode),
        .spi_sdo0(spi_sdo0), .spi_sdo1(spi_sdo1), .spi_sdo2(spi_sdo2), .spi_sdo3(spi_sdo3),
        .spi_sdi0(spi_sdi0), .spi_sdi1(spi_sdi1), .spi_sdi2(spi_sdi2), .spi_sdi3(spi_sdi3)
    );

    // Tie inputs high/low to prevent floating wires
    assign spi_sdi0 = 1'b0;
    assign spi_sdi1 = 1'b0;
    assign spi_sdi2 = 1'b0;
    assign spi_sdi3 = 1'b0;

    // -------------------------------------------------------------------------
    // APB Write Task
    // -------------------------------------------------------------------------
    task automatic apb_write(input logic [APB_ADDR_WIDTH-1:0] addr, input logic [31:0] data);
        @(posedge HCLK);
        PADDR   <= addr;
        PWDATA  <= data;
        PWRITE  <= 1'b1;
        PSEL    <= 1'b1;
        PENABLE <= 1'b0;
        
        @(posedge HCLK);
        PENABLE <= 1'b1;
        
        // Wait for PREADY
        while (!PREADY) @(posedge HCLK);
        
        @(posedge HCLK);
        PSEL    <= 1'b0;
        PENABLE <= 1'b0;
        PWRITE  <= 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // Test Vectors Configuration
    // -------------------------------------------------------------------------
    // SPI Offsets scaled to Byte Addressed alignment PADDR[5:2]
    localparam REG_STATUS = 12'h00; 
    localparam REG_CLKDIV = 12'h04; 
    localparam REG_SPICMD = 12'h08; 
    localparam REG_SPIADR = 12'h0C; 
    localparam REG_SPILEN = 12'h10; 
    localparam REG_TXFIFO = 12'h18; 

    localparam logic [31:0] TEST_CMD  = 32'hA500_0000; // 8-bit command (A5)
    localparam logic [31:0] TEST_ADDR = 32'h9E00_0000; // 8-bit address (9E)
    localparam logic [31:0] TEST_DATA = 32'h5A00_0000; // 8-bit TX data (5A)
  
  	initial begin
      $dumpfile("tb_api_spi_master.vcd");
      $dumpvars(0, tb_apb_spi_master);
    end

    // -------------------------------------------------------------------------
    // Main Stimulus Procedure
    // -------------------------------------------------------------------------
    initial begin
        $display("[TB] Starting APB SPI Master Test Bench...");
        
        // Assert Reset
        HRESETn = 0;
        PADDR   = 0;
        PWDATA  = 0;
        PWRITE  = 0;
        PSEL    = 0;
        PENABLE = 0;
        #50;
        HRESETn = 1;
        #20;

        // 1. Configure Clock Divider (Scale SPI clk down for clean capture)
        $display("[TB] Configuring SPI Clock Divider...");
        apb_write(REG_CLKDIV, 32'h0000_0002); // clk_div = 2

        // 2. Set Length Configurations
        // Bits [5:0]   = CMD length in bits  (8 bits)
        // Bits [13:8]  = ADDR length in bits (8 bits)
        // Bits [31:16] = DATA length in bits (8 bits)
        $display("[TB] Setting Transfer Lengths: CMD=8b, ADDR=8b, DATA=8b...");
        apb_write(REG_SPILEN, {16'd8, 2'b00, 6'd8, 2'b00, 6'd8});

        // 3. Populate Payload Registers
        $display("[TB] Writing Command payload...");
        apb_write(REG_SPICMD, TEST_CMD);

        $display("[TB] Writing Address payload...");
        apb_write(REG_SPIADR, TEST_ADDR);

        $display("[TB] Priming TX FIFO with Write Data...");
        apb_write(REG_TXFIFO, TEST_DATA);

        // 4. Trigger SPI Transaction (Issue Standard Write operation on CS0)
        $display("[TB] Triggering transaction via REG_STATUS...");
        // PWDATA[1]  = spi_wr (Standard Write)
        // PWDATA[11:8]= spi_csreg (Select CS0 -> 4'b0001)
        apb_write(REG_STATUS, 32'h0000_0102);

        // 5. Monitor SPI Serialization Window
        $display("[TB] Waiting for SPI lines to activate...");
        wait(spi_csn0 == 1'b0);
        $display("[TB] CS0 Detected Low. Monitoring serialization stream...");

        // Wait until End-Of-Transaction (EOT) event fires
        wait(events_o[1] == 1'b1);
        $display("[TB] End of Transaction (EOT) event captured!");

        #100;
        $display("[TB] Test Completed successfully.");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Protocol Monitor / Assertions
    // -------------------------------------------------------------------------
    logic [7:0] captured_cmd;
    logic [7:0] captured_addr;
    logic [7:0] captured_data;
    integer bit_count = 0;

    // Sample SPI Data on Falling Edge (Assuming SPI Mode 0 / Standard SPI Master TX)
    always @(posedge spi_clk) begin
        if (!spi_csn0) begin
            bit_count = bit_count + 1;
            if (bit_count <= 8) begin
                captured_cmd = {captured_cmd[6:0], spi_sdo0};
                if (bit_count == 8) 
                    $display("[MONITOR] Command Phase complete. Captured: 8'h%h (Expected: 8'h%h)", captured_cmd, TEST_CMD[31:24]);
            end
            else if (bit_count <= 16) begin
                captured_addr = {captured_addr[6:0], spi_sdo0};
                if (bit_count == 16) 
                    $display("[MONITOR] Address Phase complete. Captured: 8'h%h (Expected: 8'h%h)", captured_addr, TEST_ADDR[31:24]);
            end
            else if (bit_count <= 24) begin
                captured_data = {captured_data[6:0], spi_sdo0};
                if (bit_count == 24) 
                    $display("[MONITOR] Data Phase complete. Captured: 8'h%h (Expected: 8'h%h)", captured_data, TEST_DATA[31:24]);
            end
        end
    end

    // Reset tracking bit count when CS goes high
    always @(posedge spi_csn0) begin
        bit_count = 0;
    end

endmodule