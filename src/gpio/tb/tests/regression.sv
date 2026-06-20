class regression extends gpio_base_test;

    gpio_base_test test_pool[$];

    function new(apb_driver master);
        super.new(master);
    endfunction

    function void build_regression();
        reset_test      		t1  = new(master);
        rw_test         		t2  = new(master);
        padin_test 				t3  = new(master);
        intset_test  			t4  = new(master);
        intclr_test   			t5  = new(master);
      	int_level_high_test 	t6  = new(master);
      	int_level_low_test 		t7  = new(master);
      	int_rising_edge_test 	t8  = new(master);
      	int_falling_edge_test 	t9  = new(master);
      	padoutclr_test  		t10 = new(master);
      	padoutset_test  		t11 = new(master);
      	intmask_test  			t12 = new(master);

        test_pool.push_back(t1);
        test_pool.push_back(t2);
        test_pool.push_back(t3);
        test_pool.push_back(t4);
        test_pool.push_back(t5);
      	test_pool.push_back(t6);
      	test_pool.push_back(t7);
      	test_pool.push_back(t8);
      	test_pool.push_back(t9);
        test_pool.push_back(t10);
        test_pool.push_back(t11);
        test_pool.push_back(t12);
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
          	tb_gpio.reset_dut();
           
            test_pool[i].run();
          $display("Pass : %0d | Fail = %0d", pass, fail);
        end

    endtask

endclass