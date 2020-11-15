`timescale 1ns/1ps

`include "i2c_slave_defines.v"

`define     BIT_WIDTH       8
`define     ADDR_WIDTH      255
`define     DATA_WIDTH      255
`define     RAM             

module I2C_SLAVE_Top (
    clk,
    rstn,
    scl,
    sda,
    int_o
);

    input               clk;
    input               rstn;
    input               scl;
    inout               sda;
    output              int_o;

    wire                mem_clk;
    wire                mem_ce;
    wire                mem_oce;
    wire                mem_rst;
    wire [2:0]          mem_blksel;
    wire                mem_wre;
    wire [7:0]          mem_ad;
    wire [7:0]          mem_do;
    wire [7:0]          mem_di;

    i2c_slave u_i2c_slave   (
        .clk_in     (   clk             ),
        .rstn       (   rstn            ),
    //-----mem(ram,rom) interface --------------
        .CLK        (   mem_clk         ),
        .CE         (   mem_ce          ),
        .OCE        (   mem_oce         ),
        .RESET      (   mem_rst         ),
        .WRE        (   mem_wre         ),
        .BLKSEL     (   mem_blksel      ),
        .AD         (   mem_ad          ),
        .DO         (   mem_do          ),
        .DI         (   mem_di          ),
        .INT_O      (   int_o           ),
    //-----mem(ram,rom) interface --------------
        .scl        (   scl             ),
        .sda        (   sda             )
        );

`ifdef  RAM  
    SP gw_sp        (
        .CLK        (   mem_clk         ),
        .CE         (   mem_ce          ),
        .OCE        (   mem_oce         ),
        .RESET      (   mem_rst         ),
        .WRE        (   mem_wre         ),
        .BLKSEL     (   mem_blksel      ),
        .AD         (   {1'b0,1'b0,1'b0,mem_ad[7:0],1'b0,1'b0,1'b0} ),
        .DO         (   mem_do[7:0]     ),  //if no "ifdef ... endif", mem_do has two source and one sink,so syns,parser,pnr error.
        .DI         (   mem_di[7:0]     )
        ); 
    defparam gw_sp.READ_MODE = 1'b0;
    defparam gw_sp.WRITE_MODE = 2'b00;
    defparam gw_sp.BIT_WIDTH = 8;
    defparam gw_sp.BLK_SEL = 3'b000;
    defparam gw_sp.RESET_MODE = "SYNC";
`endif

`ifdef  ROM
    ROM gw_rom      (
        .CLK        (   mem_clk         ),
        .CE         (   mem_ce          ),
        .OCE        (   mem_oce         ),
        .RESET      (   mem_rst         ),
        .WRE        (   mem_wre         ),
        .BLKSEL     (   mem_blksel      ),
        .AD         (   {1'b0,1'b0,1'b0,mem_ad[7:0],1'b0,1'b0,1'b0} ),
        .DO         (   mem_do[7:0]     )    //if no "ifdef ... endif", mem_do has two source and one sink,so syns,parser,pnr error.
        );
    defparam gw_rom.READ_MODE = 1'b0;
    defparam gw_rom.BIT_WIDTH = 8;
    defparam gw_rom.BLK_SEL = 3'b000;
    defparam gw_rom.RESET_MODE = "SYNC";

    `include "rom_init.v"
	
    defparam gw_rom.INIT_RAM_00 = `INIT_RAM_00_DATA;
    defparam gw_rom.INIT_RAM_01 = `INIT_RAM_01_DATA;
    defparam gw_rom.INIT_RAM_02 = `INIT_RAM_02_DATA;
    defparam gw_rom.INIT_RAM_03 = `INIT_RAM_03_DATA;
    defparam gw_rom.INIT_RAM_04 = `INIT_RAM_04_DATA;
    defparam gw_rom.INIT_RAM_05 = `INIT_RAM_05_DATA;
    defparam gw_rom.INIT_RAM_06 = `INIT_RAM_06_DATA;
    defparam gw_rom.INIT_RAM_07 = `INIT_RAM_07_DATA;	

//    `include "rom_init.v"	
	
