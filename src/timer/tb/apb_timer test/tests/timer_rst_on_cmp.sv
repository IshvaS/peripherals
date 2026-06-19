class timer_rst_on_cmp extends timer_base_test;
  
    logic [31:0] rdata, edata;

  	function new(apb_driver master);
        super.new(master);
     	test_name = "TIMER_RST_ON_CMP_TEST";
    endfunction
  
  	task run();

      $display("\n========== TIMER RESET ON COMPARE TEST ==========");
        repeat(test_count) begin
          
         	//Timer 1
            edata = $urandom();
            master.write(REG_TIMER0, edata);
            master.write(REG_TIMER_CTRL0, 32'h1); 
            
            repeat(10)
                @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL0, 32'h0);
            master.read(REG_TIMER0, rdata);

            assert(rdata > 0)
            else
                $error("Timer did not count");

            master.write(REG_CMP0, edata);
            master.read(REG_TIMER0, rdata);
            check(rdata, 32'h0, "Timer reset on compare test -1");
            
            //Timer 2
            edata = $urandom();
            master.write(REG_TIMER1, edata);
            master.write(REG_TIMER_CTRL1, 32'h1); 
            
            repeat(10)
                @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL1, 32'h0);
            master.read(REG_TIMER1, rdata);

            assert(rdata > 0)
            else
                $error("Timer did not count");

            master.write(REG_CMP1, edata);
            master.read(REG_TIMER1, rdata);
            check(rdata, 32'h0, "Timer reset on compare test -1");
            
        end
    endtask

endclass