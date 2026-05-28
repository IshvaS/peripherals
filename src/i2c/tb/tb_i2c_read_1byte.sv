`timescale 1ns / 1ns

module tb_apb_i2c_read_1byte;

    parameter APB_ADDR_WIDTH = 32;
    parameter CLK_PERIOD     = 100; // Explicitly 100 ns (10 MHz)

    // Signals
    logic                      HCLK;
    logic                      HRESETn;
    logic [APB_ADDR_WIDTH-1:0] PADDR;
    logic               [31:0] PWDATA;
    logic                      PWRITE;
    logic                      PSEL;
    logic                      PENABLE;
    logic               [31:0] PRDATA;
    logic                      PREADY;
    logic                      PSLVERR;
    logic                      interrupt_o;

    logic                      scl_pad_i;
    logic                      scl_pad_o;
    logic                      scl_padoen_o;
    logic                      sda_pad_i;
    logic                      sda_pad_o;
    logic                      sda_padoen_o;

    logic                      slave_scl_o;
    logic                      slave_sda_o;

    // Register Mapping
    localparam REG_CLK_PRESCALER = 32'h00;
    localparam REG_CTRL          = 32'h04;
    localparam REG_RX            = 32'h08;
    localparam REG_STATUS        = 32'h0C;
    localparam REG_TX            = 32'h10;
    localparam REG_CMD           = 32'h14;

    // Clock Gen
    initial begin
        HCLK = 0;
        forever #(CLK_PERIOD/2) HCLK = ~HCLK;
    end

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_apb_i2c_read_1byte);
    end

    always @(posedge scl_pad_i or negedge scl_pad_i) begin
        $display("[BUS] Time=%0t SCL=%0b SDA=%0b SDA_OEN=%0b SLAVE_DRIVE=%0b",
                 $time, scl_pad_i, sda_pad_i, sda_padoen_o, slave_sda_o);
    end

    // DUT Instantiation
    apb_i2c #(.APB_ADDR_WIDTH(APB_ADDR_WIDTH)) dut (.*);

    // Emulated Wired-AND Open-Drain Bus logic
    assign scl_pad_i = (!scl_padoen_o ? scl_pad_o : 1'b1) & slave_scl_o;
    assign sda_pad_i = (!sda_padoen_o ? sda_pad_o : 1'b1) & slave_sda_o;

    // Synchronized Slave Behavioral Model
    logic [7:0] rx_byte;
    int bit_idx;
    
    initial begin
        slave_scl_o = 1'b1;
        slave_sda_o = 1'b1;
        
        forever begin
            @(negedge sda_pad_i);
            if (scl_pad_i === 1'b1) begin
                $display("[Slave] START");
                
                rx_byte = 8'h0;
                for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
                    @(posedge scl_pad_i);
                    rx_byte[bit_idx] = sda_pad_i;
                end
                
                @(negedge scl_pad_i); #1;
                if (rx_byte == 8'h9C) begin 
                    $display("[Slave] Addr Match: 0x4E [WRITE]");
                    slave_sda_o = 1'b0; 
                    @(posedge scl_pad_i); 
                    @(negedge scl_pad_i); #1; 
                    slave_sda_o = 1'b1; 
                    
                    rx_byte = 8'h0;
                    for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
                        @(posedge scl_pad_i);
                        rx_byte[bit_idx] = sda_pad_i;
                    end
                    $display("[Slave] Pointer Offset: 0x%0h", rx_byte);
                    
                    @(negedge scl_pad_i); #1;
                    slave_sda_o = 1'b0; 
                    @(posedge scl_pad_i);
                    @(negedge scl_pad_i); #1;
                    slave_sda_o = 1'b1; 
                    
                end else if (rx_byte == 8'h9D) begin 
                    $display("[Slave] Addr Match: 0x4E [READ]");
                    slave_sda_o = 1'b0; 
                    @(posedge scl_pad_i);
                    
                    rx_byte = 8'hDE; 
                    for (bit_idx = 7; bit_idx >= 0; bit_idx--) begin
                        @(negedge scl_pad_i); #1; 
                        slave_sda_o = rx_byte[bit_idx];
                    end
                    
                    @(negedge scl_pad_i); #1;
                    slave_sda_o = 1'b1; 
                    @(posedge scl_pad_i);
                    if (sda_pad_i === 1'b1)
                        $display("[Slave] Received NACK. Stopping.");
                end
            end
        end
    end

    // APB Driver Tasks
    task automatic apb_write(input logic [APB_ADDR_WIDTH-1:0] addr, input logic [31:0] data);
        @(posedge HCLK);
        PADDR   = addr;
        PWDATA  = data;
        PWRITE  = 1'b1;
        PSEL    = 1'b1;
        PENABLE = 1'b0;
        @(posedge HCLK);
        PENABLE = 1'b1;
        @(posedge HCLK);
        while (!PREADY) @(posedge HCLK);
        PSEL    = 1'b0;
        PENABLE = 1'b0;
    endtask

    task automatic apb_read(input logic [APB_ADDR_WIDTH-1:0] addr, output logic [31:0] data);
        @(posedge HCLK);
        PADDR   = addr;
        PWRITE  = 1'b0;
        PSEL    = 1'b1;
        PENABLE = 1'b0;
        @(posedge HCLK);
        PENABLE = 1'b1;
        @(posedge HCLK);
        while (!PREADY) @(posedge HCLK);
        data    = PRDATA;
        PSEL    = 1'b0;
        PENABLE = 1'b0;
    endtask

    task automatic wait_i2c_done();
        logic [31:0] status;
        do begin
            repeat(10) @(posedge HCLK);
            apb_read(REG_STATUS, status);
        end while (status[1] == 1'b1); // Poll TIP bit [cite: 57, 371]
    endtask

    // Scenario Run
    initial begin
        logic [31:0] rdata;
        
        HRESETn = 1'b1; PADDR = '0; PWDATA = '0; PWRITE = 1'b0; PSEL = 1'b0; PENABLE = 1'b0;
        #100; HRESETn = 1'b0; #100; HRESETn = 1'b1;
        repeat(5) @(posedge HCLK);

        $display("--- Start: Example 2 Test Execution ---");

        // Step 0: Scaled configuration safe for 100ns clock cycles
        apb_write(REG_CLK_PRESCALER, 16'h0063); 
        apb_write(REG_CTRL,          8'h80);    

        // Step 1: Write Slave Addr 0x4E (WR frame = 0x9C) [cite: 406]
        apb_write(REG_TX,  8'h9C);
        apb_write(REG_CMD, 8'h90); 
        wait_i2c_done();

        // Step 2: Write Target Offset 0x20 [cite: 405, 407]
        apb_write(REG_TX,  8'h20);
        apb_write(REG_CMD, 8'h10); 
        wait_i2c_done();

        // Step 3: Repeated START + Addr 0x4E (RD frame = 0x9D) [cite: 405, 408]
        apb_write(REG_TX,  8'h9D);
        apb_write(REG_CMD, 8'h90); 
        wait_i2c_done();

        // Step 4: Host Receive + NACK + STOP [cite: 408]
        apb_write(REG_CMD, 8'h68); 
        wait_i2c_done();

        // Step 5: Read Buffer Capture
        apb_read(REG_RX, rdata);
        $display("[Master] RX Captured Data: 0x%0h", rdata[7:0]);
        
        if (rdata[7:0] == 8'hDE)
            $display("STATUS: PASSED");
        else
            $display("STATUS: FAILED");

        #500;
        $finish;
    end

endmodule