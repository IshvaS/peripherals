class overflow_test extends timer_base_test;

  logic [31:0] edata,rdata;
  
  	function new(apb_driver master);
        super.new(master);
     	test_name = "OVERFLOW_TEST";
    endfunction

    task run();

        $display("\n========== OVERFLOW TEST ==========");

        repeat(test_count) begin
          	
          	// Timer 1

          	edata = 32'hFFFF_FFF0 | ($urandom_range(0, 14));

          	master.write(REG_TIMER0, edata);

          	master.write(REG_TIMER_CTRL0, 32'h1);

          	wait(tb_timer.irq_o[0]);

          	master.write(REG_TIMER_CTRL0, 32'h0);
          	
          	master.read(REG_TIMER0, rdata);

          	check(rdata, 1, "OVERFLOW TEST 1"); 
          
          	// Timer 2
          
          	edata = 32'hFFFF_FFF0 | ($urandom_range(0, 14));

            master.write(REG_TIMER1, edata);

            master.write(REG_TIMER_CTRL1, 32'h1);

          	wait(tb_timer.irq_o[2]);

            master.write(REG_TIMER_CTRL1, 32'h0);

            master.read(REG_TIMER1, rdata);

            check(rdata, 1, "OVERFLOW TEST 2"); 
          
        end

    endtask

endclass