class padoutclr_test extends gpio_base_test;

    logic [31:0] rdata;
    logic [31:0] padout;
    logic [31:0] clr_data;

    function new(apb_driver master);
        super.new(master);
        test_name = "PADOUTCLR_TEST";
    endfunction

    task run();

        $display("\n========== PADOUTCLR TEST ==========");

        repeat(test_count) begin

            padout   = $urandom();
            clr_data = $urandom();

            master.write(REG_PADOUT, padout);

            master.write(
                REG_PADOUTCLR,
                clr_data
            );

            master.read(
                REG_PADOUT,
                rdata
            );

            check(
                rdata,
                (padout & ~clr_data),
                "PADOUTCLR"
            );

        end

    endtask

endclass