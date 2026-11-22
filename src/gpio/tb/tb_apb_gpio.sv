`timescale 1ns/1ps

module tb_apb_gpio;

  	initial begin
        $dumpfile("apb_gpio.vcd");
        $dumpvars(0, tb_apb_gpio);
    end
    // ---------------------------------------------------------
    // PARAMETERS
    // ---------------------------------------------------------
    localparam CLK_PERIOD = 10;

    // ---------------------------------------------------------
    // APB SIGNALS
    // ---------------------------------------------------------
    logic         PCLK;
    logic         PRESETn;
    logic         PSEL;
    logic         PENABLE;
    logic         PWRITE;
    logic [31:0]  PADDR;
    logic [31:0]  PWDATA;
    wire  [31:0]  PRDATA;
    wire          PREADY;
    wire          PSLVERR;

    // ---------------------------------------------------------
    // GPIO SIGNALS
    // ---------------------------------------------------------
    logic [31:0] gpio_in;
    wire  [31:0] gpio_out;
    wire  [31:0] gpio_dir;
    wire  [31:0][3:0] gpio_padcfg;

    wire interrupt;

    // ---------------------------------------------------------
    // DUT
    // ---------------------------------------------------------
    apb_gpio dut (
        .HCLK       (PCLK),
        .HRESETn    (PRESETn),
        .PSEL       (PSEL),
        .PENABLE    (PENABLE),
        .PWRITE     (PWRITE),
        .PADDR      (PADDR),
        .PWDATA     (PWDATA),
        .PRDATA     (PRDATA),
        .PREADY     (PREADY),
        .PSLVERR    (PSLVERR),

        .gpio_in    (gpio_in),
        .gpio_out   (gpio_out),
        .gpio_dir   (gpio_dir),
        .gpio_padcfg(gpio_padcfg),

        .interrupt  (interrupt)
    );

    // ---------------------------------------------------------
    // FIXED REGISTER MAP
    // ---------------------------------------------------------
    localparam REG_PADDIR     = 32'h00; // BASEADDR+0x00
    localparam REG_PADIN      = 32'h04; // BASEADDR+0x04
    localparam REG_PADOUT     = 32'h08; // BASEADDR+0x08
    localparam REG_PADOUTSET  = 32'h0C; // BASEADDR+0x0C
    localparam REG_PADOUTCLR  = 32'h10; // BASEADDR+0x10

    localparam REG_INTEN      = 32'h14; // BASEADDR+0x14
    localparam REG_INTMASK    = 32'h18; // BASEADDR+0x18
    localparam REG_INTSET     = 32'h1C; // BASEADDR+0x1C
    localparam REG_INTCLR     = 32'h20; // BASEADDR+0x20
    localparam REG_INTSTATUS  = 32'h24; // BASEADDR+0x24
    localparam REG_INTTYPE0   = 32'h28; // BASEADDR+0x28
    localparam REG_INTTYPE1   = 32'h2C; // BASEADDR+0x2C

    localparam REG_INTPADCFG0 = 32'h30; // BASEADDR+0x30
    localparam REG_INTPADCFG1 = 32'h34; // BASEADDR+0x34
    localparam REG_INTPADCFG2 = 32'h38; // BASEADDR+0x38
    localparam REG_INTPADCFG3 = 32'h3C; // BASEADDR+0x3C

    // ---------------------------------------------------------
    // CLOCK
    // ---------------------------------------------------------
    initial begin
        PCLK = 0;
        forever #(CLK_PERIOD/2) PCLK = ~PCLK;
    end

    // ---------------------------------------------------------
    // APB WRITE TASK
    // ---------------------------------------------------------
    task automatic apb_write(
        input [31:0] addr,
        input [31:0] data
    );
    begin
        @(posedge PCLK);

        PSEL    = 1'b1;
        PENABLE = 1'b0;
        PWRITE  = 1'b1;
        PADDR   = addr;
        PWDATA  = data;

        @(posedge PCLK);

        PENABLE = 1'b1;

        @(posedge PCLK);

        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 32'h0;
        PWDATA  = 32'h0;

        $display("[WRITE] ADDR = %h DATA = %h", addr, data);
    end
    endtask

    // ---------------------------------------------------------
    // APB READ TASK
    // ---------------------------------------------------------
    task automatic apb_read(
        input  [31:0] addr,
        output [31:0] data
    );
    begin
        @(posedge PCLK);

        PSEL    = 1'b1;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = addr;

        @(posedge PCLK);

        PENABLE = 1'b1;

        @(posedge PCLK);

        data = PRDATA;

        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PADDR   = 32'h0;

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

        gpio_in = 0;

        repeat(5) @(posedge PCLK);

        PRESETn = 1'b1;

        repeat(2) @(posedge PCLK);

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
    logic [31:0] rdata;

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

        apb_read(REG_PADDIR, rdata);
        check_value(rdata, 32'h0, "PADDIR RESET");

        apb_read(REG_PADOUT, rdata);
        check_value(rdata, 32'h0, "PADOUT RESET");

        apb_read(REG_INTEN, rdata);
        check_value(rdata, 32'h0, "INTEN RESET");

        apb_read(REG_INTTYPE0, rdata);
        check_value(rdata, 32'h0, "INTTYPE0 RESET");

        apb_read(REG_INTTYPE1, rdata);
        check_value(rdata, 32'h0, "INTTYPE1 RESET");

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata, 32'h0, "INTSTATUS RESET");

        // -----------------------------------------------------
        // PADDIR TEST
        // -----------------------------------------------------
        $display("\n========== PADDIR TEST ==========\n");

        apb_write(REG_PADDIR, 32'h0000FFFF);

        apb_read(REG_PADDIR, rdata);
        check_value(rdata, 32'h0000FFFF, "PADDIR WRITE/READ");

        // -----------------------------------------------------
        // PADOUT TEST
        // -----------------------------------------------------
        $display("\n========== PADOUT TEST ==========\n");

        apb_write(REG_PADOUT, 32'hA5A55A5A);

        apb_read(REG_PADOUT, rdata);
        check_value(rdata, 32'hA5A55A5A, "PADOUT WRITE/READ");

        check_value(gpio_out, 32'hA5A55A5A, "GPIO OUT CHECK");

        // -----------------------------------------------------
        // PADOUTSET TEST
        // -----------------------------------------------------
        $display("\n========== PADOUTSET TEST ==========\n");

        apb_write(REG_PADOUTSET, 32'h0000000F);

        apb_read(REG_PADOUT, rdata);
        check_value(rdata, 32'hA5A55A5F, "PADOUTSET FUNCTION");

        // -----------------------------------------------------
        // PADOUTCLR TEST
        // -----------------------------------------------------
        $display("\n========== PADOUTCLR TEST ==========\n");

        apb_write(REG_PADOUTCLR, 32'h0000000F);

        apb_read(REG_PADOUT, rdata);
        check_value(rdata, 32'hA5A55A50, "PADOUTCLR FUNCTION");

        // -----------------------------------------------------
        // PADIN TEST
        // -----------------------------------------------------
        $display("\n========== PADIN TEST ==========\n");

        gpio_in = 32'h12345678;

        repeat(3) @(posedge PCLK);

        apb_read(REG_PADIN, rdata);
        check_value(rdata, 32'h12345678, "PADIN READ");

        // -----------------------------------------------------
        // INTERRUPT ENABLE TEST
        // -----------------------------------------------------
        $display("\n========== INTERRUPT ENABLE TEST ==========\n");

        apb_write(REG_INTEN, 32'h00000001);

        apb_read(REG_INTEN, rdata);
        check_value(rdata, 32'h00000001, "INTEN WRITE/READ");

        // -----------------------------------------------------
        // RISING EDGE INTERRUPT TEST
        // -----------------------------------------------------
      	$display("\n========== RISING EDGE INTERRUPT TEST ==========\n TIME = %0t", $time);

        // GPIO0 as input
      	apb_write(REG_PADDIR, 32'h0);

        // Rising edge
        apb_write(REG_INTTYPE0, 32'h0);
        apb_write(REG_INTTYPE1, 32'h1);

        gpio_in[0] = 0;
        repeat(3) @(posedge PCLK);

        gpio_in[0] = 1;
        repeat(3) @(posedge PCLK);
      
      	gpio_in[0] = 0;
      	repeat(3) @(posedge PCLK);
        
      	apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[0], 1'b1, "RISING EDGE STATUS");

        check_value(interrupt, 1'b1, "RISING EDGE IRQ");

        // -----------------------------------------------------
        // INTERRUPT CLEAR TEST
        // -----------------------------------------------------
        $display("\n========== INTERRUPT CLEAR TEST ==========\n");

        apb_write(REG_INTCLR, 32'h00000001);

        repeat(2) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
      
        check_value(rdata[0], 1'b0, "INTERRUPT CLEAR");

        // -----------------------------------------------------
        // FALLING EDGE INTERRUPT TEST
        // -----------------------------------------------------
        $display("\n========== FALLING EDGE INTERRUPT TEST ==========\n");

        apb_write(REG_INTTYPE0, 32'h1);
        apb_write(REG_INTTYPE1, 32'h1);

        gpio_in[0] = 1;
        repeat(3) @(posedge PCLK);

        gpio_in[0] = 0;
        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[0], 1'b1, "FALLING EDGE STATUS");

        // -----------------------------------------------------
        // SOFTWARE INTERRUPT SET TEST
        // -----------------------------------------------------
        $display("\n========== SOFTWARE INTERRUPT SET TEST ==========\n");

        apb_write(REG_INTSET, 32'h00000002);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[1], 1'b1, "SOFTWARE INTERRUPT SET");

        // -----------------------------------------------------
        // PADCFG TEST
        // -----------------------------------------------------
        $display("\n========== PADCFG TEST ==========\n");

        apb_write(REG_INTPADCFG0, 32'h12345678);

        apb_read(REG_INTPADCFG0, rdata);
        check_value(rdata, 32'h12345678, "PADCFG0");

        apb_write(REG_INTPADCFG1, 32'h87654321);

        apb_read(REG_INTPADCFG1, rdata);
        check_value(rdata, 32'h87654321, "PADCFG1");

        // -----------------------------------------------------
        // MULTIPLE INTERRUPT TEST
        // -----------------------------------------------------
        $display("\n========== MULTIPLE INTERRUPT TEST ==========\n");

        apb_write(REG_INTEN, 32'h00000003);

        apb_write(REG_INTTYPE0, 32'h0);
        apb_write(REG_INTTYPE1, 32'h3);

        gpio_in[1:0] = 2'b00;
        repeat(3) @(posedge PCLK);

        gpio_in[1:0] = 2'b11;
        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[1:0], 2'b11, "MULTIPLE INTERRUPTS");
      
      	        // -----------------------------------------------------
        // INTERRUPT MASK TEST
        // -----------------------------------------------------
        $display("\n========== INTERRUPT MASK TEST ==========\n");

        // clear previous interrupts
        apb_write(REG_INTCLR, 32'hFFFFFFFF);

        // gpio0 input
        apb_write(REG_PADDIR, 32'h0);

        // enable interrupt
        apb_write(REG_INTEN, 32'h00000001);

        // mask interrupt
        apb_write(REG_INTMASK, 32'h00000001);

        // rising edge type
        apb_write(REG_INTTYPE0, 32'h0);
        apb_write(REG_INTTYPE1, 32'h1);

        gpio_in[0] = 0;
        repeat(3) @(posedge PCLK);

        gpio_in[0] = 1;
        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[0], 1'b1, "MASKED STATUS STORED");

        check_value(interrupt, 1'b0, "MASKED IRQ BLOCKED");

        // unmask
        apb_write(REG_INTMASK, 32'h0);

        repeat(2) @(posedge PCLK);

        check_value(interrupt, 1'b1, "UNMASKED IRQ ASSERTED");

        // -----------------------------------------------------
        // LEVEL HIGH INTERRUPT TEST
        // -----------------------------------------------------
        $display("\n========== LEVEL HIGH INTERRUPT TEST ==========\n");

        apb_write(REG_INTCLR, 32'hFFFFFFFF);

        // level high = 00
        apb_write(REG_INTTYPE0, 32'h0);
        apb_write(REG_INTTYPE1, 32'h0);

        gpio_in[0] = 1;

        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[0], 1'b1, "LEVEL HIGH STATUS");

        // clear while pin still high
        apb_write(REG_INTCLR, 32'h1);

        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);

        // should reassert immediately
        check_value(rdata[0], 1'b1, "LEVEL HIGH REASSERT");

        // -----------------------------------------------------
        // LEVEL LOW INTERRUPT TEST
        // -----------------------------------------------------
        $display("\n========== LEVEL LOW INTERRUPT TEST ==========\n");

        apb_write(REG_INTCLR, 32'hFFFFFFFF);

        // level low = 01
        apb_write(REG_INTTYPE0, 32'h1);
        apb_write(REG_INTTYPE1, 32'h0);

        gpio_in[0] = 0;

        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[0], 1'b1, "LEVEL LOW STATUS");

        // -----------------------------------------------------
        // OUTPUT GPIO INTERRUPT BLOCK TEST
        // -----------------------------------------------------
        $display("\n========== OUTPUT GPIO INTERRUPT BLOCK TEST ==========\n");

        // clean previous interrupt conditions
        gpio_in = 32'h0;

        apb_write(REG_INTEN,     32'h0);
        apb_write(REG_INTMASK,   32'h0);
        apb_write(REG_INTCLR,    32'hFFFFFFFF);

        repeat(5) @(posedge PCLK);

        // gpio0 output
        apb_write(REG_PADDIR, 32'h1);

        // rising edge
        apb_write(REG_INTTYPE0, 32'h0);
        apb_write(REG_INTTYPE1, 32'h1);

        gpio_in[0] = 0;
        repeat(3) @(posedge PCLK);

        gpio_in[0] = 1;
        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);

        check_value(rdata[0], 1'b0, "OUTPUT GPIO NO INTERRUPT");

        // -----------------------------------------------------
        // SOFTWARE INTERRUPT CLEAR TEST
        // -----------------------------------------------------
        $display("\n========== SOFTWARE INTERRUPT CLEAR TEST ==========\n");

        apb_write(REG_INTSET, 32'h00000004);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[2], 1'b1, "SOFTWARE SET");

        apb_write(REG_INTCLR, 32'h00000004);

        repeat(2) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[2], 1'b0, "SOFTWARE CLEAR");

        // -----------------------------------------------------
        // PARTIAL INTERRUPT CLEAR TEST
        // -----------------------------------------------------
        $display("\n========== PARTIAL INTERRUPT CLEAR TEST ==========\n");

        apb_write(REG_INTSET, 32'h0000000F);

        apb_read(REG_INTSTATUS, rdata);
        check_value(rdata[3:0], 4'hF, "MULTI INTERRUPT SET");

        // clear only bit0
        apb_write(REG_INTCLR, 32'h00000001);

        repeat(2) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);

        check_value(rdata[3:0], 4'hE, "PARTIAL CLEAR");

        // -----------------------------------------------------
        // PADCFG2/3 TEST
        // -----------------------------------------------------
        $display("\n========== PADCFG2/3 TEST ==========\n");

        apb_write(REG_INTPADCFG2, 32'hCAFEBABE);

        apb_read(REG_INTPADCFG2, rdata);
        check_value(rdata, 32'hCAFEBABE, "PADCFG2");

        apb_write(REG_INTPADCFG3, 32'hDEADBEEF);

        apb_read(REG_INTPADCFG3, rdata);
        check_value(rdata, 32'hDEADBEEF, "PADCFG3");

        // -----------------------------------------------------
        // INVALID ADDRESS TEST
        // -----------------------------------------------------
        $display("\n========== INVALID ADDRESS TEST ==========\n");

      apb_read(32'h00000FFC, rdata);//this will fail because the decode logic [5:2] maps to 4'b1111 the address of PADCFG3 reg

        check_value(rdata, 32'h0, "INVALID READ RETURNS ZERO");

        // -----------------------------------------------------
        // RESET DURING ACTIVE INTERRUPT TEST
        // -----------------------------------------------------
        $display("\n========== RESET DURING ACTIVE IRQ ==========\n");

        // trigger interrupt
        apb_write(REG_PADDIR, 32'h0);

        apb_write(REG_INTEN, 32'h1);

        apb_write(REG_INTTYPE0, 32'h0);
        apb_write(REG_INTTYPE1, 32'h1);

        gpio_in[0] = 0;
        repeat(3) @(posedge PCLK);

        gpio_in[0] = 1;
        repeat(3) @(posedge PCLK);

        check_value(interrupt, 1'b1, "IRQ ACTIVE");

        // reset during interrupt
        PRESETn = 0;

        repeat(3) @(posedge PCLK);

        PRESETn = 1;

        repeat(3) @(posedge PCLK);

        apb_read(REG_INTSTATUS, rdata);

        check_value(rdata, 32'h0, "RESET CLEARS STATUS");

        check_value(interrupt, 1'b0, "RESET CLEARS IRQ");

        // -----------------------------------------------------
        // RESET AGAIN
        // -----------------------------------------------------
        $display("\n========== RESET RECHECK ==========\n");

        reset_dut();

        apb_read(REG_PADOUT, rdata);
        check_value(rdata, 32'h0, "RESET AFTER OPERATION");

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