class rw_test extends gpio_base_test;

    logic [31:0] rdata;
    logic [31:0] edata;
  
  	function new(apb_driver master);
        super.new(master);
    	test_name = "RESET_TEST";
    endfunction

    task run();

        $display("\n========== WRITE READ TEST ==========");

        repeat(test_count) begin

          foreach(rw_registers[i]) begin

              	edata = $urandom() & 32'hFFFF_FFFE; // prevent timer enable

                master.write(
                    rw_registers[i],
                    edata
                );

                master.read(
                    rw_registers[i],
                    rdata
                );
              	
              check(rdata, edata, "Write/Read Test");

            end

        end

    endtask

endclass