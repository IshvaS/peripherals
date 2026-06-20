class int_level_high_test extends gpio_base_test;

    logic [31:0] rdata;

    function new(apb_driver master);
        super.new(master);
        test_name = "INT_LEVEL_HIGH_TEST";
    endfunction

    task run();

      $display("\n========== INT LEVEL HIGH TEST ==========");
      	
      	tb_gpio.gpio_in = 32'h0;

        for(int bt=0; bt<32; bt++) begin

          	master.write(REG_INTEN,    32'h1 << bt);
			master.write(REG_INTTYPE0, 32'h0);
			master.write(REG_INTTYPE1, 32'h0);

          	tb_gpio.gpio_in[bt] = 1;

			repeat(2) @(posedge tb_gpio.HCLK);
          	
          	master.read(REG_INTSTATUS, rdata);

          	check(rdata[bt], 1'b1, "Level High");

        end

    endtask

endclass