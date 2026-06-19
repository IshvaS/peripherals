class timer_rst_on_cmp extends timer_base_test;
  
    logic [31:0] rdata, edata;

  	function new(apb_driver master);
        super.new(master);
     	test_name = "TIMER_RST_ON_CMP_TEST";
    endfunction
  
  	task run();

        $display("\n========== TIMER FUNCTIONALITY TEST ==========");
        repeat(test_count) begin
            edata = $urandom();
            master.write(REG_TIMER, edata);
            master.write(REG_TIMER_CTRL, 32'h1); 
        
            repeat(10)
                @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL, 32'h0);
            master.read(REG_TIMER, rdata);

            assert(rdata > 0)
            else
                $error("Timer did not count");

            master.write(REG_CMP, edata);
            master.read(REG_TIMER, rdata);
          	check(rdata, 32'h0, "Timer reset on compare test");
        end
    endtask

endclass