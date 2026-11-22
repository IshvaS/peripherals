class padin_test extends gpio_base_test;

    logic [31:0] rdata;
    logic [31:0] edata;

    function new(apb_driver master);
        super.new(master);
        test_name = "PADIN_TEST";
    endfunction

    task run();

        $display("\n========== PADIN TEST ==========");

        repeat(test_count) begin

            edata = $urandom();

            // Drive GPIO inputs
            tb_gpio.gpio_in = edata;

            // Allow synchronizer/update logic
          	repeat(2) @(master.vif.drv_cb);

            master.read(
                REG_PADIN,
                rdata
            );

            check(
                rdata,
                edata,
                "PADIN Test"
            );

        end

    endtask

endclass