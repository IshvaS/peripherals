class apb_driver
#(
    parameter APB_ADDR_WIDTH = 12
);

    virtual apb_if.master vif;

    function new(
        virtual apb_if.master vif
    );
        this.vif = vif;
    endfunction

    task automatic init();
      vif.drv_cb.PADDR   <= '0;
      vif.drv_cb.PWDATA  <= '0;
      vif.drv_cb.PWRITE  <= 0;
      vif.drv_cb.PSEL    <= 0;
      vif.drv_cb.PENABLE <= 0;
	endtask
  
    task automatic write(
        input logic [APB_ADDR_WIDTH-1:0] addr, 
        input logic [31:0] data
    );
      @(vif.drv_cb);
        vif.drv_cb.PADDR   <= addr;
        vif.drv_cb.PWDATA  <= data;
        vif.drv_cb.PWRITE  <= 1'b1;
        vif.drv_cb.PSEL    <= 1'b1;
        vif.drv_cb.PENABLE <= 1'b0;

      @(vif.drv_cb);
        vif.drv_cb.PENABLE <= 1'b1;

      @(vif.drv_cb);
        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PWRITE  <= 1'b0;

    endtask



    task automatic read(
        input logic [APB_ADDR_WIDTH-1:0] addr, 
        output logic [31:0] data
    );

      @(vif.drv_cb);
        vif.drv_cb.PADDR   <= addr;
        vif.drv_cb.PWRITE  <= 1'b0;
        vif.drv_cb.PSEL    <= 1'b1;
        vif.drv_cb.PENABLE <= 1'b0;

      @(vif.drv_cb);
        vif.drv_cb.PENABLE <= 1'b1;

      @(vif.drv_cb);
        data        = vif.drv_cb.PRDATA;
        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PWRITE  <= 1'b0;

    endtask
endclass