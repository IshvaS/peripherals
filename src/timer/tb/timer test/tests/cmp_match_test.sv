class cmp_match_test extends timer_base_test;

  	logic [31:0] cmp_val, rdata;
  
  	function new(apb_driver master);
        super.new(master);
      	test_name = "CMP_MATCH_TEST";
    endfunction

    task run();

        $display("\n========== CMP MATCH TEST ==========");

        repeat(test_count) begin

            cmp_val = ($urandom()%11)+5;

            master.write(REG_CMP, cmp_val);

            master.write(REG_TIMER_CTRL, 32'h1);

          	wait(tb_timer.irq_o[1]);

            master.write(REG_TIMER_CTRL, 32'h0);
          
          	master.read(REG_TIMER, rdata);
          
          	check(rdata, 1, "CMP MATCH TEST");

        end

    endtask

endclass