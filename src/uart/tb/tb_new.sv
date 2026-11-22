`timescale 1ns/1ps

module tb_uart;
    logic HCLK;
    logic HRESETn;

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

    parameter RBR = 12'h000, THR = 12'h000, DLL = 12'h000, 
              IER = 12'h004, DLM = 12'h004, 
              IIR = 12'h008, FCR = 12'h008, 
              LCR = 12'h00C, 
              MCR = 12'h010, LSR = 12'h14, MSR = 12'h18, SCR = 12'h1C;

    apb_uart_sv dut (.*);
    
    initial begin
      $dumpfile("tb_uart.vcd");
      $dumpvars(0, tb_uart);
    end
  
    task automatic write(
        input logic [11:0] addr,
        input logic [31:0] data
    );
    begin
        @(posedge HCLK);
        PADDR = addr;
        PWDATA = data;
        PSEL = 1;
        PWRITE = 1;

        @(posedge HCLK);
        PENABLE = 1;

        @(posedge HCLK);
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
        @(posedge HCLK);
        PADDR = addr;
        PSEL = 1;
        PWRITE = 0;

        @(posedge HCLK);
        PENABLE = 1;

        @(posedge HCLK);
      $display("READ DEBUG: PADDR=%h PRDATA=%h fifo_rx_data=%h",
         PADDR, PRDATA, dut.fifo_rx_data);
       	
      	data = PRDATA;
        
      	PENABLE = 0;
        PSEL = 0;
        

        $display("[READ] Address = %h Data = %h ", addr, data);
    end
    endtask
  	
//   always @(PRDATA)
// begin
//   $display("DEBUG: time=%0t PADDR=%h PRDATA=%h fifo_rx_data=%h", $time, PADDR, PRDATA, dut.fifo_rx_data);
// end

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
  
    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end

    initial begin
        $display("TB STARTED @%0t", $time);
        
        HRESETn = 0;
        PADDR   = 0;
        PWDATA  = 0;
        PWRITE  = 0;
        PSEL    = 0;
        PENABLE = 0;
        
        #20; 
        HRESETn    = 1;
        $display("======== Reset done ========");
        
        #10;
        test(LCR, 32'h00000080); 
      	test(DLL, 32'h00000020); 
        test(DLM, 32'h00000000);
      
      	test(LCR, 32'h0000000B); 
        test(IER, 32'h0000_0007);
        read(LSR, read_data);
        $display("LSR = %h after reset", read_data);
      
        write(THR, 32'h0000_0055);
      	repeat(10) @(posedge HCLK); 
        
        read_data = 32'h0;
        while (read_data[0] == 1'b0) begin
            read(LSR, read_data);
            #10; 
        end
        $display("[RX] Data detected in Receiver FIFO!");
      
        read(LSR, read_data);
        $display("LSR=%h", read_data);
      
        read(RBR, read_data);
        if (read_data[7:0] == 8'h55) 
            $display("[PASS] Expected = 55 Actual = %h", read_data[7:0]);
        else
            $display("[FAIL] Expected = 55 Actual = %h", read_data[7:0]);
      repeat(2)@(posedge HCLK);
      	read(RBR, read_data);
        if (read_data[7:0] == 8'h55) 
            $display("[PASS] Expected = 55 Actual = %h", read_data[7:0]);
        else
            $display("[FAIL] Expected = 55 Actual = %h", read_data[7:0]);
         
      	read(LSR, read_data);
        $display("LSR=%h", read_data);
      
      write(THR, 32'h0000_00A5);
      	repeat(10) @(posedge HCLK); 
        
        read_data = 32'h0;
        while (read_data[0] == 1'b0) begin
            read(LSR, read_data);
            #10; 
        end
        $display("[RX] Data detected in Receiver FIFO!");
      
        read(LSR, read_data);
        $display("LSR=%h", read_data);
      
        read(RBR, read_data);
      if (read_data[7:0] == 8'hA5) 
            $display("[PASS] Expected = 55 Actual = %h", read_data[7:0]);
        else
            $display("[FAIL] Expected = 55 Actual = %h", read_data[7:0]);
      
        $display("Configuration Complete!");
        #200;
        $finish;
    end
endmodule