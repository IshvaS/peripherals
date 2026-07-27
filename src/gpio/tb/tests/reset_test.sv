class reset_test extends gpio_base_test;

    logic [31:0] rdata;
  
  	function new(apb_driver master);
        super.new(master);
      	test_name = "RESET_TEST";
    endfunction

    task run();

        $display("\n========== RESET TEST ==========");

      	foreach(rw_registers[i]) begin

        	master.read(rw_registers[i], rdata);
          
          if( rw_registers[i] == REG_PADCFG0 ||
               rw_registers[i] == REG_PADCFG1 ||
                rw_registers[i] == REG_PADCFG2 ||
                 rw_registers[i] == REG_PADCFG3)
          	
            check(rdata, 32'h2222_2222, "Reset Test");
          
          else
            check(rdata, 32'h0, "Reset Test");

        end
      
        foreach(ro_registers[i]) begin
          master.read(ro_registers[i], rdata);
          check(rdata, 32'h0, "Reset Test");
        end

    endtask

endclass