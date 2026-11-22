`timescale 1ns/1ps

module tb_apb_interrupt;

  	initial begin
      $dumpfile("apb_interrupt.vcd");
      $dumpvars(0, tb_apb_interrupt);
    end
    // ---------------------------------------------------------
    // PARAMETERS
    // ---------------------------------------------------------
    localparam CLK_PERIOD = 10;

    // ---------------------------------------------------------
    // APB SIGNALS
    // ---------------------------------------------------------
    logic         clk;
    logic         PRESETn;
    logic         PSEL;
    logic         PENABLE;
    logic         PWRITE;
  	logic [11:0]  PADDR;
    logic [31:0]  PWDATA;
    wire  [31:0]  PRDATA;
    wire          PREADY;
    wire          PSLVERR;

    // ---------------------------------------------------------
    // IRQ SIGNALS
    // ---------------------------------------------------------
    logic [8:0] irq;

    wire interrupt;

    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------
    apb_interrupt dut (
        .HCLK       (clk),
        .HRESETn    (PRESETn),
        .PSEL       (PSEL),
        .PENABLE    (PENABLE),
        .PWRITE     (PWRITE),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),
        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PSLVERR    (PSLVERR),

        .i2c0       (irq[0]),
        .i2c1       (irq[1]),
        .spi        (irq[2]),
        .tc0        (irq[3]),
        .to0        (irq[4]),
        .tc1        (irq[5]),
        .to1        (irq[6]),
        .uart       (irq[7]),
        .gpio       (irq[8]),

        .irq_valid  (interrupt)
    );


    // ---------------------------------------------------------
    // CLOCK
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ---------------------------------------------------------
    // APB WRITE TASK
    // ---------------------------------------------------------
    task automatic apb_write(
        input [11:0] addr,
        input [31:0] data
    );
    begin
        @(posedge clk);

        PSEL    = 1'b1;
        PENABLE = 1'b0;
        PWRITE  = 1'b1;
        PADDR   = addr;
        PWDATA  = data;

        @(posedge clk);

        PENABLE = 1'b1;

        @(posedge clk);

        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 12'h0;
        PWDATA  = 32'h0;

        $display("[WRITE] ADDR = %h DATA = %h", addr, data);
    end
    endtask

    // ---------------------------------------------------------
    // APB READ TASK
    // ---------------------------------------------------------
    task automatic apb_read(
        input  [11:0] addr,
        output [31:0] data
    );
    begin
        @(posedge clk);

        PSEL    = 1'b1;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = addr;

        @(posedge clk);

        PENABLE = 1'b1;

        @(posedge clk);

        data = PRDATA;

        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PADDR   = 12'h0;

        $display("[READ ] ADDR = %h DATA = %h", addr, data);
    end
    endtask

    // ---------------------------------------------------------
    // RESET TASK
    // ---------------------------------------------------------
    task automatic reset_dut;
    begin
        PRESETn = 1'b0;

        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;

        irq = 9'b0;

        repeat(5) @(posedge clk);

        PRESETn = 1'b1;

        repeat(2) @(posedge clk);

        $display("\n========== RESET DONE ==========\n");
    end
    endtask

    // ---------------------------------------------------------
    // CHECK TASK
    // ---------------------------------------------------------
  	integer pass = 0, fail = 0;
    task automatic check_value(
        input [31:0] actual,
        input [31:0] expected,
        input [255:0] msg
    );
    begin
      if(actual === expected) begin
            $display("[PASS] %s | Expected = %h Actual = %h",
                      msg, expected, actual);
        	pass++;
      end
        else begin
            $display("[FAIL] %s | Expected = %h Actual = %h",
                      msg, expected, actual);
          fail++;
        end
    end
    endtask

    // ---------------------------------------------------------
    // TEST VARIABLES
    // ---------------------------------------------------------
  logic [31:0] rdata, sample;

    // ---------------------------------------------------------
    // MAIN TEST
    // ---------------------------------------------------------
    initial begin

        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------
        reset_dut();

        // -----------------------------------------------------
        // INITIAL VALUE CHECK
        // -----------------------------------------------------
        $display("\n========== INITIAL VALUE TEST ==========\n");

        apb_read(REG_INT_ENABLE, rdata);
        check_value(rdata, 32'h0, "ENABLE RESET");

        apb_read(REG_INT_PENDING, rdata);
        check_value(rdata, 32'h0, "PENDING RESET");

        apb_read(REG_INT_CLAIM_ID, rdata);
        check_value(rdata, 32'h0, "CLAIM ID RESET");

        // -----------------------------------------------------
        // ENABLE TEST
        // -----------------------------------------------------
        $display("\n========== ENABLE TEST ==========\n");
      	sample = $urandom;

        apb_write(REG_INT_ENABLE, 32'h000001FF);

        apb_read(REG_INT_ENABLE, rdata);
        check_value(rdata, 32'h000001FF, "ENABLE WRITE/READ");

        $display("\n========== ARBITRATION TEST ==========\n");

        irq[2] = 1'b1; irq[8] = 1'b1;irq[0] = 1'b1; #5; irq[2] = 1'b0; irq[8] = 1'b0;irq[0] = 1'b0;

        apb_read(REG_INT_PENDING, rdata); 

        apb_read(REG_INT_CLAIM_ID, rdata); 
        apb_read(REG_INT_CLAIM_ID, rdata);
        apb_read(REG_INT_CLAIM_ID, rdata);

        // -----------------------------------------------------
        // END
        // -----------------------------------------------------
        $display("\n========== ALL TESTS COMPLETED ==========\n");
      	$display("TEST ANALYSIS:");
      	$display("PASS : %d", pass);
      	$display("FAIL : %d", fail);

        #100;
        $finish;
    end

endmodule