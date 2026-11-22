class gpio_base_test;

    apb_driver master;

    static int test_count = 0;
    static int pass = 0;
    static int fail = 0;

    string test_name;

    static logic [11:0] rw_registers[$] =
    '{
        REG_PADDIR,
        REG_PADOUT,

        REG_INTEN,
        REG_INTMASK,

        REG_INTTYPE0,
        REG_INTTYPE1,

        REG_PADCFG0,
        REG_PADCFG1,
        REG_PADCFG2,
        REG_PADCFG3
    };

    static logic [11:0] ro_registers[$] =
    '{
        REG_PADIN,
        REG_INTSTATUS
    };

    static logic [11:0] wo_registers[$] =
    '{
        REG_PADOUTSET,
        REG_PADOUTCLR,

        REG_INTSET,
        REG_INTCLR
    };

    function new(
        apb_driver master
    );
        this.master = master;
    endfunction

    virtual task run();
    endtask

    task automatic check(
        input logic [31:0] rdata,
        input logic [31:0] edata,
        input string name
    );

        if(rdata === edata)
            pass++;
        else begin
            fail++;
            $error(
                "Mismatch occurred: %s - Actual = %0h | Expected = %0h",
                name,
                rdata,
                edata
            );
        end

    endtask

endclass