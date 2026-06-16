package gpio_regmap_pkg;

    // ---------------------------------------------------------
    // Basic I/O Control
    // ---------------------------------------------------------
    localparam logic [11:0] REG_PADDIR    = 12'h000; // BASEADDR + 0x00
    localparam logic [11:0] REG_PADIN     = 12'h004; // BASEADDR + 0x04
    localparam logic [11:0] REG_PADOUT    = 12'h008; // BASEADDR + 0x08
    localparam logic [11:0] REG_PADOUTSET = 12'h00C; // BASEADDR + 0x0C
    localparam logic [11:0] REG_PADOUTCLR = 12'h010; // BASEADDR + 0x10

    // ---------------------------------------------------------
    // Interrupt Engine Control
    // ---------------------------------------------------------
    localparam logic [11:0] REG_INTEN     = 12'h014; // BASEADDR + 0x14
    localparam logic [11:0] REG_INTMASK   = 12'h018; // BASEADDR + 0x18
    localparam logic [11:0] REG_INTSET    = 12'h01C; // BASEADDR + 0x1C
    localparam logic [11:0] REG_INTCLR    = 12'h020; // BASEADDR + 0x20
    localparam logic [11:0] REG_INTSTATUS = 12'h024; // BASEADDR + 0x24
    localparam logic [11:0] REG_INTTYPE0  = 12'h028; // BASEADDR + 0x28
    localparam logic [11:0] REG_INTTYPE1  = 12'h02C; // BASEADDR + 0x2C

    // ---------------------------------------------------------
    // Physical Pad Configuration
    // ---------------------------------------------------------
    localparam logic [11:0] REG_PADCFG0   = 12'h030; // BASEADDR + 0x30
    localparam logic [11:0] REG_PADCFG1   = 12'h034; // BASEADDR + 0x34
    localparam logic [11:0] REG_PADCFG2   = 12'h038; // BASEADDR + 0x38
    localparam logic [11:0] REG_PADCFG3   = 12'h03C; // BASEADDR + 0x3C

endpackage : gpio_regmap_pkg