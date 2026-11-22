class timer_func_test extends timer_base_test;

    logic [31:0] rdata;
    logic [31:0] edata;
  
  	function new(apb_driver master);
        super.new(master);
    	test_name = "TIMER_FUNC_TEST";
    endfunction

    task run();

        $display("\n========== TIMER FUNCTIONALITY TEST ==========");

        repeat(test_count) begin

            edata = $urandom();

            master.write(REG_TIMER, edata);

            master.write(REG_TIMER_CTRL, 32'h1);

          	repeat(5)
              @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL, 32'h0);

            master.read(REG_TIMER, rdata);
          
          	check(rdata, edata+8, "Timer Functionality");

        end

    endtask

endclass