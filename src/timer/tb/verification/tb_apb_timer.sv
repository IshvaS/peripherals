`timescale 1ns/1ps
`include "apb_if.sv"
`include "apb_master.sv"
`include "timer_scoreboard.sv"

module tb_apb_timer;

    initial begin
      $dumpfile("apb_timer.vcd");
      $dumpvars(0, tb_apb_timer);
    end

    localparam CLK_PERIOD = 10;
  
    logic PCLK;
    wire [1:0] irq_o;

    timer dut (
        .HCLK        (apb.HCLK),
        .HRESETn     (apb.HRESETn),
        .PSEL        (apb.PSEL),
        .PENABLE     (apb.PENABLE),
        .PWRITE      (apb.PWRITE),
        .PADDR       (apb.PADDR),
        .PWDATA      (apb.PWDATA),
        .PRDATA      (apb.PRDATA),
        .PREADY      (apb.PREADY),
        .PSLVERR     (apb.PSLVERR),
        .irq_o       (irq_o)
    );

    localparam APB_ADDR_WIDTH = 12;
    localparam REG_TIMER      = 12'h000;
    localparam REG_TIMER_CTRL = 12'h004;
    localparam REG_CMP        = 12'h008;

    initial begin
        PCLK = 0;
        forever #(CLK_PERIOD/2) PCLK = ~PCLK;
    end
  
    task automatic reset_dut;
    begin
        apb.HRESETn = 1'b0;
        master.init();
        repeat(5) @(posedge apb.HCLK);
        apb.HRESETn = 1'b1;
        repeat(2) @(posedge apb.HCLK);
        $display("\n========== RESET DONE ==========\n");
    end
    endtask

    logic [31:0] edata, rdata;
  
    logic [APB_ADDR_WIDTH-1:0] target_registers[] = '{
        REG_TIMER, REG_TIMER_CTRL, REG_CMP
    };
  
    apb_if           apb(PCLK);
    apb_master       master;
    timer_scoreboard timer; // Scoreboard instance object handle

    initial begin
        master = new(apb);
        timer = new();
        
        reset_dut();
        timer.reset(); // Establish baseline state predictions

        // -----------------------------------------------------
        // PHASE 1: RESET TEST
        // -----------------------------------------------------
        $display("\n========== RESET TEST ==========\n");
        for(int i=0; i< target_registers.size(); i++) begin
            master.read(target_registers[i], rdata);
            timer.read_exp(target_registers[i], rdata);
        end

        // -----------------------------------------------------
        // PHASE 2: WRITE-READ TEST 
        // -----------------------------------------------------
        $display("========== WRITE-READ TEST ==========");
        $display("========== TIMER-FUNC TEST ==========");
        repeat(1000) begin
          foreach (target_registers[i]) begin
            edata = $urandom() & ((target_registers[i] == REG_TIMER_CTRL)?32'hFFFF_FFFE:32'hFFFF_FFFF);
              master.write(target_registers[i], edata);
              timer.write_exp(target_registers[i], edata); 

              master.read(target_registers[i], rdata);
              timer.read_exp(target_registers[i], rdata);
          end
        
        // -----------------------------------------------------
        // PHASE 3: TIMER FUNCTIONALITY TEST
        // -----------------------------------------------------
          master.write(REG_TIMER, edata);
          timer.write_exp(REG_TIMER, edata); // Sync scoreboard state
          master.write(REG_TIMER_CTRL, 32'h1); 
          timer.write_exp(REG_TIMER_CTRL, 32'h1); // Sync scoreboard state

          repeat(3) timer.tick(); //compensate bus latency

          repeat(20) begin
            @(posedge apb.HCLK);
            timer.tick();
          end

          master.write(REG_TIMER_CTRL, 32'h0); // Disable timer
          timer.write_exp(REG_TIMER_CTRL, 32'h0); // Sync scoreboard state
          master.read(REG_TIMER, rdata);       // Read back value
          timer.read_exp(REG_TIMER, rdata);    // Check against expected value

          assert(rdata == timer.get_timer()) 
          else $error("Timer mismatch DUT=%0d EXP=%0d", rdata, timer.get_timer());
        end

        // -----------------------------------------------------
        // PHASE 4: TIMER RESET ON CMP WRITE TEST
        // -----------------------------------------------------
        $display("\n========== TIMER RESET ON CMP WRITE TEST ==========\n");
        repeat(5) begin
            reset_dut();
            timer.reset();

          	edata = $urandom();
            master.write(REG_TIMER, edata);
            timer.write_exp(REG_TIMER, edata);
          
            master.write(REG_TIMER_CTRL, 32'h1); 
            timer.write_exp(REG_TIMER_CTRL, 32'h1);

          	repeat(3) timer.tick()++;
          
            repeat(10) begin
                @(posedge apb.HCLK);
                timer.tick();   
            end

            master.write(REG_TIMER_CTRL, 32'h0);
            timer.write_exp(REG_TIMER_CTRL, 32'h0); 
          
            master.read(REG_TIMER, rdata);
            timer.read_exp(REG_TIMER, rdata);

            assert(rdata > 0)
            else
                $error("Timer did not count");

            master.write(REG_CMP, edata);
            timer.write_exp(REG_CMP, edata); // Sync scoreboard state

            master.read(REG_TIMER, rdata);
            timer.read_exp(REG_TIMER, rdata);

            assert(rdata == 0)
            else
                $error("Timer not reset after CMP write");
        end
        timer.report_summary();
        $finish;
    end

endmodule