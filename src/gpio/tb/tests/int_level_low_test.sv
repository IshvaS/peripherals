class int_level_low_test extends gpio_base_test;

    logic [31:0] rdata;

    function new(apb_driver master);
        super.new(master);
        test_name = "INT_LEVEL_LOW_TEST";
    endfunction

    task run();

      $display("\n========== INT LEVEL LOW TEST ==========");
      	
      	tb_gpio.gpio_in = 32'h1;

        for(int bt=0; bt<32; bt++) begin

          	master.write(REG_INTEN,    32'h1 << bt);
          	master.write(REG_INTTYPE0, 32'hFFFF_FFFF);
            master.write(REG_INTTYPE1, 32'h0);

          	tb_gpio.gpio_in[bt] = 0;

			repeat(2) @(posedge tb_gpio.HCLK);
          	
          	master.read(REG_INTSTATUS, rdata);

          	check(rdata[bt], 1'b1, "Level Low");

        end

    endtask

endclass