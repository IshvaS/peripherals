`include "gpio_golden_model.sv"

class gpio_scoreboard;

    gpio_golden_model golden_model;

    // Tracker variables
    int match_count = 0;
    int mismatch_count = 0;

    // 2. Instantiate the model inside the constructor
    function new();
        this.golden_model = new();
    endfunction

  
    function void write_exp(logic [11:0] addr, logic [31:0] wdata);
        golden_model.write_data(addr, wdata);
    endfunction

  
    function void read_exp(
      logic [11:0] addr, 
      logic [31:0] actual_data, 
      logic [31:0] gpio_in
    );
        logic [31:0] expected_data;
        
        // Extract the predicted data from your model
        expected_data = golden_model.read_data(addr, gpio_in);

        // Cross-check
        if (actual_data === expected_data) begin
//             $display("[SCOREBOARD PASS] Addr: %h | Data: %h", addr, actual_data);
            match_count++;
        end else begin
            $error("[SCOREBOARD FAIL] Addr: %h | Exp: %h | Act: %h", addr, expected_data, actual_data);
            mismatch_count++;
        end
    endfunction
  
  	function void report_summary();
        $display("\n==============================");
        $display("   SCOREBOARD VERIFICATION SUMMARY");
        $display("==============================");
        $display(" Total Passed Matches : %0d", match_count);
        $display(" Total Failed Mis-matches : %0d", mismatch_count);
        $display("==============================\n");
    endfunction
endclass