`endif

endmodule


module i2c_slave ( 
    clk_in,            //system clock, from master
    rstn,            //system reset, from master
    CLK,            //mem(ram,rom) port
    CE,
    OCE,
    RESET,
    WRE,
    AD,
    BLKSEL,
    DO,
    DI,
    INT_O,
    scl,            //i2c
    sda
);
    //port declaration
    input                       clk_in;
    input                       rstn;
    input                       scl;
    inout                       sda;
    output                      CLK;
    output                      CE;
    output                      OCE;
    output                      RESET;
    output                      WRE;
    output [2:0]                BLKSEL;
    output [`BIT_WIDTH-1:0]     AD;
    output [`BIT_WIDTH-1:0]     DI;
    input  [`BIT_WIDTH-1:0]     DO;
    output                      INT_O;

    //variable declaration
   // reg [7:0] mem [255:0]/* synthesis syn_ramstyle = "block_ram" */; 
    reg [`BIT_WIDTH-1:0]        word_address        =   0;  
    reg                         start_condition     =   0;
    reg                         stop_condition      =   0;
    reg                         sda_reg             =   0;
    reg                         sda_reg_dly         =   0;
    reg                         scl_reg             =   0;
    reg                         scl_reg_dly         =   0;
    reg                         scl_posedge         =   0;
    reg                         scl_negedge         =   0;
    reg [3:0]                   cstate              =   0/* synthesis syn_keep=1 */;
    reg [3:0]                   nstate              =   0/* synthesis syn_keep=1 */;
    reg [`BIT_WIDTH:0]          in_reg              =   0; 
    //reg [7:0] out_reg;
                           
    reg [3:0]                   bit_counter         =   0; 
                       
    reg                         w_r_flag            =   0; //1:read , 0: write 
    reg                         slave_addr_flag     =   0; 
    reg                         sda_out             =   0;
    reg                         in_reg_enable       =   0; // 1: sda in to fill in_reg  
    reg                         sda_out_en          =   0; // 1: out, 0: disabled
    reg                         word_add_flag       =   0;
    reg                         ack_flag            =   0;

    wire                        sda_negedge;
    wire                        sda_posedge;

    reg                         clken               =   0;
    reg                         clken_reg           =   0;
    reg                         wre_reg             =   0;
    reg [`BIT_WIDTH-1:0]        ad_reg              =   0;
    reg [`BIT_WIDTH-1:0]        rom_out_reg         =   0;
    reg [`BIT_WIDTH-1:0]        di_reg              =   0;
    reg [`BIT_WIDTH-1:0]        sp_out_reg          =   0;
    reg                         int_reg             =   0;
    reg [`BIT_WIDTH:0]          addr_len_reg        =   0;
    reg [`BIT_WIDTH:0]          data_len_reg        =   0;

    reg                         is_continue         =   0;
`ifdef  RAM
    reg                         is_write            =   0;
`endif

`ifdef  RAM
    parameter                   int_model           =   `INT_MODE; //0:after interrupt, write stop, read; 1: write and read all stop
`endif

    //parameter declaration
//    parameter                   I2C_Slave_Addr      =   7'b1010_000;
    parameter                   I2C_Slave_Addr      =   `I2C_SLAVE_ADDR;
    //FSM parameter
    parameter                   IDLE                =   4'b0000;
    parameter                   START               =   4'b0001;
    parameter                   ADDRESS             =   4'b0010;
    parameter                   ACK                 =   4'b0011;
    parameter                   DATA                =   4'b0100;
    parameter                   DATA_ACK            =   4'b0101;


/************************************************************
*INT_O
************************************************************/
    assign INT_O = int_reg;   

/*************************************************************
*mem(ram,rom) Interface 
*************************************************************/
    assign CLK = clk_in;

    assign RESET = ~rstn;

    assign BLKSEL =    3'b000;

    assign OCE  =   1'b0;

    always@(posedge clk_in)    clken_reg <=    clken;
    assign CE = clken && ~clken_reg;

    assign WRE  =   wre_reg;

    assign AD   = ad_reg;

    assign DI   = di_reg;

