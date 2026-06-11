// QSPI READ 1 DATA WORD WITH DUMMY 8 CYCLES
`timescale 1ns/1ps

module tb_spi;

    // APB Interface Signals
    logic        HCLK;
    logic        HRESETn;
    logic [11:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PSEL; 
    logic        PENABLE;
    logic [31:0] PRDATA;
    logic        PREADY;
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

    // Register Mapping Offsets
    localparam logic [11:0] REG_STATUS = 12'h000; 
    localparam logic [11:0] REG_CLKDIV = 12'h004; 
    localparam logic [11:0] REG_SPICMD = 12'h008; 
    localparam logic [11:0] REG_SPIADR = 12'h00C; 
    localparam logic [11:0] REG_SPILEN = 12'h010; 
    localparam logic [11:0] REG_SPIDUM = 12'h014; 
    localparam logic [11:0] REG_RXFIFO = 12'h020; 

    logic [31:0] spi_rx_word;

    // Clock Gen
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end

    initial begin
        $dumpfile("tb_spi.vcd");
        $dumpvars(0, tb_spi);
    end

    // APB Write Task
    task automatic apb_write(input logic [11:0] addr, input logic [31:0] data);
    begin
        @(posedge HCLK);
        PADDR   = addr; PWDATA  = data; PSEL    = 1'b1; PWRITE  = 1'b1; PENABLE = 1'b0;
        @(posedge HCLK);
        PENABLE = 1'b1;
        @(posedge HCLK);
        PSEL    = 1'b0; PENABLE = 1'b0; PWRITE  = 1'b0;
    end
    endtask

    // APB Read Task
    task automatic apb_read(input logic [11:0] addr, output logic [31:0] data_out);
    begin
        @(posedge HCLK);
        PADDR   = addr; PSEL    = 1'b1; PWRITE  = 1'b0; PENABLE = 1'b0;
        @(posedge HCLK);
        PENABLE = 1'b1;
        @(posedge HCLK);
        data_out = PRDATA; PSEL   = 1'b0; PENABLE  = 1'b0;
    end
    endtask

    // ========================================================
    // CENTRALIZED EXECUTION TIMELINE
    // ========================================================
    initial begin
        // Reset Setup
        HRESETn = 1'b1; PADDR = 0; PWDATA = 0; PSEL = 0; PENABLE = 0;
        #10; HRESETn = 1'b0; repeat(5) @(posedge HCLK); HRESETn = 1'b1; repeat(2) @(posedge HCLK);

        $display("[TB] Configuring Clock Divider...");
        apb_write(REG_CLKDIV, 32'h00000002); // Set faster clock for visible waves
        
        $display("[TB] Loading SPI Command and Address...");
        apb_write(REG_SPICMD, 32'hEB000000); // Standard Fast-Read Quad CMD (0xEB)
        apb_write(REG_SPIADR, 32'h12345600); // 24-bit Address payload
        
        $display("[TB] Setting Transfer Lengths (CMD=8b, ADDR=24b, RX_DATA=32b)...");
        // CMD_LEN (bits 5:0) = 8, ADDR_LEN (bits 13:8) = 24, DATA_LEN (bits 31:16) = 32
        apb_write(REG_SPILEN, 32'h00201808); 
        
        $display("[TB] Setting 8 Dummy Cycles for Read...");
        // spi_dummy_rd is mapped to bits [15:0] of REG_SPIDUM
        apb_write(REG_SPIDUM, 32'h00000008); 
      
        $display("[TB] Triggering Quad SPI Read Transaction on CS0...");
        // PWDATA[2] = 1 (spi_qrd), PWDATA[11:8] = 4'b0001 (Select CS0)
        apb_write(REG_STATUS, 32'h00000104);

        $display("Awaiting transaction completion...");
        @(posedge HCLK); 
        wait(events_o[1] == 1'b1); // Wait for End of Transaction
        $display("SPI transaction completed!");
        
        $display("[TB] Reading Data out of REG_RXFIFO...");
        apb_read(REG_RXFIFO, spi_rx_word);
        $display("[TB] Success! Data read from SPI Slave: 0x%h", spi_rx_word);

        #50;
        $finish;
    end

    // ========================================================
    // 4. QUAD SLAVE EMULATION (Drives 4 data lines simultaneously)
    // ========================================================
    // Responses must be driven 4 bits at a time (Nibble by Nibble)
    logic [31:0] slave_response_data = 32'hDEADBEEF;
    integer nibble_idx = 7; // 8 nibbles in a 32-bit word (7 down to 0)

    initial begin
        spi_sdi0 = 1'b0; spi_sdi1 = 1'b0; spi_sdi2 = 1'b0; spi_sdi3 = 1'b0;
        forever begin
            // Change lines on the rising edge of the SPI clock so the master captures cleanly
            @(posedge spi_clk);
            
            if (!spi_csn0 && (dut.u_spictrl.state == dut.u_spictrl.DATA_RX)) begin
                // Split the current active 4-bit nibble across the 4 SDI input lines
                spi_sdi3 = slave_response_data[(nibble_idx * 4) + 3];
                spi_sdi2 = slave_response_data[(nibble_idx * 4) + 2];
                spi_sdi1 = slave_response_data[(nibble_idx * 4) + 1];
                spi_sdi0 = slave_response_data[(nibble_idx * 4) + 0];
                
                if (nibble_idx == 0) 
                    nibble_idx = 7; // Reset index for multi-word sequences
                else 
                    nibble_idx = nibble_idx - 1;
            end else begin
                // Pull lines low when outside the active read window
                spi_sdi0 = 1'b0; spi_sdi1 = 1'b0; spi_sdi2 = 1'b0; spi_sdi3 = 1'b0;
            end
        end
    end

endmodule