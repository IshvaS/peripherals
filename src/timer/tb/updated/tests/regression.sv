class regression extends timer_base_test;

    timer_base_test test_pool[$];

    function new(apb_driver master);
        super.new(master);
    endfunction

    function void build_regression();
        reset_test      	t1 = new(master);
        rw_test         	t2 = new(master);
        timer_func_test 	t3 = new(master);
        cmp_match_test  	t4 = new(master);
        overflow_test   	t5 = new(master);
      	timer_rst_on_cmp	t6 = new(master);
      	prescaler_test		t7 = new(master);

        test_pool.push_back(t1);
        test_pool.push_back(t2);
        test_pool.push_back(t3);
        test_pool.push_back(t4);
        test_pool.push_back(t5);
      	test_pool.push_back(t6);
      	test_pool.push_back(t7);
    endfunction

    task run();
        $display("\n=========================================");
        $display(" STARTING RANDOM ORDER TEST REGRESSION   ");
        $display("=========================================");

        build_regression();

        test_pool.shuffle();

        foreach (test_pool[i]) begin
          $display("\n[REGRESSION] Running Test %s(%0d/%0d)...",
                   test_pool[i].test_name, i+1, test_pool.size());
          	tb_timer.reset_dut();
           
            test_pool[i].run();
          $display("Pass : %0d | Fail = %0d", pass, fail);
        end

    endtask

endclass