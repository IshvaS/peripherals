import uic_pkg::*;

module apb_uic
#(
    parameter APB_ADDR_WIDTH = 12
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

    input  logic                [1:0] timer_irq,
    input  logic                [1:0] i2c_irq,
    input  logic                      spi_irq,
    input  logic                      uart_irq,
    input  logic                      gpio_irq,
    input  logic                      soft_irq,
    
    output logic                [7:0] irq_vector,
    output logic                      irq,

    input logic                       irq_ack
);

    logic [31:0] enable_q,  enable_n;
    logic [31:0] pending_q, pending_n;
    logic [IRQ_COUNT-1:0] irq_i;
    logic [7:0] irq_vector_n;
    logic irq_n;

    // Pack interrupts
    assign irq_i[0] = timer_irq[0];
    assign irq_i[1] = timer_irq[1];
    assign irq_i[2] = i2c_irq[0];
    assign irq_i[3] = i2c_irq[1];
    assign irq_i[4] = spi_irq;
    assign irq_i[5] = uart_irq;
    assign irq_i[6] = gpio_irq;
    assign irq_i[7] = soft_irq;

    wire write_enable = PSEL & PENABLE & PWRITE;
    wire read_enable  = PSEL & PENABLE & !PWRITE;

    typedef enum logic [2:0] {
        IRQ_CLASS_NONE   = 3'b000,
        IRQ_CLASS_TIMER  = 3'b001,
        IRQ_CLASS_EXT    = 3'b010,
        IRQ_CLASS_SOFT   = 3'b011
    } irq_class_t;

    typedef enum logic [4:0] {
        TIMER0_ID = 5'd0,
        TIMER1_ID = 5'd1,
        I2C0_ID   = 5'd0,
        I2C1_ID   = 5'd1,
        SPI_ID    = 5'd2,
        UART_ID   = 5'd3,
        GPIO_ID   = 5'd4,
        SOFT_ID   = 5'd0
    } irq_id_t;

    irq_class_t irq_class;
    irq_id_t    irq_id;

    logic [$clog2(IRQ_COUNT)-1:0] highest_pending_int;
    logic pending_valid;

    always_comb 
    begin : priority_encoder

        highest_pending_int = 'b0;
        pending_valid       = 1'b0;
        irq_class           = IRQ_CLASS_NONE;
        irq_id              = TIMER0_ID;

        for (int i = 0; i < IRQ_COUNT; i++) begin
            if (pending_q[i]) begin
                highest_pending_int = i;
                pending_valid       = 1'b1;
                break;
            end
        end

        if (pending_valid) begin
            unique case(highest_pending_int)
                'd0: 
                begin 
                    irq_class = IRQ_CLASS_TIMER; 
                    irq_id = TIMER0_ID; 
                end
                'd1: 
                begin 
                    irq_class = IRQ_CLASS_TIMER; 
                    irq_id = TIMER1_ID; 
                end
                'd2: 
                begin 
                    irq_class = IRQ_CLASS_EXT;   
                    irq_id = I2C0_ID;   
                end
                'd3: 
                begin 
                    irq_class = IRQ_CLASS_EXT;   
                    irq_id = I2C1_ID;   
                end
                'd4: 
                begin 
                    irq_class = IRQ_CLASS_EXT;   
                    irq_id = SPI_ID;    
                end
                'd5: 
                begin 
                    irq_class = IRQ_CLASS_EXT;   
                    irq_id = UART_ID;   
                end
                'd6: 
                begin 
                    irq_class = IRQ_CLASS_EXT;   
                    irq_id = GPIO_ID;   
                end
                'd7: 
                begin 
                    irq_class = IRQ_CLASS_SOFT;  
                    irq_id = SOFT_ID;   
                end
                default: ;
            endcase

            irq_vector_n = {irq_class, irq_id};
            irq_n        = 1'b1;
        end 
        else begin
            irq_vector_n = 8'h00;
            irq_n        = 1'b0;
        end
    end

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    always_comb 
    begin : register_combinational
        enable_n  = enable_q;
        pending_n = pending_q;

        pending_n |= (irq_i & enable_q);

        if (write_enable) begin
            unique case (PADDR)
                REG_IRQ_ENABLE:  
                    enable_n  = PWDATA;
                REG_SET_PENDING: 
                    pending_n |= (PWDATA & enable_q); 
                REG_CLR_PENDING: 
                    pending_n &= ~PWDATA;
                default: ;
            endcase
        end

        if (irq_ack && pending_valid) begin
            pending_n[highest_pending_int] = 1'b0;
        end
    end

    // 3. APB Read Interface
    always_comb 
    begin : apb_read
        PRDATA = 'b0;
        if (read_enable) begin
            unique case (PADDR)
                REG_IRQ_ENABLE:  
                    PRDATA = enable_q;
                REG_IRQ_PENDING: 
                    PRDATA = pending_q;
                default:         
                    PRDATA = 'b0;
            endcase
        end
    end

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            enable_q  <= 32'b0;
            pending_q <= 32'b0;
        end else begin
            enable_q  <= enable_n;
            pending_q <= pending_n;
        end
    end

    assign irq_vector = irq_vector_n;
    assign irq        = irq_n;

endmodule