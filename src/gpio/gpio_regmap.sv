// Basic I/O Control
`define REG_PADDIR      4'b0000 // BASEADDR + 0x00
`define REG_PADIN       4'b0001 // BASEADDR + 0x04
`define REG_PADOUT      4'b0010 // BASEADDR + 0x08
`define REG_PADOUTSET   4'b0011 // BASEADDR + 0x0C
`define REG_PADOUTCLR   4'b0100 // BASEADDR + 0x10

// Interrupt Engine Control
`define REG_INTEN       4'b0101 // BASEADDR + 0x14
`define REG_INTMASK     4'b0110 // BASEADDR + 0x18
`define REG_INTSET      4'b0111 // BASEADDR + 0x1C
`define REG_INTCLR      4'b1000 // BASEADDR + 0x20
`define REG_INTSTATUS   4'b1001 // BASEADDR + 0x24
`define REG_INTTYPE0    4'b1010 // BASEADDR + 0x28
`define REG_INTTYPE1    4'b1011 // BASEADDR + 0x2C

// Physical Pad Configurations (Drive Strength, Pull Up/Down, etc.)
`define REG_PADCFG0     4'b1100 // BASEADDR + 0x30
`define REG_PADCFG1     4'b1101 // BASEADDR + 0x34
`define REG_PADCFG2     4'b1110 // BASEADDR + 0x38
`define REG_PADCFG3     4'b1111 // BASEADDR + 0x3C