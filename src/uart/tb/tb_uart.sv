`timescale 1ns/1ps

module tb_uart;
    logic CLK;
    logic RSTN;

    logic [11:0] PADDR;
    logic [31:0] PWDATA;
  	logic PWRITE;
    logic PSEL;
    logic PENABLE;

    logic [31:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    logic rx_i;
    logic tx_o;

    logic event_o;
  
  	assign rx_i = tx_o;

    // Change your testbench parameters to match the DUT 3-bit indexing
parameter RBR = 12'h0, THR = 12'h0, DLL = 12'h0, 
          IER = 12'h1, DLM = 12'h1, 
          IIR = 12'h2, FCR = 12'h2, 
          LCR = 12'h3, 
          MCR = 12'h4, LSR = 12'h5, MSR = 12'h6, SCR = 12'h7;

    apb_uart_sv dut (.*);

    task automatic write(
        input logic [11:0] addr,
        input logic [31:0] data
    );
    begin
        @(posedge CLK);
        PADDR = addr;
        PWDATA = data;
        PSEL = 1;
        PWRITE =1;

        @(posedge CLK);
        PENABLE = 1;

        @(posedge CLK);
        PENABLE = 0;
        PSEL = 0;
        PWRITE = 0;
        $display("[WRITE] Address = %h Data = %h ========", addr, data);
    end
    endtask

    logic [31:0] read_data;
    task automatic read(
        input logic [11:0] addr,
      output logic [31:0] data
    );
    begin
        @(posedge CLK);
        PADDR = addr;
        PSEL = 1;
        PWRITE =0;

        @(posedge CLK);
        PENABLE = 1;

        @(posedge CLK);
        PENABLE = 0;
        PSEL = 0;

        data = PRDATA;

        $display("[READ] Address = %h Data = %h ", addr, data);
    end
    endtask

    task automatic test(
        input logic [11:0] addr,
        input logic [31:0] data
    );
    begin
        write(addr, data);
        read(addr, read_data);
        if (read_data !== data)
            $display("[TEST FAILED] Address = %h Expected Data = %h Read Data = %h", addr, data, read_data);
        else
            $display("[TEST PASSED] Address = %h Expected Data = %h Read Data = %h", addr, data, read_data);
    end
    endtask
  
  	// 1. Unified clock generation
initial begin
    CLK = 0;
    forever #5 CLK = ~CLK;
end

// 2. Safe, time-0 initialization sequence
initial begin
    $display("TB STARTED @%0t", $time);
    
    // Force clean initial states at exactly time 0!
    RSTN   = 0;  // Start in active reset to keep state machines quiet
    PADDR  = 0;
    PWDATA = 0;
    PWRITE = 0;
    PSEL   = 0;
    PENABLE= 0;
//   	tx_o = 0;
//     rx_i   = 1;  // UART idle state is high, not low!
    
    // Now allow time to advance
    #20; 
    RSTN   = 1;  // Release reset
    $display("======== Reset done ========");
    
    #10;
    // Fix addresses according to the 3-bit design parameters:
    test(LCR, 32'h00000080); // Enable DLAB
  test(DLL, 32'h00000002); // Set a safe, non-zero divisor (e.g. 24)
    test(DLM, 32'h00000000);
  
    test(LCR, 32'h00000003); // Disable DLAB, set 8-bit mode
  	test(IER, 32'h0000_0007);
  	read(LSR, read_data);
  	$display("LSR = %h after reset", read_data);
  
  	write(THR, 32'h0000_0055);
    repeat(100) @(posedge CLK); // Wait for the byte to be transmitted
  	read_data = 32'h0;
    while (read_data[0] == 1'b0) begin
        read(LSR, read_data);
     	#10; // Avoid slamming the delta steps
    end
    $display("[RX] Data detected in Receiver FIFO!");
  
//   	read(RBR, read_data);
  	read(RBR, read_data);
	if (read_data[7:0] == 8'h55) // Explicitly check the byte lane
    	$display("[PASS] Expected = 55 Actual = %h", read_data[7:0]);
	else
    	$display("[FAIL] Expected = 55 Actual = %h", read_data[7:0]);
    
    $display("Configuration Complete!");
    #200;
    $finish;
end
endmodule