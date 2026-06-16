import uart_pkg::*;

module apb_uart_sv
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HResetn,

    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    input  logic                      rx_i,      // Receiver input
    output logic                      tx_o,      // Transmitter output

    output logic                      event_o    // interrupt/event output
);

    parameter TX_FIFO_DEPTH = 16; // in bytes
    parameter RX_FIFO_DEPTH = 16; // in bytes

    logic [2:0]       register_adr;
    logic [9:0][7:0]  regs_q, regs_n;
    logic [1:0]       trigger_level_n, trigger_level_q;

    // receive buffer register, read only
    logic [7:0]       rx_data;
    // parity error
    logic             parity_error;
    logic [3:0]       IIR_o;
    logic [3:0]       clr_int;

    /* verilator lint_off UNOPTFLAT */
    // tx flow control
    logic             tx_ready;
    /* lint_on */

    // rx flow control
    logic             apb_rx_ready;
    logic             rx_valid;

    logic             tx_fifo_clr_n, tx_fifo_clr_q;
    logic             rx_fifo_clr_n, rx_fifo_clr_q;

    logic             fifo_tx_valid;
    logic             tx_valid;
    logic             fifo_rx_valid;
    logic             fifo_rx_ready; //fixed read error
    logic             rx_ready;

    logic             [7:0] fifo_tx_data;
    logic             [8:0] fifo_rx_data;

    logic             [7:0] tx_data;
    logic             [$clog2(TX_FIFO_DEPTH):0] tx_elements;
    logic             [$clog2(RX_FIFO_DEPTH):0] rx_elements;

    wire write_enable = PSEL && PENABLE && PWRITE;
    wire read_enable  = PSEL && PENABLE && !PWRITE;
    assign register_adr = PADDR[4:2];

    uart_rx uart_rx_i
    (
        .clk_i              ( HCLK                          ),
        .rstn_i             ( HResetn                       ),
        .rx_i               ( rx_i                          ),
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( {regs_q[REG_DLM + 'd8], regs_q[REG_DLL + 'd8]}    ),
        .cfg_parity_en_i    ( regs_q[REG_LCR][3]                ),
        .cfg_bits_i         ( regs_q[REG_LCR][1:0]              ),
        // .cfg_stop_bits_i    ( regs_q[REG_LCR][2]                ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (                               ),
        /* lint_on */
        .err_o              ( parity_error                  ),
        .err_clr_i          ( 1'b1                          ),
        .rx_data_o          ( rx_data                       ),
        .rx_valid_o         ( rx_valid                      ),
        .rx_ready_i         ( rx_ready                      )
    );

    uart_tx uart_tx_i
    (
        .clk_i              ( HCLK                          ),
        .rstn_i             ( HResetn                       ),
        .tx_o               ( tx_o                          ),
        /* verilator lint_off PINCONNECTEMPTY */
        .busy_o             (                               ),
        /* lint_on */
        .cfg_en_i           ( 1'b1                          ),
        .cfg_div_i          ( {regs_q[REG_DLM + 'd8], regs_q[REG_DLL + 'd8]}    ),
        .cfg_parity_en_i    ( regs_q[REG_LCR][3]                ),
        .cfg_bits_i         ( regs_q[REG_LCR][1:0]              ),
        .cfg_stop_bits_i    ( regs_q[REG_LCR][2]                ),

        .tx_data_i          ( tx_data                       ),
        .tx_valid_i         ( tx_valid                      ),
        .tx_ready_o         ( tx_ready                      )
    );

    io_generic_fifo
    #(
        .DATA_WIDTH         ( 9                             ),
        .BUFFER_DEPTH       ( RX_FIFO_DEPTH                 )
    )
    uart_rx_fifo_i
    (
        .clk_i              ( HCLK                           ),
        .rstn_i             ( HResetn                       ),

        .clr_i              ( rx_fifo_clr_q                 ),

        .elements_o         ( rx_elements                   ),

        .data_o             ( fifo_rx_data                  ),
        .valid_o            ( fifo_rx_valid                 ),
        .ready_i            ( fifo_rx_ready                 ),

        .valid_i            ( rx_valid                      ),
        .data_i             ( { parity_error, rx_data }     ),
        .ready_o            ( rx_ready                      )
    );

    io_generic_fifo
    #(
        .DATA_WIDTH         ( 8                             ),
        .BUFFER_DEPTH       ( TX_FIFO_DEPTH                 )
    )
    uart_tx_fifo_i
    (
        .clk_i              ( HCLK                           ),
        .rstn_i             ( HResetn                       ),

        .clr_i              ( tx_fifo_clr_q                 ),

        .elements_o         ( tx_elements                   ),

        .data_o             ( tx_data                       ),
        .valid_o            ( tx_valid                      ),
        .ready_i            ( tx_ready                      ),

        .valid_i            ( fifo_tx_valid                 ),
        .data_i             ( fifo_tx_data                  ),
        // not needed since we are getting the status via the fifo population
        .ready_o            (                               )
    );

    uart_interrupt
    #(
        .TX_FIFO_DEPTH (TX_FIFO_DEPTH),
        .RX_FIFO_DEPTH (RX_FIFO_DEPTH)
    )
    uart_interrupt_i
    (
        .clk_i              ( HCLK                           ),
        .rstn_i             ( HResetn                       ),


        .IER_i              ( regs_q[REG_IER][2:0]              ), // interrupt enable register
        .RDA_i              ( regs_n[REG_LSR][5]                ), // receiver data available
        .CTI_i              ( 1'b0                          ), // character timeout indication


        .error_i            ( regs_n[REG_LSR][2]                ),
        .rx_elements_i      ( rx_elements                   ),
        .tx_elements_i      ( tx_elements                   ),
        .trigger_level_i    ( trigger_level_q               ),

        .clr_int_i          ( clr_int                       ), // one hot

        .interrupt_o        ( event_o                       ),
        .IIR_o              ( IIR_o                         )

    );

    // UART Registers

    // register write and update logic
    always_comb
    begin
        regs_n          = regs_q;
        trigger_level_n = trigger_level_q;

        fifo_tx_valid   = 1'b0;
        tx_fifo_clr_n   = 1'b0; // self clearing
        rx_fifo_clr_n   = 1'b0; // self clearing

        // rx status
        regs_n[REG_LSR][0] = fifo_rx_valid; // fifo is empty

        // parity error on receiving part has occured
        regs_n[REG_LSR][2] = fifo_rx_data[8]; // parity error is detected when element is retrieved

        // tx status register
        regs_n[REG_LSR][5] = ~ (|tx_elements); // fifo is empty
        regs_n[REG_LSR][6] = tx_ready & ~ (|tx_elements); // shift register and fifo are empty

        if (write_enable)
        begin
            case (register_adr)

                REG_THR: // either THR or DLL
                begin
                    if (regs_q[REG_LCR][7]) // Divisor Latch Access Bit (DLAB)
                    begin
                        regs_n[REG_DLL + 'd8] = PWDATA[7:0];
                    end
                    else
                    begin
                        fifo_tx_data = PWDATA[7:0];
                        fifo_tx_valid = 1'b1;
                    end
                end

                REG_IER: // either IER or DLM
                begin
                    if (regs_q[REG_LCR][7]) // Divisor Latch Access Bit (DLAB)
                        regs_n[REG_DLM + 'd8] = PWDATA[7:0];
                    else
                        regs_n[REG_IER] = PWDATA[7:0];
                end

                REG_LCR:
                    regs_n[REG_LCR] = PWDATA[7:0];

                REG_FCR: // write only register, fifo control register
                begin
                    rx_fifo_clr_n   = PWDATA[1];
                    tx_fifo_clr_n   = PWDATA[2];
                    trigger_level_n = PWDATA[7:6];
                end

                default: ;
            endcase

        end

    end

    logic fifo_rx_ready_n; //fixed read error 

    // register read logic
    always_comb
    begin
        PRDATA = 'b0;
        apb_rx_ready = 1'b0;
        fifo_rx_ready_n = 1'b0;
        clr_int      = 4'b0;

        if (read_enable)
        begin
            case (register_adr)
                REG_RBR: // either RBR or DLL
                begin
                    if (regs_q[REG_LCR][7]) // Divisor Latch Access Bit (DLAB)
                        PRDATA = {24'b0, regs_q[REG_DLL + 'd8]};
                    else
                    begin

                        fifo_rx_ready_n = 1'b1;

                        PRDATA = {24'b0, fifo_rx_data[7:0]};

                        clr_int = 4'b1000; // clear Received Data Available interrupt
                    end
                end

                REG_LSR: // Line Status Register
                begin
                    PRDATA = {24'b0, regs_q[REG_LSR]};
                    clr_int = 4'b1100; // clear parrity interrupt error
                end

                REG_LCR: // Line Control Register
                    PRDATA = {24'b0, regs_q[REG_LCR]};

                REG_IER: // either IER or DLM
                begin
                    if (regs_q[REG_LCR][7]) // Divisor Latch Access Bit (DLAB)
                        PRDATA = {24'b0, regs_q[REG_DLM + 'd8]};
                    else
                        PRDATA = {24'b0, regs_q[REG_IER]};
                end

                REG_IIR: // interrupt identification register read only
                begin
                    PRDATA = {24'b0, 1'b1, 1'b1, 2'b0, IIR_o};
                    clr_int = 4'b0100; // clear Transmitter Holding Register Empty
                end

                default: ;
            endcase
        end
    end

    // synchronouse part
    always_ff @(posedge HCLK, negedge HResetn)
    begin
        if(!HResetn)
        begin

            regs_q[REG_IER]       <= 8'h0;
            regs_q[REG_IIR]       <= 8'h1;
            regs_q[REG_LCR]       <= 8'h0;
            regs_q[REG_MCR]       <= 8'h0;
            regs_q[REG_LSR]       <= 8'h60;
            regs_q[REG_MSR]       <= 8'h0;
            regs_q[REG_SCR]       <= 8'h0;
            regs_q[REG_DLM + 'd8] <= 8'h0;
            regs_q[REG_DLL + 'd8] <= 8'h0;

            trigger_level_q <= 2'b00;
            tx_fifo_clr_q   <= 1'b0;
            rx_fifo_clr_q   <= 1'b0;
            fifo_rx_ready   <= 1'b0;

        end
        else
        begin
            regs_q <= regs_n;

            trigger_level_q <= trigger_level_n;
            tx_fifo_clr_q   <= tx_fifo_clr_n;
            rx_fifo_clr_q   <= rx_fifo_clr_n;
            fifo_rx_ready   <= fifo_rx_ready_n;

        end
    end

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule
