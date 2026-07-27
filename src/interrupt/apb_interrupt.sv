module apb_interrupt
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

    input  logic                      i2c0,
    input  logic                      i2c1,
    input  logic                      spi,
    input  logic                      tc0,
    input  logic                      to0,
    input  logic                      tc1,
    input  logic                      to1,
    input  logic                      uart,
    input  logic                      gpio,

    output logic                      irq_valid
);

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    logic [31:0] enable;
    logic [31:0] pending;
    logic [4:0]  claim_id;
    logic [31:0] hw_irq;
    logic has_active_int;
    
    wire [31:0] active_interrupts = pending & enable;
    wire write_enable   = PSEL && PENABLE && PWRITE;
    wire read_enable    = PSEL && PENABLE && !PWRITE;
    wire claim_id_read  = PSEL && PENABLE && !PWRITE && (PADDR == REG_INT_CLAIM_ID);
    
    assign hw_irq = {23'b0, gpio, uart, to1, tc1, to0, tc0, spi, i2c1, i2c0};
    assign irq_valid    = has_active_int;

    always_comb begin
        has_active_int = |active_interrupts;
        claim_id       = 5'd0;

        if (has_active_int) begin
            for (int i = 0; i < 32; i++) begin
                if (active_interrupts[i]) begin
                    claim_id = i[4:0];
                    break; 
                end
            end
        end
    end

    always_ff @(posedge HCLK or negedge HRESETn) 
    begin
        if (!HRESETn) 
        begin
            enable  <= 32'h0;
            pending <= 32'h0;
        end 
        else 
        begin
            if (claim_id_read) 
            begin
                pending <= (pending & ~(32'h1 << claim_id)) | hw_irq;
            end 
            else if (write_enable) 
            begin
                case (PADDR)
                    REG_INT_EN: 
                        enable <= PWDATA;
                    
                    REG_INT_SET_PENDING: 
                        pending <= pending | PWDATA | hw_irq;

                    REG_INT_CLR_PENDING: 
                        pending <= (pending & ~PWDATA) | hw_irq;
                    
                    default: ;
                endcase
            end 
            else 
            begin
                pending <= pending | hw_irq;
            end
        end
    end

    always_comb
    begin
        PRDATA = 32'h0;
        if(read_enable) 
        begin
            case(PADDR)
                REG_INT_EN:
                    PRDATA = enable;
                REG_INT_PENDING:
                    PRDATA = (pending & enable);
                REG_INT_CLAIM_ID:
                    PRDATA = {27'b0, claim_id};
                default:
                    PRDATA = 32'h0;
            endcase
        end
    end

endmodule