`ifdef  RAM
    always@(posedge clk_in) begin
        if(!wre_reg)
            sp_out_reg <=  DO;
    end

    always @ (bit_counter or sp_out_reg)begin
        case (bit_counter)
            4'd0: sda_out = sp_out_reg[7];
            4'd1: sda_out = sp_out_reg[6];
            4'd2: sda_out = sp_out_reg[5];
            4'd3: sda_out = sp_out_reg[4];
            4'd4: sda_out = sp_out_reg[3];
            4'd5: sda_out = sp_out_reg[2];
            4'd6: sda_out = sp_out_reg[1];
            4'd7: sda_out = sp_out_reg[0];
            default: sda_out = sp_out_reg[0];
        endcase
    end
`endif


`ifdef  ROM
    always@(posedge clk_in)begin
        if(!wre_reg)
            rom_out_reg <=  DO;
    end

    always @ (bit_counter or rom_out_reg)begin
        case (bit_counter)
            4'd0: sda_out = rom_out_reg[7];
            4'd1: sda_out = rom_out_reg[6];
            4'd2: sda_out = rom_out_reg[5];
            4'd3: sda_out = rom_out_reg[4];
            4'd4: sda_out = rom_out_reg[3];
            4'd5: sda_out = rom_out_reg[2];
            4'd6: sda_out = rom_out_reg[1];
            4'd7: sda_out = rom_out_reg[0];
            default: sda_out = rom_out_reg[0];
        endcase
    end
`endif

/**************************************************************
*input and output
**************************************************************/
    assign sda = (sda_out == 0 && sda_out_en) ? 1'b0 : 1'bZ;

//`ifdef In_Ram
/*    always @ (bit_counter or out_reg)begin
        case (bit_counter)
            4'd0: sda_out = out_reg[7];
            4'd1: sda_out = out_reg[6];
            4'd2: sda_out = out_reg[5];
            4'd3: sda_out = out_reg[4];
            4'd4: sda_out = out_reg[3];
            4'd5: sda_out = out_reg[2];
            4'd6: sda_out = out_reg[1];
            4'd7: sda_out = out_reg[0];
            default: sda_out = out_reg[0];
        endcase
    end
*/
//`endif

    always @ (posedge clk_in or negedge rstn)begin 
        if (!rstn) 
            in_reg <= 8'h00;
        else if (in_reg_enable) 
            in_reg<={in_reg[6:0],sda_reg_dly};
        else  
            in_reg <= in_reg;
    end

/************************************************************
*start_condition and stop_condition
************************************************************/
    always @ (posedge clk_in or negedge rstn)begin 
        if (!rstn) begin 
            sda_reg <= 1; // bus is active low
            sda_reg_dly <= 1;
        end
        else begin 
            sda_reg <= sda;
            sda_reg_dly <= sda_reg;
        end  
    end

    always @ (posedge clk_in or negedge rstn)begin   
        if (!rstn) begin 
            scl_reg <= 1;
            scl_reg_dly <= 1;
        end
        else begin
            scl_reg <= scl;
            scl_reg_dly <= scl_reg;
        end    
    end

    assign sda_negedge = sda_reg_dly && ~sda_reg;
    assign sda_posedge = sda_reg && ~sda_reg_dly;

    always@(posedge clk_in or negedge rstn)begin
      if(!rstn)begin
          start_condition<=0;
          stop_condition<=0;
      end
      else begin
          start_condition<= sda_negedge && scl_reg;
          stop_condition<= sda_posedge && scl_reg;
      end

    end

/***********************************************************
*scl_posedge and sda_negedge
***********************************************************/
    always @ (posedge clk_in or negedge rstn)begin 
    
        if (!rstn)  
            scl_posedge <= 0;    
        else if (scl_reg && !scl_reg_dly)  
            scl_posedge <= 1;
        else  
            scl_posedge <= 0; 
    end

    always @ (posedge clk_in or negedge rstn)begin     
        if (!rstn) 
            scl_negedge <= 0;
        else if (!scl_reg && scl_reg_dly)  
            scl_negedge <= 1;
        else  
            scl_negedge <= 0;
    end

