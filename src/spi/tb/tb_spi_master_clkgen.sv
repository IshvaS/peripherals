`timescale 1ns/1ps

module tb_spi_master_clkgen;

    parameter CLK_PERIOD = 10;

    logic clk;
    logic reset_n;

    logic [7:0] clk_div;
    logic clk_div_valid;

    logic en;

    logic spi_clk;
    logic spi_rise;
    logic spi_fall;

    spi_master_clkgen dut (
        .clk(clk),
        .rstn(reset_n),
        .clk_div(clk_div),
        .clk_div_valid(clk_div_valid),
        .en(en),
        .spi_clk(spi_clk),
        .spi_rise(spi_rise),
        .spi_fall(spi_fall)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2)
            clk = ~clk;
    end

  	initial begin
    	$dumpfile("spi.vcd");
    	$dumpvars(0, tb_spi_master_clkgen);
	end
  
    // Stimulus
    initial begin

        reset_n       = 0;
        clk_div       = 8'h0A;
        clk_div_valid = 0;
        en            = 0;

        // Reset
        #20;
        reset_n = 1;

        // Load divider
        #10;
        clk_div_valid = 1;

        #10;
        clk_div_valid = 0;

        // Enable SPI clock
        #20;
        en = 1;

        // Change divider
        #100;
        clk_div = 8'h05;
        clk_div_valid = 1;

        #10;
        clk_div_valid = 0;

        // Disable SPI clock
        #150;
        en = 0;

        #100;

        $finish;
    end

endmodule