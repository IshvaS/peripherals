class apb_master
#(
    parameter APB_ADDR_WIDTH = 12
);

    virtual apb_if vif;

    function new(
        virtual apb_if vif
    );
        this.vif = vif;
    endfunction

    task automatic init();
        vif.PADDR   = '0;
        vif.PWDATA  = '0;
        vif.PWRITE  = 0;
        vif.PSEL    = 0;
        vif.PENABLE = 0;
    endtask

    task automatic write(
        input logic [APB_ADDR_WIDTH-1:0] addr, 
        input logic [31:0] data
    );
        @(posedge vif.HCLK);
        vif.PADDR   <= addr;
        vif.PWDATA  <= data;
        vif.PWRITE  <= 1'b1;
        vif.PSEL    <= 1'b1;
        vif.PENABLE <= 1'b0;

        @(posedge vif.HCLK);
        vif.PENABLE <= 1'b1;

        @(posedge vif.HCLK);
        vif.PSEL    <= 1'b0;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= 1'b0;

    endtask



    task automatic read(
        input logic [APB_ADDR_WIDTH-1:0] addr, 
        output logic [31:0] data
    );

        @(posedge vif.HCLK);
        vif.PADDR   <= addr;
        vif.PWRITE  <= 1'b0;
        vif.PSEL    <= 1'b1;
        vif.PENABLE <= 1'b0;

        @(posedge vif.HCLK);
        vif.PENABLE <= 1'b1;

        @(posedge vif.HCLK);
        data        = vif.PRDATA;
        vif.PSEL    <= 1'b0;
        vif.PENABLE <= 1'b0;
        vif.PWRITE  <= 1'b0;

    endtask
endclass