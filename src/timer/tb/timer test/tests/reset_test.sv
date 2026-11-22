class reset_test extends timer_base_test;

    logic [31:0] rdata;
  
  	function new(apb_driver master);
        super.new(master);
      	test_name = "RESET_TEST";
    endfunction

    task run();

        $display("\n========== RESET TEST ==========");

        foreach(target_registers[i]) begin

            master.read(target_registers[i], rdata);
          	check(rdata, 32'h0, "Reset Test");

        end

    endtask

endclass