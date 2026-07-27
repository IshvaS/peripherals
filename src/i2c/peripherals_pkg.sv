// ---------------------------------------------------------
// GPIO Register Map
// ---------------------------------------------------------
package gpio_pkg;

    localparam logic [11:0] REG_PADDIR      = 12'h000; // BASEADDR + 0x00
    localparam logic [11:0] REG_PADIN       = 12'h004; // BASEADDR + 0x04
    localparam logic [11:0] REG_PADOUT      = 12'h008; // BASEADDR + 0x08
    localparam logic [11:0] REG_PADOUTSET   = 12'h00C; // BASEADDR + 0x0C
    localparam logic [11:0] REG_PADOUTCLR   = 12'h010; // BASEADDR + 0x10

    localparam logic [11:0] REG_INTEN       = 12'h014; // BASEADDR + 0x14
    localparam logic [11:0] REG_INTMASK     = 12'h018; // BASEADDR + 0x18
    localparam logic [11:0] REG_INTSET      = 12'h01C; // BASEADDR + 0x1C
    localparam logic [11:0] REG_INTCLR      = 12'h020; // BASEADDR + 0x20
    localparam logic [11:0] REG_INTSTATUS   = 12'h024; // BASEADDR + 0x24
    localparam logic [11:0] REG_INTTYPE0    = 12'h028; // BASEADDR + 0x28
    localparam logic [11:0] REG_INTTYPE1    = 12'h02C; // BASEADDR + 0x2C

    localparam logic [11:0] REG_PADCFG0     = 12'h030; // BASEADDR + 0x30
    localparam logic [11:0] REG_PADCFG1     = 12'h034; // BASEADDR + 0x34
    localparam logic [11:0] REG_PADCFG2     = 12'h038; // BASEADDR + 0x38
    localparam logic [11:0] REG_PADCFG3     = 12'h03C; // BASEADDR + 0x3C

endpackage : gpio_pkg

// ---------------------------------------------------------
// Timer Register Map
// ---------------------------------------------------------
package timer_pkg;

    localparam logic [11:0] REG_TIMER       = 12'h000; // BASEADDR + 0x00
    localparam logic [11:0] REG_TIMER_CTRL  = 12'h004; // BASEADDR + 0x04
    localparam logic [11:0] REG_CMP         = 12'h008; // BASEADDR + 0x08

    localparam int REGS_OFFSET_WORD = 2;
    localparam int ADDR_BITS        = 4;

    localparam int ENABLE_BIT = 0;
    localparam int PRESCALER_STARTBIT = 16;
    localparam int PRESCALER_STOPBIT  = 31;

endpackage : timer_pkg

// ---------------------------------------------------------
// I2C Register Map
// ---------------------------------------------------------
package i2c_pkg;

    localparam logic [11:0] REG_CLK_PRESCALER = 12'h000; // BASEADDR + 0x00
    localparam logic [11:0] REG_CTRL          = 12'h004; // BASEADDR + 0x04
    localparam logic [11:0] REG_RX            = 12'h008; // BASEADDR + 0x08
    localparam logic [11:0] REG_STATUS        = 12'h00C; // BASEADDR + 0x0C
    localparam logic [11:0] REG_TX            = 12'h010; // BASEADDR + 0x10
    localparam logic [11:0] REG_CMD           = 12'h014; // BASEADDR + 0x14

    // I2C bitcontroller states
    localparam logic [3:0] I2C_CMD_NOP   = 4'b0000;
    localparam logic [3:0] I2C_CMD_START = 4'b0001;
    localparam logic [3:0] I2C_CMD_STOP  = 4'b0010;
    localparam logic [3:0] I2C_CMD_WRITE = 4'b0100;
    localparam logic [3:0] I2C_CMD_READ  = 4'b1000;

endpackage : i2c_pkg

// ---------------------------------------------------------
// SPI Register Map
// ---------------------------------------------------------
package spi_pkg;

    localparam logic [11:0] REG_STATUS = 12'h000; // BASEREG + 0x00
    localparam logic [11:0] REG_CLKDIV = 12'h004; // BASEREG + 0x04
    localparam logic [11:0] REG_SPICMD = 12'h008; // BASEREG + 0x08
    localparam logic [11:0] REG_SPIADR = 12'h00C; // BASEREG + 0x0C
    localparam logic [11:0] REG_SPILEN = 12'h010; // BASEREG + 0x10
    localparam logic [11:0] REG_SPIDUM = 12'h014; // BASEREG + 0x14
    localparam logic [11:0] REG_TXFIFO = 12'h018; // BASEREG + 0x18
    localparam logic [11:0] REG_RXFIFO = 12'h020; // BASEREG + 0x20
    localparam logic [11:0] REG_INTCFG = 12'h024; // BASEREG + 0x24
    localparam logic [11:0] REG_INTSTA = 12'h028; // BASEREG + 0x28

endpackage : spi_pkg

// ---------------------------------------------------------
// UART Register Map
// ---------------------------------------------------------
package uart_pkg;

    localparam logic [11:0] REG_RBR = 12'h000; // BASEREG + 0x00
    localparam logic [11:0] REG_THR = 12'h000; // BASEREG + 0x00
    localparam logic [11:0] REG_DLL = 12'h000; // BASEREG + 0x00
    localparam logic [11:0] REG_IER = 12'h004; // BASEREG + 0x04
    localparam logic [11:0] REG_DLM = 12'h004; // BASEREG + 0x04
    localparam logic [11:0] REG_IIR = 12'h008; // BASEREG + 0x08
    localparam logic [11:0] REG_FCR = 12'h008; // BASEREG + 0x08
    localparam logic [11:0] REG_LCR = 12'h00C; // BASEREG + 0x0C
    localparam logic [11:0] REG_MCR = 12'h010; // BASEREG + 0x10
    localparam logic [11:0] REG_LSR = 12'h014; // BASEREG + 0x14
    localparam logic [11:0] REG_MSR = 12'h018; // BASEREG + 0x18
    localparam logic [11:0] REG_SCR = 12'h01C; // BASEREG + 0x1C

endpackage : uart_pkg

// ---------------------------------------------------------
// Unified Interrupt Controller Register Map
// ---------------------------------------------------------
package uic_pkg;

    localparam logic [11:0] REG_IRQ_ENABLE    = 12'h000; // BASEREG + 0x00
    localparam logic [11:0] REG_IRQ_PENDING   = 12'h004; // BASEREG + 0x04
    localparam logic [11:0] REG_SET_PENDING   = 12'h008; // BASEREG + 0x08
    localparam logic [11:0] REG_CLR_PENDING   = 12'h00C; // BASEREG + 0x0C

    localparam int IRQ_COUNT        = 8;
    
endpackage : uic_pkg

// ---------------------------------------------------------
// Interrupt Controller Register Map
// ---------------------------------------------------------
package interrupt_pkg;

    localparam logic [11:0] REG_INT_ENABLE        = 12'h000; // BASEREG + 0x00
    localparam logic [11:0] REG_INT_PENDING       = 12'h004; // BASEREG + 0x04
    localparam logic [11:0] REG_INT_SET_PENDING   = 12'h008; // BASEREG + 0x08
    localparam logic [11:0] REG_INT_CLR_PENDING   = 12'h00C; // BASEREG + 0x0C
    localparam logic [11:0] REG_INT_CLAIM_ID      = 12'h010; // BASEREG + 0x10

endpackage : interrupt_pkg
