`timescale 1ns/1ps
`include "apb_if.sv"
`include "apb_master.sv"
`include "gpio_scoreboard.sv"

module tb_apb_gpio;

    initial begin
        $dumpfile("apb_gpio.vcd");
        $dumpvars(0, tb_apb_gpio);
    end

    localparam CLK_PERIOD = 10;
  
    logic PCLK;
    logic [31:0] gpio_in;
    wire  [31:0] gpio_out;
    wire  [31:0] gpio_dir;
    wire  [31:0][3:0] gpio_padcfg;
    wire  [31:0] gpio_in_sync;
    wire  interrupt; 

    apb_gpio dut (
        .HCLK        (apb.HCLK),
        .HRESETn     (apb.HRESETn),
        .PSEL        (apb.PSEL),
        .PENABLE     (apb.PENABLE),
        .PWRITE      (apb.PWRITE),
        .PADDR       (apb.PADDR),
        .PWDATA      (apb.PWDATA),
        .PRDATA      (apb.PRDATA),
        .PREADY      (apb.PREADY),
        .PSLVERR     (apb.PSLVERR),
        .gpio_in     (gpio_in),
        .gpio_out    (gpio_out),
        .gpio_dir    (gpio_dir),
        .gpio_padcfg (gpio_padcfg),
        .gpio_in_sync(gpio_in_sync),
        .interrupt   (interrupt)
    );

    localparam APB_ADDR_WIDTH = 12;
    localparam REG_PADDIR     = 12'h000;
    localparam REG_PADIN      = 12'h004;
    localparam REG_PADOUT     = 12'h008;
    localparam REG_PADOUTSET  = 12'h00C;
    localparam REG_PADOUTCLR  = 12'h010;
    localparam REG_INTEN      = 12'h014;
    localparam REG_INTMASK    = 12'h018;
    localparam REG_INTSET     = 12'h01C;
    localparam REG_INTCLR     = 12'h020;
    localparam REG_INTSTATUS  = 12'h024;
    localparam REG_INTTYPE0   = 12'h028;
    localparam REG_INTTYPE1   = 12'h02C;
    localparam REG_PADCFG0    = 12'h030;
    localparam REG_PADCFG1    = 12'h034;
    localparam REG_PADCFG2    = 12'h038;
    localparam REG_PADCFG3    = 12'h03C;

    initial begin
        PCLK = 0;
        forever #(CLK_PERIOD/2) PCLK = ~PCLK;
    end
  
    task automatic reset_dut;
    begin
        apb.HRESETn = 1'b0;
        master.init();
        gpio_in = 0;
        repeat(5) @(posedge apb.HCLK);
        apb.HRESETn = 1'b1;
        repeat(2) @(posedge apb.HCLK);
        $display("\n========== RESET DONE ==========\n");
    end
    endtask

    logic [31:0] wdata, rdata;
  
    logic [APB_ADDR_WIDTH-1:0] target_registers[] = '{
        REG_PADDIR,    REG_PADIN,     REG_PADOUT, 
        REG_PADOUTSET, REG_PADOUTCLR, REG_INTEN, 
        REG_INTMASK,   REG_INTSET,    REG_INTCLR, 
        REG_INTSTATUS, REG_INTTYPE0,  REG_INTTYPE1,
        REG_PADCFG0,   REG_PADCFG1,   REG_PADCFG2,   REG_PADCFG3
    };
  
    apb_if           apb(PCLK);
    apb_master       master;
    gpio_scoreboard  gpio; // Scoreboard instance object handle

    initial begin
        master = new(apb);
        gpio = new();
        
        reset_dut();
        gpio.golden_model.reset(); // Establish baseline state predictions

        // -----------------------------------------------------
        // PHASE 1: RESET TEST
        // -----------------------------------------------------
        $display("\n========== RESET TEST ==========\n");
        for(int i=0; i< target_registers.size(); i++) begin
            master.read(target_registers[i], rdata);
            gpio.read_exp(target_registers[i], rdata, gpio_in);
        end
      
        // -----------------------------------------------------
        // PHASE 2: ADVANCED RANDOMIZED STRESS TEST
        // -----------------------------------------------------
        $display("\n========== STARTING RANDOM CRV STRESS TEST ==========\n");

      	repeat(1000) begin
            for(int i=0; i< target_registers.size(); i++) begin
                
                if (target_registers[i] == REG_INTSTATUS) continue;

                gpio_in = $random;
                wdata = $random;
                
                master.write(target_registers[i], wdata);
                gpio.write_exp(target_registers[i], wdata);
                
                @(posedge apb.HCLK); // Minor settling step

                if (target_registers[i] == REG_PADOUTSET || target_registers[i] == REG_PADOUTCLR) begin
                    master.read(REG_PADOUT, rdata);
                    gpio.read_exp(REG_PADOUT, rdata, gpio_in);
                end 

                else begin
                    master.read(target_registers[i], rdata);
                    gpio.read_exp(target_registers[i], rdata, gpio_in); 
                end        
            end
        end
      
      	$display("\n========== RISING EDGE INTERRUPT TEST ==========\n");

		reset_dut();

		master.write(REG_PADDIR,   32'h0);
		master.write(REG_INTEN,    32'h1);
		master.write(REG_INTTYPE1, 32'h1);
		master.write(REG_INTTYPE0, 32'h0);

		gpio_in = 32'h0;
		repeat(3) @(posedge apb.HCLK);

		gpio_in = 32'h1;
		repeat(3) @(posedge apb.HCLK);
	
		master.read(REG_INTSTATUS, rdata);

		assert(rdata[0]);
		assert(interrupt);
      
      	$display("\n========== FALLING EDGE INTERRUPT TEST ==========\n");

        reset_dut();

        master.write(REG_PADDIR,   32'h0);
        master.write(REG_INTEN,    32'h1);
        master.write(REG_INTTYPE1, 32'h1);
        master.write(REG_INTTYPE0, 32'h1);

        gpio_in = 32'h1;
        repeat(3) @(posedge apb.HCLK);

        gpio_in = 32'h0;
        repeat(3) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0]);
        assert(interrupt);
      
      	$display("\n========== HIGH LEVEL INTERRUPT TEST ==========\n");

        reset_dut();

        master.write(REG_PADDIR,   32'h0);
        master.write(REG_INTEN,    32'h1);
        master.write(REG_INTTYPE1, 32'h0);
        master.write(REG_INTTYPE0, 32'h0);

        gpio_in = 32'h1;

        repeat(3) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0]);
        assert(interrupt);
      
      	$display("\n========== LOW LEVEL INTERRUPT TEST ==========\n");

        reset_dut();

        master.write(REG_PADDIR,   32'h0);
        master.write(REG_INTEN,    32'h1);
        master.write(REG_INTTYPE1, 32'h0);
        master.write(REG_INTTYPE0, 32'h1);

        gpio_in = 32'h0;

        repeat(3) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0]);
        assert(interrupt);
      
      	$display("\n========== SOFTWARE INTERRUPT SET TEST ==========\n");

        reset_dut();

        master.write(REG_INTSET, 32'h1);

        repeat(2) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0]);
        assert(interrupt);
      
      	$display("\n========== INTERRUPT CLEAR TEST ==========\n");

        master.write(REG_INTCLR, 32'h1);

        repeat(2) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0] == 0);
        assert(interrupt == 0);
      
      	$display("\n========== INTERRUPT MASK TEST ==========\n");

        reset_dut();

        master.write(REG_INTSET, 32'h1);

        repeat(2) @(posedge apb.HCLK);

        master.write(REG_INTMASK, 32'h1);

        repeat(2) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0]);
        assert(interrupt == 0);
      
      	$display("\n========== INTERRUPT DISABLE TEST ==========\n");

        reset_dut();

        master.write(REG_PADDIR,   32'h0);
        master.write(REG_INTEN,    32'h0);
        master.write(REG_INTTYPE1, 32'h1);
        master.write(REG_INTTYPE0, 32'h0);

        gpio_in = 32'h0;
        repeat(3) @(posedge apb.HCLK);

        gpio_in = 32'h1;
        repeat(3) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS, rdata);

        assert(rdata[0] == 0);
        assert(interrupt == 0);
      
      	$display("MULTIPLE INTERRUPT TEST");

        reset_dut();

        master.write(REG_PADDIR,   32'h0);
        master.write(REG_INTEN,    32'hF);
        master.write(REG_INTTYPE1, 32'hF);
        master.write(REG_INTTYPE0, 32'h0);

        gpio_in = 0;
        repeat(3) @(posedge apb.HCLK);

        gpio_in = 32'hF;
        repeat(3) @(posedge apb.HCLK);

        master.read(REG_INTSTATUS,rdata);

        assert(rdata[3:0] == 4'hF);
        assert(interrupt);
    
        // -----------------------------------------------------
        // PHASE 3: METRICS PROCESSING
        // -----------------------------------------------------
        gpio.report_summary();
        
        if (gpio.mismatch_count > 0) begin
            $error("\n========== STATUS: VERIFICATION CRASHED WITH ERRORS ==========\n");
        end else begin
            $display("\n========== STATUS: ALL CORES SUCCESSFUL ==========\n");
        end
        
        $finish;
    end

endmodule