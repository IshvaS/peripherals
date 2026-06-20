class padoutset_test extends gpio_base_test;

    logic [31:0] rdata;
    logic [31:0] padout;
    logic [31:0] set_data;

    function new(apb_driver master);
        super.new(master);
        test_name = "PADOUTSET_TEST";
    endfunction

    task run();

        $display("\n========== PADOUTSET TEST ==========");

        repeat(test_count) begin

            padout   = $urandom();
            set_data = $urandom();

            master.write(REG_PADOUT, padout);

            master.write(
                REG_PADOUTSET,
                set_data
            );

            master.read(
                REG_PADOUT,
                rdata
            );

            check(
                rdata,
                (padout | set_data),
                "PADOUTSET"
            );

        end

    endtask

endclass