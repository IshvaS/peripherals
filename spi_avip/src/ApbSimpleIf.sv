// Minimal APB master interface with blocking write/read tasks.
// Call from UVM through a virtual interface: vif.write(addr, data); vif.read(addr, data);
interface ApbSimpleIf #(parameter ADDR_W = 12) (input logic pclk, input logic presetn);

  logic [ADDR_W-1:0] paddr;
  logic [31:0]       pwdata;
  logic [31:0]       prdata;
  logic              pwrite;
  logic              psel;
  logic              penable;
  logic              pready;
  logic              pslverr;

  initial begin
    paddr   = '0;
    pwdata  = '0;
    pwrite  = 1'b0;
    psel    = 1'b0;
    penable = 1'b0;
  end

  task automatic write(input logic [ADDR_W-1:0] addr, input logic [31:0] data);
    @(posedge pclk);                       // SETUP phase
    paddr   <= addr;
    pwdata  <= data;
    pwrite  <= 1'b1;
    psel    <= 1'b1;
    penable <= 1'b0;
    @(posedge pclk);                       // ACCESS phase
    penable <= 1'b1;
    @(posedge pclk);
    while (!pready) @(posedge pclk);       // wait for PREADY
    psel    <= 1'b0;
    penable <= 1'b0;
    pwrite  <= 1'b0;
  endtask

  task automatic read(input logic [ADDR_W-1:0] addr, output logic [31:0] data);
    @(posedge pclk);                       // SETUP phase
    paddr   <= addr;
    pwrite  <= 1'b0;
    psel    <= 1'b1;
    penable <= 1'b0;
    @(posedge pclk);                       // ACCESS phase
    penable <= 1'b1;
    @(posedge pclk);
    while (!pready) @(posedge pclk);
    data = prdata;                         // sampled at the completing edge
    psel    <= 1'b0;
    penable <= 1'b0;
  endtask

endinterface : ApbSimpleIf