/*********************************************************
*FSM
*********************************************************/
    always @ (posedge clk_in or negedge rstn)begin 
        if (!rstn)begin 
            cstate <= #1 IDLE;

            w_r_flag <= 0;
            word_address <= 0;
            word_add_flag <= 0;
            ack_flag    <=  0;
            slave_addr_flag <= 0;
            int_reg     <=  0;
            addr_len_reg <= 0;
            data_len_reg <= 0;
            is_continue <=  0;
    `ifdef RAM
            is_write    <=  0;
    `endif

        end
        else begin 
            case (cstate)
                IDLE:   begin
                            clken <= 1'b0; 
                            sda_out_en <= 1'b0;
                            if (start_condition && scl) begin
                                cstate <= START;
                               `ifdef RAM 
                                    if(is_continue && (int_model == 1))
                                        cstate <= IDLE;
                                `endif
                            end
                            else begin 
                                cstate <=  IDLE;
                                in_reg_enable <=  0;
                            end
                        end
                START:  begin 
                            clken <= 1'b0; 
                            if (start_condition && scl) 
                                cstate <=  START;
                            else if (stop_condition && scl)  
                                cstate <=  IDLE;
                            else if (scl_posedge) begin                 
                                bit_counter <=  0;
                                in_reg_enable <=  1;
                            end                 
                            else if (in_reg_enable ) begin
                                cstate <= ADDRESS; 
                                in_reg_enable <=  0; 
                                bit_counter <=  bit_counter + 1;
                                slave_addr_flag <=  0;
                                word_add_flag <=  0;
                                ack_flag <=  0;
                            end
                        end        
                ADDRESS:begin  
                            clken <= 1'b0;      
                            if (start_condition && scl)
                                cstate <=  START;
                            else if (stop_condition && scl)  
                                cstate <=  IDLE;
                            else if (scl_posedge && (bit_counter <= 8))                  
                                in_reg_enable <=  1;
                            else if (in_reg_enable) begin 
                                in_reg_enable <=  0; 
                                bit_counter <=  bit_counter + 1;
                                cstate <=  ADDRESS;
                            end        
                            else if (bit_counter == 8 ) begin 
                                if (in_reg[7:1] == I2C_Slave_Addr ) begin 
                                    w_r_flag <=  in_reg[0];
                                    cstate <=  ACK;
                                    slave_addr_flag <=  1;
                                    ack_flag <=  0; 
                                end
                                else begin 
                                    //sda_out <=  1'b1;
                                    cstate <=  IDLE;
                                end
                            end        
                        end
                ACK:    begin 
                            clken <= 1'b0;
                            if (start_condition && scl)  
                                cstate <=  START;
                            else if (stop_condition && scl)  
                                cstate <=  IDLE;
                            else if (slave_addr_flag  && scl_negedge && !ack_flag) begin 
                                sda_out_en <=  1; 
                                ack_flag <=  1;
                            end
        
                            else if (slave_addr_flag && scl_negedge  && ack_flag ) begin 
                                sda_out_en <=  0; 
                                bit_counter <= 4'b0;

                                cstate <=  DATA;                                              
                            end 
                            else  if (!slave_addr_flag ) begin 
                                sda_out_en <=  1'b0;
                                bit_counter <=  4'b0;
                                cstate <=  IDLE;
                            end
                        end 
                DATA:   begin 
                            ack_flag <= 1'b0; 
                            if (start_condition && scl)  
                                cstate <=  START;
                            else if (stop_condition && scl)  
                                cstate <=  IDLE;
                            else begin 
                                //write
                                if (!w_r_flag && scl_posedge && (bit_counter <= 8) )begin 
                                    in_reg_enable <=  1;//write
                                    clken   <=  1'b1;
                                    wre_reg <= ~w_r_flag;
                                end
                                else if (!w_r_flag && in_reg_enable && (bit_counter <= 8)) begin 
                                    // write more
                                    in_reg_enable <=  0; 
                                    bit_counter <=  bit_counter + 1;
                                    cstate <=  DATA;
                                    wre_reg <= ~w_r_flag;
                                end
                                else if (!w_r_flag && (bit_counter == 8)) begin 
                                    // write last bit
                                    clken   <=  1'b0;
                                    in_reg_enable <=  0; 
                                    cstate <=  DATA_ACK;
                                    //ack_flag <=  0; 
                                    wre_reg <= ~w_r_flag;
                                    if (!word_add_flag) begin 
                                            word_address <=  in_reg;
                                            word_add_flag <=  1;
                                            addr_len_reg <= in_reg; 
                                    end
                                    else begin
                                    `ifdef RAM
                                        is_write <= 1'b1;
                                    `endif
                                        /*di_reg <=   in_reg;
                                        data_len_reg <= in_reg; 
                                        //mem[word_address] <=  in_reg;
                                        ad_reg <=   word_address;
                                        word_address <=  word_address + 1;*/
                                        if(addr_len_reg <= `ADDR_WIDTH)begin    
                                            addr_len_reg <= addr_len_reg + 1;
                                            di_reg <= in_reg;
                                            ad_reg <= word_address;
                                            word_address <= word_address + 1;
                                        end
                                        else begin
                                            is_continue <= 1;
                                            int_reg <= 1;
                                            //cstate <= IDLE;
                                        end

                                        if(data_len_reg <= `ADDR_WIDTH)begin
                                            data_len_reg <= in_reg;
                                        end
                                        else begin
                                            is_continue <= 1;
                                            int_reg <= 1;
                                            //cstate <= IDLE;
                                        end

                                    end
                                end
                                // read 
                                else if (w_r_flag && (bit_counter == 0) && !scl_negedge) begin
                                `ifdef RAM
                                    if(!is_write)begin
                                        int_reg <= 1;
                                        cstate <= IDLE;
                                    end
                                `endif
                                    sda_out_en <= 1; 
                                    //out_reg <=  mem[word_address]; 
                                       clken <= 1'b1;
                                       wre_reg <= ~w_r_flag;
                                       ad_reg <= word_address;
                                       addr_len_reg <= word_address;
                                       if(addr_len_reg >= (`ADDR_WIDTH+1))begin
                                           int_reg <= 1;
                                           cstate <= IDLE;
                                       end
                                end
                                else if (w_r_flag && (bit_counter < 7) && scl_negedge) begin
                                    bit_counter <=  bit_counter + 1; 
                                        wre_reg <= ~w_r_flag;
                                end
                                else if (w_r_flag && (bit_counter == 7) && scl_negedge) begin
                                    bit_counter <=  0; 
                                    sda_out_en <=  0; 
                                    //cstate <=  DATA_ACK;
                                    //ack_flag <=  0;
                                    clken <= 1'b0;
                                    wre_reg <= ~w_r_flag;
                                    ad_reg <= word_address;
                                    word_address <=  word_address + 1;
                                    if(addr_len_reg <= `ADDR_WIDTH)begin
                                            addr_len_reg <= addr_len_reg + 1;
                                        end
                                        else begin
                                            int_reg <= 1;
                                            addr_len_reg <= 0;
                                            cstate <= IDLE;
                                        end
                                    cstate <=  DATA_ACK;
                                end
                            end // else
                        end 
            DATA_ACK:   begin 
                            clken <= 1'b0;
                            if (start_condition && scl)  
                                cstate <=  START;
                            else if (stop_condition && scl)  
                                cstate <=  IDLE;
                            else if ( !w_r_flag && scl_negedge && !ack_flag) begin
                                sda_out_en <=  1; 
                                //sda_out <=  0; 
                                ack_flag <=  1;
                            end
                            else if ( !w_r_flag && scl_negedge  && ack_flag ) begin
                                sda_out_en <=  0; 
                                ack_flag <= 0;
                                //sda_out <=  1; 
                                bit_counter <=  4'b0;
                                cstate <=  DATA; 
                            end
                            else if (w_r_flag && scl_posedge) begin 
                                if (!sda) begin 
                                    nstate <=  DATA;
                                    bit_counter <=  4'b0;
                                    ack_flag <=  1;
                                end
                                else if (sda) begin 
                                    nstate <=  IDLE;
                                    ack_flag <=  1;
                                end
                            end
                            else if (w_r_flag && scl_negedge) begin 
                                cstate <=  nstate;
                            end
                        end 
            default:    begin 
                            if (start_condition && scl)  
                                cstate <=  START;
                            else if (stop_condition && scl)  
                                cstate <=  IDLE;
                            else  
                                cstate <=  IDLE;
                        end 
            endcase
 
        end //else 
    end 

endmodule                                    


