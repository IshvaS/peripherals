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

            prescaler = ($urandom % 8) + 2; // 2..9

            master.write(REG_TIMER, 32'h0);

            ctrl_word = {prescaler[15:0],16'h0001};

            master.write(REG_TIMER_CTRL, ctrl_word);

            repeat(prescaler*5)
                @(master.vif.drv_cb);

            master.write(REG_TIMER_CTRL, 32'h0);

            master.read(REG_TIMER, rdata);

            check(
                rdata,
                32'd4,
                $sformatf("Prescaler=%0d", prescaler)
            );

        end

    endtask

endclass