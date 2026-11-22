class int_rising_edge_test extends gpio_base_test;

    logic [31:0] rdata;

    function new(apb_driver master);
        super.new(master);
        test_name = "INT_RISING_EDGE_TEST";
    endfunction

    task run();

      $display("\n========== INT RISING EDGE TEST ==========");
      	
      	for(int bt=0; bt<32; bt++) begin

          master.write(REG_INTCLR, 32'hFFFF_FFFF);

          master.write(REG_INTEN,    32'h1 << bt);
          master.write(REG_INTTYPE0, 32'h0);
          master.write(REG_INTTYPE1, 32'h1 << bt);

          tb_gpio.gpio_in = 32'h0;

          repeat(2) @(posedge tb_gpio.HCLK);

          tb_gpio.gpio_in[bt] = 1'b1;

          repeat(2) @(posedge tb_gpio.HCLK);

          master.read(REG_INTSTATUS, rdata);

          check(
              rdata,
              (32'h1 << bt),
              $sformatf("Rising Edge Bit %0d", bt)
          );

      end

    endtask

endclass