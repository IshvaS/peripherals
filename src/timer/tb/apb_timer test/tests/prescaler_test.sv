class prescaler_test extends timer_base_test;

    logic [31:0] rdata;
    logic [31:0] ctrl_word;
    int prescaler;

    function new(apb_driver master);
        super.new(master);
        test_name = "PRESCALER_TEST";
    endfunction

    task run();

        $display("\n========== PRESCALER TEST ==========");

        repeat(test_count) begin
          
          	// Timer 1

            prescaler = ($urandom % 8) + 2; // 2..9

            master.write(REG_TIMER0, 32'h0);

            ctrl_word = {prescaler[15:0],16'h0001};

            master.write(REG_TIMER_CTRL0, ctrl_word);

            repeat(prescaler*5)
                @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL0, 32'h0);

            master.read(REG_TIMER0, rdata);

            check(
                rdata,
                32'd4,
                $sformatf("Prescaler=%0d", prescaler)
            );
          
          	//Timer 2
          	prescaler = ($urandom % 8) + 2; // 2..9

            master.write(REG_TIMER1, 32'h0);

            ctrl_word = {prescaler[15:0],16'h0001};

            master.write(REG_TIMER_CTRL1, ctrl_word);

            repeat(prescaler*5)
                @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL1, 32'h0);

            master.read(REG_TIMER1, rdata);

            check(
                rdata,
                32'd4,
                $sformatf("Prescaler=%0d", prescaler)
            );

        end

    endtask

endclass