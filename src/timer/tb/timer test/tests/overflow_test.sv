class overflow_test extends timer_base_test;

  logic [31:0] edata,rdata;
  
  	function new(apb_driver master);
        super.new(master);
     	test_name = "OVERFLOW_TEST";
    endfunction

    task run();

        $display("\n========== OVERFLOW TEST ==========");

        repeat(test_count) begin

          	edata = 32'hFFFF_FFF0 | ($urandom_range(0, 14));

            master.write(REG_TIMER, edata);

            master.write(REG_TIMER_CTRL, 32'h1);

          	wait(tb_timer.irq_o[0]);

            master.write(REG_TIMER_CTRL, 32'h0);
          	
          	master.read(REG_TIMER, rdata);

          	check(rdata, 1, "OVERFLOW TEST"); 	
          
        end

    endtask

endclass