class timer_base_test;

    apb_driver       master;
  	static int test_count = 0;
  	static int pass = 0, fail = 0;
  	string test_name;
  
  	static logic [11:0] target_registers[$] =
    '{
        REG_TIMER,
        REG_TIMER_CTRL,
        REG_CMP
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
      string name
    );
      if(rdata == edata)
        pass++;
      else begin
        fail++;
        $display("Mismatch occurred: %s - Actual = %0h | Expected = %0h",
                 name,
                 rdata,
                 edata);
      end
      
    endtask
      

endclass