`include "apb_if.sv"
`include "apb_driver.sv"

`include "gpio_base_test.sv"
`include "reset_test.sv"
`include "rw_test.sv"
`include "padin_test.sv"
`include "intset_test.sv"
`include "intclr_test.sv"
`include "int_level_high_test.sv"
`include "int_level_low_test.sv"
`include "int_rising_edge_test.sv"
`include "int_falling_edge_test.sv"
`include "padoutclr_test.sv"
`include "padoutset_test.sv"
`include "intmask_test.sv"

`include "report_summary.sv"
`include "regression.sv"


module tb_gpio;

    logic HCLK;

    logic [31:0] gpio_in;
    logic [31:0] gpio_in_sync;
    logic [31:0] gpio_out;
    logic [31:0] gpio_dir;
    logic [31:0] [3:0] gpio_padcfg;
    logic interrupt;

    apb_if apb(HCLK);

     apb_gpio dut (
        .HCLK           (HCLK),
        .HRESETn        (apb.HRESETn),

        .PADDR          (apb.PADDR),
        .PSEL           (apb.PSEL),
        .PENABLE        (apb.PENABLE),
        .PWRITE         (apb.PWRITE),
        .PWDATA         (apb.PWDATA),

        .PRDATA         (apb.PRDATA),
        .PREADY         (apb.PREADY),
        .PSLVERR        (apb.PSLVERR),

        .gpio_in        (gpio_in),
        .gpio_in_sync   (gpio_in_sync),
        .gpio_out       (gpio_out),
        .gpio_dir       (gpio_dir),
        .gpio_padcfg    (gpio_padcfg),
        .interrupt      (interrupt)
    );

    apb_driver      master;

  	regression rg;
  	report_summary report;

    //----------------------------------------
    // Clock
    //----------------------------------------

    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end
  
  	initial begin
      $dumpfile("tb_gpio.vcd");
      $dumpvars(0, tb_gpio);
    end

    //----------------------------------------
    // Reset
    //----------------------------------------

    task reset_dut();

        apb.HRESETn = 0;
      
      	master.init();
      
      	gpio_in = 0;

        repeat(5)
            @(posedge HCLK);

        apb.HRESETn = 1;

        repeat(2)
            @(posedge HCLK);

    endtask

    //----------------------------------------
    // Test
    //----------------------------------------

    initial begin

        master = new(apb);

        reset_dut();
      
      	rg = new(master);
      
      	rg.test_count = 1000;

        rg.run();
      	
      	report = new(master);

        report.summary();

        #100;
        $finish;

    end

endmodule