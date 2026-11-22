`include "apb_if.sv"
`include "apb_driver.sv"

`include "timer_base_test.sv"
`include "reset_test.sv"
`include "rw_test.sv"
`include "timer_func_test.sv"
`include "cmp_match_test.sv"
`include "overflow_test.sv"
`include "timer_rst_on_cmp.sv"
`include "prescaler_test.sv"
`include "report_summary.sv"
`include "regression.sv"


module tb_timer;

    logic HCLK;

    logic [1:0] irq_o;

    apb_if apb(HCLK);

    timer dut (
        .HCLK      (HCLK),
        .HRESETn   (apb.HRESETn),

        .PADDR     (apb.PADDR),
        .PSEL      (apb.PSEL),
        .PENABLE   (apb.PENABLE),
        .PWRITE    (apb.PWRITE),
        .PWDATA    (apb.PWDATA),

        .PRDATA    (apb.PRDATA),
        .PREADY    (apb.PREADY),
        .PSLVERR   (apb.PSLVERR),

        .irq_o     (irq_o)
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
      $dumpfile("tb_timer.vcd");
      $dumpvars(0, tb_timer);
    end

    //----------------------------------------
    // Reset
    //----------------------------------------

    task reset_dut();

        apb.HRESETn = 0;
      
      	master.init();

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