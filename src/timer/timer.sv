`include "peripherals_pkg.sv"
import timer_pkg::*;

module timer
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    output logic                [1:0] irq_o // overflow and cmp interrupt
);

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    logic [31:0] timer_q, timer_n;
    logic [31:0] cmp_q, cmp_n;
    logic [31:0] ctrl_q, ctrl_n;
    logic [31:0] cycle_counter_n, cycle_counter_q;

    logic [PRESCALER_STOPBIT-PRESCALER_STARTBIT:0] prescaler_int;

    wire write_enable = PSEL && PENABLE && PWRITE;
    wire read_enable  = PSEL && PENABLE && !PWRITE;

    //irq logic
    always_comb
    begin
        irq_o = 2'b0;

        // overflow irq
        if (timer_q == 32'hffff_ffff)
            irq_o[0] = 1'b1;

        // compare match irq if compare reg ist set
        if (cmp_q != 'b0 && timer_q == cmp_q)
            irq_o[1] = 1'b1;

    end

    assign prescaler_int = ctrl_q[PRESCALER_STOPBIT:PRESCALER_STARTBIT];

    wire interrupt     = irq_o[0] | irq_o[1];
    wire timer_enabled = ctrl_q[ENABLE_BIT];

    // register write logic
    always_comb
    begin
        timer_n = timer_q;
        cmp_n   = cmp_q;
        ctrl_n  = ctrl_q;
        cycle_counter_n = cycle_counter_q + 1;
            
        if(timer_enabled && prescaler_int != 'b0 && prescaler_int == cycle_counter_q) // prescaler
        begin
            if (interrupt) // reset timer on interrupt
                timer_n = 1'b0;
            else
                timer_n = timer_q + 1;
        end
        else if (timer_enabled && prescaler_int == 'b0) // normal count mode
        begin
            if (interrupt) // reset timer on interrupt
                timer_n = 1'b0;
            else
                timer_n = timer_q + 1;
        end

        // reset prescaler cycle counter
        if (prescaler_int != 0 && cycle_counter_q >= prescaler_int)
            cycle_counter_n = 32'b0;

        // written from APB bus - gets priority
        if (write_enable)
        begin
            case (PADDR)
                REG_TIMER:
                    timer_n = PWDATA;

                REG_TIMER_CTRL:
                    ctrl_n = PWDATA;

                REG_CMP:
                begin
                    cmp_n = PWDATA;
                    timer_n = 32'b0; // reset timer if compare register is written
                end
                default:
                    ;
            endcase
        end
    end

    // synchronouse part
    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(!HRESETn)
        begin
            timer_q          <= 32'b0;
            cmp_q            <= 32'b0;
            ctrl_q           <= 32'b0;
            cycle_counter_q <= 32'b0;
        end
        else
        begin
            timer_q          <= timer_n;
            cmp_q            <= cmp_n;
            ctrl_q           <= ctrl_n;
            cycle_counter_q <= cycle_counter_n;
        end
    end

    // APB register read logic
    always_comb
    begin
        PRDATA = 'b0;

        if (read_enable)
        begin
            case (PADDR)
                REG_TIMER:
                    PRDATA = timer_q;

                REG_TIMER_CTRL:
                    PRDATA = ctrl_q;

                REG_CMP:
                    PRDATA = cmp_q;
                    
                default:
                    PRDATA = 'b0;
            endcase
        end

    end

endmodule
