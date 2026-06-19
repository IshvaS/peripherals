interface apb_if
#(
    parameter ADDR_WIDTH = 12,
    parameter DATA_WIDTH = 32
)(
    input logic HCLK
);

    logic HRESETn;

    logic [ADDR_WIDTH-1:0] PADDR;
    logic PSEL;
    logic PENABLE;
    logic PWRITE;

    logic [DATA_WIDTH-1:0] PWDATA;
    logic [DATA_WIDTH-1:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    // Driver clocking block
    clocking drv_cb @(posedge HCLK);
        output PADDR;
        output PSEL;
        output PENABLE;
        output PWRITE;
        output PWDATA;

        input  PRDATA;
        input  PREADY;
        input  PSLVERR;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge HCLK);
        input PADDR;
        input PSEL;
        input PENABLE;
        input PWRITE;
        input PWDATA;

        input PRDATA;
        input PREADY;
        input PSLVERR;
    endclocking

    modport master(
        clocking drv_cb,
        input HRESETn
    );

    modport monitor(
        clocking mon_cb,
        input HRESETn
    );

    modport slave(
        input  HCLK,
        input  HRESETn,

        input  PADDR,
        input  PSEL,
        input  PENABLE,
        input  PWRITE,
        input  PWDATA,

        output PRDATA,
        output PREADY,
        output PSLVERR
    );

endinterface