module tb_uic;
	logic HCLK;
    logic HRESETn;

    logic [31:0] PADDR;
    logic [31:0] PWDATA;
    logic        PWRITE;
    logic        PSEL;
    logic        PENABLE;

    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    logic [1:0] timer_irq;
    logic [1:0] i2c_irq;
    logic spi_irq;
    logic uart_irq;
    logic gpio_irq;
    logic soft_irq;

    logic [7:0] irq_vector;
    logic irq;

    logic irq_ack;

    apb_uic dut(*);

    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end

    initial begin
        $dumpfile("tb_uic.vcd");
        $dumpvars(0, tb_uic);
    end

    initial begin
        HRESETn = 0;
        #15 HRESETn = 1;
    end
endmodule
