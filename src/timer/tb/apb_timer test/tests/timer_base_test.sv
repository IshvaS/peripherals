class timer_base_test;

    apb_driver       master;

  	static int       test_count = 0;
  	static int       pass = 0, fail = 0;
    
  	string  test_name;
  
  	localparam REG_TIMER0       = 12'h000;
    localparam REG_TIMER_CTRL0  = 12'h004;
    localparam REG_CMP0         = 12'h008;

    localparam REG_TIMER1       = 12'h010;
    localparam REG_TIMER_CTRL1  = 12'h014;
    localparam REG_CMP1         = 12'h018;

    static logic [11:0] target_registers[$] =
    '{
        REG_TIMER0,
        REG_TIMER_CTRL0,
        REG_CMP0,

        REG_TIMER1,
        REG_TIMER_CTRL1,
        REG_CMP1
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