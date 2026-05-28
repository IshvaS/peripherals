// define three registers per timer - timer, cmp and prescaler registers
`define REGS_MAX_IDX              2'd2
`define REG_TIMER                 2'b00
`define REG_TIMER_CTRL            2'b01
`define REG_CMP                   2'b10

`define PRESCALER_STARTBIT        3'd3
`define PRESCALER_STOPBIT         3'd5
`define ENABLE_BIT                3'd0