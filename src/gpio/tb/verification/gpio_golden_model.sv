// Bring package elements into compilation scope before declaring class
import gpio_regmap_pkg::*; 

class gpio_golden_model;
    localparam APB_ADDR_WIDTH = 12;

    logic [31:0] paddir;
    logic [31:0] padout;
    logic [31:0] inten;
    logic [31:0] intmask;
    logic [31:0] intstatus;
    logic [31:0] inttype0;
    logic [31:0] inttype1;
    
    logic [31:0] padcfg[4]; 

    // Constructor
    function new();
        this.reset();
    endfunction

    function void reset();
        paddir    = 32'h0;
        padout    = 32'h0;
        inten     = 32'h0;
        intmask   = 32'h0;
        intstatus = 32'h0;
        inttype0  = 32'h0;
        inttype1  = 32'h0;
        
        foreach (padcfg[i]) begin
            padcfg[i] = 32'h2222_2222;
        end
    endfunction

    // ---------------------------------------------------------
    // Predictor for Write Operations
    // ---------------------------------------------------------
    // Fixed port-width slice from APB_ADDR_WIDTH:0 to APB_ADDR_WIDTH-1:0
    function void write_data(logic [APB_ADDR_WIDTH-1:0] addr, logic [31:0] wdata);
        case (addr)
            REG_PADDIR:    paddir   = wdata; // Removed backtick macro identifiers
            REG_PADOUT:    padout   = wdata;
            
            // Atomic Set/Clear logic updates the primary PADOUT state
            REG_PADOUTSET: padout   = padout | wdata;  
            REG_PADOUTCLR: padout   = padout & ~wdata; 
            
            REG_INTEN:     inten    = wdata;
            REG_INTMASK:   intmask  = wdata;
            
            // Software forcing an interrupt event
            REG_INTSET:    intstatus = intstatus | wdata; 
            
            // Interrupt Status Clear is "Write 1 to Clear" (W1C)
            REG_INTCLR:    intstatus = intstatus & ~wdata; 
            
            REG_INTTYPE0:  inttype0 = wdata;
            REG_INTTYPE1:  inttype1 = wdata;
            
            REG_PADCFG0:   padcfg[0] = wdata;
            REG_PADCFG1:   padcfg[1] = wdata;
            REG_PADCFG2:   padcfg[2] = wdata;
            REG_PADCFG3:   padcfg[3] = wdata;
            
            default: ; // Ignore writes to read-only registers like REG_PADIN/REG_INTSTATUS
        endcase
    endfunction

    // ---------------------------------------------------------
    // Predictor for Read Operations
    // ---------------------------------------------------------
  function logic [31:0] read_data(logic [APB_ADDR_WIDTH-1:0] addr, logic [31:0] hw_gpio_in_pins);
        case (addr)
            REG_PADDIR:    return paddir;
            REG_PADOUT:    return padout;
            REG_INTEN:     return inten;
            REG_INTMASK:   return intmask;
            REG_INTSTATUS: return intstatus;
            REG_INTTYPE0:  return inttype0;
            REG_INTTYPE1:  return inttype1;
            
            REG_PADCFG0:   return padcfg[0];
            REG_PADCFG1:   return padcfg[1];
            REG_PADCFG2:   return padcfg[2];
            REG_PADCFG3:   return padcfg[3];

            // Dynamic Inputs
            REG_PADIN:     return hw_gpio_in_pins; 

            // Write-Only Strobes: Securely return 0 on read attempts
            REG_PADOUTSET: return 32'h0; 
            REG_PADOUTCLR: return 32'h0;
            REG_INTSET:    return 32'h0;
            REG_INTCLR:    return 32'h0;

            default:        return 32'h0; // Catch-all for unmapped space
        endcase
    endfunction

endclass