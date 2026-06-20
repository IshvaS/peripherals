class intset_test extends gpio_base_test;

    logic [31:0] rdata;

    function new(apb_driver master);
        super.new(master);
        test_name = "INTSET_TEST";
    endfunction

    task run();

        $display("\n========== INTSET TEST ==========");

        for(int bt=0; bt<32; bt++) begin

            master.write(REG_INTCLR, 32'hFFFF_FFFF);

            master.write(
                REG_INTSET,
                (32'h1 << bt)
            );

            master.read(
                REG_INTSTATUS,
                rdata
            );

            check(
                rdata,
                (32'h1 << bt),
                $sformatf("Software Interrupt Bit %0d", bt)
            );

        end

    endtask

endclass