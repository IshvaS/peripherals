class intmask_test extends gpio_base_test;

    logic [31:0] rdata;

    function new(apb_driver master);
        super.new(master);
        test_name = "INTMASK_TEST";
    endfunction

    task run();

        $display("\n========== INTMASK TEST ==========");

        for(int bt=0; bt<32; bt++) begin

            master.write(REG_INTCLR, 32'hFFFF_FFFF);

            master.write(
                REG_INTEN,
                (32'h1 << bt)
            );

            master.write(
                REG_INTMASK,
                (32'h1 << bt)
            );

            // Generate software interrupt
            master.write(
                REG_INTSET,
                (32'h1 << bt)
            );

            repeat(2) @(posedge tb_gpio.HCLK);

            master.read(
                REG_INTSTATUS,
                rdata
            );

            // Status should still be set
            check(
                rdata,
                (32'h1 << bt),
                $sformatf("INTMASK Status Bit %0d", bt)
            );

            // IRQ should be suppressed
            check(
                tb_gpio.interrupt,
                1'b0,
                $sformatf("INTMASK IRQ Bit %0d", bt)
            );

        end

    endtask

endclass