`timescale 1ns/1ps

module tb_timer_basic;

    logic                      HCLK;
    logic                      HRESETn;
    logic [11:0]               PADDR;
    logic [31:0]               PWDATA;
    logic                      PWRITE;
    logic                      PSEL;
    logic                      PENABLE;
    logic [31:0]               PRDATA;
    logic                      PREADY;
    logic                      PSLVERR;

    logic [1:0]                irq_o;

    timer #(.APB_ADDR_WIDTH(12)) dut
    (
        .HCLK       ( HCLK       ),
        .HRESETn    ( HRESETn    ),
        .PADDR      ( PADDR      ),
        .PWDATA     ( PWDATA     ),
        .PWRITE     ( PWRITE     ),
        .PSEL       ( PSEL       ),
        .PENABLE    ( PENABLE    ),
        .PRDATA     ( PRDATA     ),
        .PREADY     ( PREADY     ),
        .PSLVERR    ( PSLVERR    ),

        .irq_o      ( irq_o      )
    );

    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK; // 100MHz clock
    end

    task automatic apb_write_task(input [11:0] addr, input [31:0] data);
        begin
            @(negedge HCLK);
            PADDR = addr;
            PWDATA = data;
            PWRITE = 1'b1;
            PSEL = 1'b1;
            PENABLE = 1'b0;

            @(negedge HCLK);
            PENABLE = 1'b1;

            @(negedge HCLK);
            PWRITE = 1'b0;
            PSEL = 1'b0;
            PENABLE = 1'b0;
        end
    endtask

  task automatic apb_read_task(input [11:0] addr, output logic [31:0] data);
        begin
            @(negedge HCLK);
            PADDR = addr;
            PWRITE = 1'b0;
            PSEL = 1'b1;
            PENABLE = 1'b0;

            @(negedge HCLK);
            PENABLE = 1'b1;

            @(negedge HCLK);
            data = PRDATA;
            PSEL = 1'b0;
            PENABLE = 1'b0;
        end
    endtask

    integer pass = 0, fail = 0;
    task automatic check( input [31:0] expected, input [31:0] actual);
        if (expected !== actual) begin
            $display("Test failed! Expected: %h, Actual: %h", expected, actual);
            fail++;
        end
        else begin
            $display("Test passed! Value: %h", actual);
        end
    endtask

    task automatic reset_dut;
        begin
            @(negedge HCLK);
            HRESETn = 1'b0;

            @(negedge HCLK);
            HRESETn = 1'b1;

            $display("DUT Reset Completed");
        end
    endtask

    logic [31:0] timer_value;
    initial begin
        reset_dut();

        // Test 1: Write to control register and check if timer starts counting
        apb_write_task(`REG_TIMER_CTRL, 32'h00000001); // Enable timer
        #100; // Wait for some time
        apb_read_task(`REG_TIMER, timer_value);
        #10; // Wait for read to complete
        check(32'h0000000A, timer_value); // Assuming timer increments every 10 cycles

        // Test 2: Write to compare register and check if interrupt is triggered
        apb_write_task(`REG_CMP, 32'h0000000F); // Set compare value
        #100; // Wait for some time
        check(32'b1, irq_o[0]); // Check if compare interrupt is triggered

        // Test 3: Check if timer resets after compare match
        apb_read_task(`REG_TIMER, timer_value);
        #10; // Wait for read to complete
        check(32'h00000000, timer_value); // Timer should reset to 0 after compare match

        $display("All tests completed. Passed: %0d, Failed: %0d", pass, fail);
        $finish;
    end
    
endmodule