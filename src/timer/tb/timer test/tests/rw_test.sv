class rw_test extends timer_base_test;

    logic [31:0] rdata;
    logic [31:0] edata;
  
  	function new(apb_driver master);
        super.new(master);
    	test_name = "RESET_TEST";
    endfunction

    task run();

        $display("\n========== WRITE READ TEST ==========");

        repeat(test_count) begin

            foreach(target_registers[i]) begin

              	edata = $urandom() & 32'hFFFF_FFFE; // prevent timer enable

                master.write(
                    target_registers[i],
                    edata
                );

                master.read(
                    target_registers[i],
                    rdata
                );
              	
              check(rdata, edata, "Write/Read Test");

            end

        end

    endtask

endclass