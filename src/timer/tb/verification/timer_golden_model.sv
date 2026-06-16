class timer_golden_model;
    localparam APB_ADDR_WIDTH = 12;

  	logic [1:0] irq_o;
  	
  	localparam REG_TIMER      = 12'h000;
    localparam REG_TIMER_CTRL = 12'h004;
    localparam REG_CMP     	  = 12'h008;
  
    logic [31:0] timer;
    logic [31:0] ctrl;
    logic [31:0] cmp;

    // Constructor
    function new();
        this.reset();
    endfunction

    function void reset();
        timer = 32'h0;
        ctrl  = 32'h0;
        cmp   = 32'h0;
        irq_o = 2'b0;
    endfunction

    function void write_data(
      	logic [APB_ADDR_WIDTH-1:0] addr,
      	logic [31:0] wdata
    );
        case (addr)
            REG_TIMER :
                timer    = wdata;
            REG_TIMER_CTRL:
            ctrl = wdata;
            REG_CMP:
            cmp = wdata;
            timer = 32'h0;
            default: ; // Ignore writes to read-only registers like REG_PADIN/REG_INTSTATUS

        endcase
    endfunction

    function logic [31:0] read_data(
        logic [APB_ADDR_WIDTH-1:0] addr
    );
        case (addr)
            REG_TIMER:      return timer;
            REG_TIMER_CTRL: return ctrl;
            REG_CMP:        return cmp;
            default:        return 32'h0; // Catch-all for unmapped space
        endcase
    endfunction

    

endclass
        