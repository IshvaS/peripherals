class report_summary extends timer_base_test;
  
  function new(apb_driver master);
        super.new(master);
    endfunction

    function void summary();
      $display("\n=================================");
      $display(" SCOREBOARD VERIFICATION SUMMARY ");
      $display("=================================");
      $display(" Total Passed Matches : %0d", pass);
      $display(" Total Failed Mis-matches : %0d", fail);
      $display("==============================\n");
    endfunction

endclass