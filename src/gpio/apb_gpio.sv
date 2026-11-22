`include "gpio_regmap.sv"

module apb_gpio
#(
    parameter APB_ADDR_WIDTH = 12  //APB slaves are 4KB by default
)
(
    input  logic                      HCLK,
    input  logic                      HRESETn,
    input  logic [APB_ADDR_WIDTH-1:0] PADDR,
    input  logic               [31:0] PWDATA,
    input  logic                      PWRITE,
    input  logic                      PSEL,
    input  logic                      PENABLE,
    output logic               [31:0] PRDATA,
    output logic                      PREADY,
    output logic                      PSLVERR,

    input  logic               [31:0] gpio_in,

    output logic               [31:0] gpio_in_sync,
    output logic               [31:0] gpio_out,
    output logic               [31:0] gpio_dir,
    output logic      [31:0]    [3:0] gpio_padcfg,

    output logic                      interrupt
);

    logic [31:0] r_gpio_inten;
    logic [31:0] r_gpio_intmask;
    logic [31:0] r_gpio_inttype0;
    logic [31:0] r_gpio_inttype1;
    logic [31:0] r_gpio_intstatus;
    logic [31:0] s_gpio_intstatus_next;
    logic [31:0] s_intclr;
    logic [31:0] s_intset;

    logic [31:0] r_gpio_out;
    logic [31:0] r_gpio_dir;
    
    logic [31:0] r_gpio_sync0;
    logic [31:0] r_gpio_sync1;
    logic [31:0] r_gpio_in;

    logic [31:0] s_gpio_rise;
    logic [31:0] s_gpio_fall;
    logic [31:0] s_is_int_rise;
    logic [31:0] s_is_int_fall;
    logic [31:0] s_is_int_lev0;
    logic [31:0] s_is_int_lev1;
    logic [31:0] s_is_int_all;

    logic  [3:0] s_apb_addr;

    assign s_apb_addr = PADDR[5:2];

    assign gpio_in_sync = r_gpio_sync1;

    assign s_gpio_rise = r_gpio_sync1 & ~r_gpio_in; //foreach input check if rising edge
    assign s_gpio_fall = ~r_gpio_sync1 & r_gpio_in; //foreach input check if falling edge

    assign s_is_int_rise =  r_gpio_inttype1 & ~r_gpio_inttype0 & s_gpio_rise; // inttype 10 rise
    assign s_is_int_fall =  r_gpio_inttype1 &  r_gpio_inttype0 & s_gpio_fall; // inttype 11 fall
    assign s_is_int_lev0 = ~r_gpio_inttype1 &  r_gpio_inttype0 & ~r_gpio_sync1;  // inttype 01 level low 0
    assign s_is_int_lev1 = ~r_gpio_inttype1 & ~r_gpio_inttype0 &  r_gpio_sync1;  // inttype 00 level high 1

    //check if bit if interrupt is enable and if interrupt specified by inttype occurred
    //masked interrupts are stored in intstatus reg but are not used to generate interrupt
    //allow only interrupts on input pins by masking with ~r_gpio_dir
    assign s_is_int_all  = ~r_gpio_dir & r_gpio_inten & (s_is_int_rise | s_is_int_fall | s_is_int_lev0 | s_is_int_lev1);

    assign s_intclr = (PSEL && PENABLE && PWRITE && s_apb_addr == `REG_INTCLR) ? PWDATA : 32'h0;
    assign s_intset = (PSEL && PENABLE && PWRITE && s_apb_addr == `REG_INTSET) ? PWDATA : 32'h0;

    always_comb
    begin
        // Keep previous interrupt status
        s_gpio_intstatus_next = r_gpio_intstatus;

        // Clear requested interrupt bits
        s_gpio_intstatus_next =
            s_gpio_intstatus_next & ~s_intclr;

        // Add new hardware interrupts
        s_gpio_intstatus_next =
            s_gpio_intstatus_next | s_is_int_all;

        // Software-triggered interrupts
        s_gpio_intstatus_next =
            s_gpio_intstatus_next | s_intset;

    end

    
    assign interrupt = HRESETn & |(s_gpio_intstatus_next & ~r_gpio_intmask); 

    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_gpio_intstatus  <= 32'h0;
        end
        else
        begin
            r_gpio_intstatus <= s_gpio_intstatus_next;
        end
    end

    always_ff @(posedge HCLK, negedge HRESETn)
    begin
        if(~HRESETn)
        begin
            r_gpio_sync0    <= 'h0;
            r_gpio_sync1    <= 'h0;
            r_gpio_in       <= 'h0;
        end
        else 
        begin
            r_gpio_sync0    <= gpio_in;      //first 2 sync for metastability resolving
            r_gpio_sync1    <= r_gpio_sync0;
            r_gpio_in       <= r_gpio_sync1; //last reg used for edge detection
        end
    end //always

    

    always_ff @(posedge HCLK, negedge HRESETn) 
    begin
        if(~HRESETn) 
        begin
            r_gpio_inten    <=  '0;
            r_gpio_inttype0 <=  '0;
            r_gpio_inttype1 <=  '0;
            r_gpio_out      <=  '0;
            r_gpio_dir      <=  '0;
            r_gpio_intmask <= '0;
            for (int i=0;i<32;i++)
                gpio_padcfg[i]  <=  4'b0010; // DS=high, PE=disabled
        end
        else
        begin
            if (PSEL && PENABLE && PWRITE)
            begin
                case (s_apb_addr)
                `REG_PADDIR:
                    r_gpio_dir      <= PWDATA;
                `REG_PADOUT:
                    r_gpio_out      <= PWDATA;
                `REG_PADOUTSET:
                    r_gpio_out      <= r_gpio_out | PWDATA;
                `REG_PADOUTCLR:
                    r_gpio_out      <= r_gpio_out & ~PWDATA;
                `REG_INTEN:
                    r_gpio_inten    <= PWDATA;
                `REG_INTMASK:
                    r_gpio_intmask  <= PWDATA;
                `REG_INTTYPE0:
                    r_gpio_inttype0 <= PWDATA;
                `REG_INTTYPE1:
                    r_gpio_inttype1 <= PWDATA;
                `REG_PADCFG0:
                begin
                    gpio_padcfg[0]  <= PWDATA[3:0];
                    gpio_padcfg[1]  <= PWDATA[7:4];
                    gpio_padcfg[2]  <= PWDATA[11:8];
                    gpio_padcfg[3]  <= PWDATA[15:12];
                    gpio_padcfg[4]  <= PWDATA[19:16];
                    gpio_padcfg[5]  <= PWDATA[23:20];
                    gpio_padcfg[6]  <= PWDATA[27:24];
                    gpio_padcfg[7]  <= PWDATA[31:28];
                end
                `REG_PADCFG1:
                begin
                    gpio_padcfg[8]  <= PWDATA[3:0];
                    gpio_padcfg[9]  <= PWDATA[7:4];
                    gpio_padcfg[10] <= PWDATA[11:8];
                    gpio_padcfg[11] <= PWDATA[15:12];
                    gpio_padcfg[12] <= PWDATA[19:16];
                    gpio_padcfg[13] <= PWDATA[23:20];
                    gpio_padcfg[14] <= PWDATA[27:24];
                    gpio_padcfg[15] <= PWDATA[31:28];
                end
                `REG_PADCFG2:
                begin
                    gpio_padcfg[16] <= PWDATA[3:0];
                    gpio_padcfg[17] <= PWDATA[7:4];
                    gpio_padcfg[18] <= PWDATA[11:8];
                    gpio_padcfg[19] <= PWDATA[15:12];
                    gpio_padcfg[20] <= PWDATA[19:16];
                    gpio_padcfg[21] <= PWDATA[23:20];
                    gpio_padcfg[22] <= PWDATA[27:24];
                    gpio_padcfg[23] <= PWDATA[31:28];
                end
                `REG_PADCFG3:
                begin
                    gpio_padcfg[24] <= PWDATA[3:0];
                    gpio_padcfg[25] <= PWDATA[7:4];
                    gpio_padcfg[26] <= PWDATA[11:8];
                    gpio_padcfg[27] <= PWDATA[15:12];
                    gpio_padcfg[28] <= PWDATA[19:16];
                    gpio_padcfg[29] <= PWDATA[23:20];
                    gpio_padcfg[30] <= PWDATA[27:24];
                    gpio_padcfg[31] <= PWDATA[31:28];
                end
                endcase
            end
        end
    end //always

    always_comb
    begin
        PRDATA = 32'h0;
        if (PSEL && PENABLE && !PWRITE)
        begin
            case (s_apb_addr)
            `REG_PADDIR:
                PRDATA = r_gpio_dir;
            `REG_PADIN:
                PRDATA = r_gpio_sync1;
            `REG_PADOUT:
                PRDATA = r_gpio_out;
            `REG_INTEN:
                PRDATA = r_gpio_inten;
            `REG_INTMASK:
                PRDATA = r_gpio_intmask;
            `REG_INTTYPE0:
                PRDATA = r_gpio_inttype0;
            `REG_INTTYPE1:
                PRDATA = r_gpio_inttype1;
            `REG_INTSTATUS:
                PRDATA = r_gpio_intstatus;
            `REG_PADCFG0:
                PRDATA = {gpio_padcfg[7],gpio_padcfg[6],gpio_padcfg[5],gpio_padcfg[4],gpio_padcfg[3],gpio_padcfg[2],gpio_padcfg[1],gpio_padcfg[0]};
            `REG_PADCFG1:
                PRDATA = {gpio_padcfg[15],gpio_padcfg[14],gpio_padcfg[13],gpio_padcfg[12],gpio_padcfg[11],gpio_padcfg[10],gpio_padcfg[9],gpio_padcfg[8]};
            `REG_PADCFG2:
                PRDATA = {gpio_padcfg[23],gpio_padcfg[22],gpio_padcfg[21],gpio_padcfg[20],gpio_padcfg[19],gpio_padcfg[18],gpio_padcfg[17],gpio_padcfg[16]};
            `REG_PADCFG3:
                PRDATA = {gpio_padcfg[31],gpio_padcfg[30],gpio_padcfg[29],gpio_padcfg[28],gpio_padcfg[27],gpio_padcfg[26],gpio_padcfg[25],gpio_padcfg[24]};
            default:
                PRDATA = 32'h0;
            endcase
        end
    end

    assign gpio_out = r_gpio_out;
    assign gpio_dir = r_gpio_dir;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

endmodule