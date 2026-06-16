class timer_golden_model;

    localparam APB_ADDR_WIDTH = 12;

    localparam REG_TIMER      = 12'h000;
    localparam REG_TIMER_CTRL = 12'h004;
    localparam REG_CMP        = 12'h008;

    localparam ENABLE_BIT         = 0;
    localparam PRESCALER_STARTBIT = 16;
    localparam PRESCALER_STOPBIT  = 31;

    logic [31:0] timer;
    logic [31:0] ctrl;
    logic [31:0] cmp;

    logic [15:0] count;
    logic [1:0]  irq_o;

    // ---------------------------------------------------------
    // Constructor
    // ---------------------------------------------------------

    function new();
        reset();
    endfunction

    // ---------------------------------------------------------
    // Reset
    // ---------------------------------------------------------

    function void reset();

        timer = 32'h0;
        ctrl  = 32'h0;
        cmp   = 32'h0;

        count = 16'h0;
        irq_o = 2'b00;

    endfunction

    // ---------------------------------------------------------
    // APB Write Model
    // ---------------------------------------------------------

    function void write_data
    (
        logic [APB_ADDR_WIDTH-1:0] addr,
        logic [31:0] wdata
    );

        case(addr)

            REG_TIMER:
                timer = wdata;

            REG_TIMER_CTRL:
                ctrl = wdata;

            REG_CMP:
            begin
                cmp   = wdata;
                timer = 32'h0;    // matches RTL
            end

            default: ;

        endcase

    endfunction

    // ---------------------------------------------------------
    // APB Read Model
    // ---------------------------------------------------------

    function logic [31:0] read_data
    (
        logic [APB_ADDR_WIDTH-1:0] addr
    );

        case(addr)

            REG_TIMER:
                return timer;

            REG_TIMER_CTRL:
                return ctrl;

            REG_CMP:
                return cmp;

            default:
                return 32'h0;

        endcase

    endfunction

    // ---------------------------------------------------------
    // Clock Tick Model
    // ---------------------------------------------------------

    function void tick();

        logic [15:0] prescaler;

        irq_o = 2'b00;

        prescaler =
            ctrl[PRESCALER_STOPBIT:PRESCALER_STARTBIT];

        if(ctrl[ENABLE_BIT])
        begin

            // prescaler disabled
            if(prescaler == 16'h0)
            begin

                if(timer == 32'hFFFF_FFFF)
                begin
                    irq_o[0] = 1'b1;
                    timer    = 32'h0;
                end

                else if((cmp != 0) && (timer == cmp))
                begin
                    irq_o[1] = 1'b1;
                    timer    = 32'h0;
                end

                else
                    timer++;

            end

            // prescaler enabled
            else
            begin

                count++;

                if(count >= prescaler)
                begin

                    count = 16'h0;

                    if(timer == 32'hFFFF_FFFF)
                    begin
                        irq_o[0] = 1'b1;
                        timer    = 32'h0;
                    end

                    else if((cmp != 0) && (timer == cmp))
                    begin
                        irq_o[1] = 1'b1;
                        timer    = 32'h0;
                    end

                    else
                        timer++;

                end
            end
        end

    endfunction

    // ---------------------------------------------------------
    // Helper Functions
    // ---------------------------------------------------------

    function logic [1:0] get_irq();
        return irq_o;
    endfunction

    function logic [31:0] get_timer();
        return timer;
    endfunction

    function logic [31:0] get_cmp();
        return cmp;
    endfunction

    function logic [31:0] get_ctrl();
        return ctrl;
    endfunction

endclass