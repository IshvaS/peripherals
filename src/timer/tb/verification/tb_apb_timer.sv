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

    always @(posedge apb.HCLK) begin
        if (apb.HRESETn) begin
          
            if (apb.PSEL && apb.PENABLE && apb.PREADY) begin
                if (apb.PWRITE) begin
                    timer.write_exp(apb.PADDR, apb.PWDATA);
                end else begin
                    timer.read_exp(apb.PADDR, apb.PRDATA);
                end
            end
            
            // 2. Step the scoreboard state forward in complete lock-step
            timer.tick();
            
            // 3. Perform cycle-by-cycle automated output checking
            assert(irq_o === timer.get_irq()) 
            else $error("Interrupt Mismatch! DUT=%b EXP=%b", irq_o, timer.get_irq());
        end
    end

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
        $display("\n========== WRITE-READ TEST ==========\n");
        repeat(1000) begin
          foreach (target_registers[i]) begin
              edata = $urandom();
              master.write(target_registers[i], edata);
              timer.write_exp(target_registers[i], edata); 

              master.read(target_registers[i], rdata);
              timer.read_exp(target_registers[i], rdata);
          end
        end
        
        // -----------------------------------------------------
        // PHASE 3: TIMER FUNCTIONALITY TEST
        // -----------------------------------------------------
        $display("\n========== TIMER FUNCTIONALITY TEST ==========\n");
        master.write(REG_TIMER, 32'h0);
        master.write(REG_TIMER_CTRL, 32'h1); 
      
        repeat(20) @(posedge apb.HCLK);      // Let it count safely

        master.write(REG_TIMER_CTRL, 32'h0); // Disable timer
        master.read(REG_TIMER, rdata);       // Read back value

        assert(rdata == timer.get_timer()) 
        else $error("Timer mismatch DUT=%0d EXP=%0d", rdata, timer.get_timer());

        timer.report_summary();
        $finish;
    end

endmodule