`timescale 1ns/1ps

`define IF_DATA_WIDTH 8
   
module gw_i2c_master (
    clk_50m,
    rst_n,
	key2,
    scl,
	scl_pull,
    sda,
	sda_pull,	
    wr_error_flag,
    cstate_f,
    interupt
);
    
 input	 clk_50m;
 input	 rst_n;
 input	 key2;	
 inout	 scl;
 inout	 sda;
 output  scl_pull;
 output  sda_pull;	
 output  wr_error_flag;
         
 output  cstate_f;
 output  interupt;

/////////////////////////////////////////////////////////////////////
/*reg/wire 												 		   */
 
 wire                        I_TX_EN;
 wire [2:0]                  I_WADDR;
 wire [`IF_DATA_WIDTH-1:0]   I_WDATA;
 wire                         I_RX_EN;
 wire [2:0]                  I_RADDR;
 wire [`IF_DATA_WIDTH-1:0]   O_RDATA;
 
 wire                        rstn1;
 wire                        start;
 reg [7:0]                   delay_rst=0;
 reg [7:0]                   delay=0;
 reg [15:0]                  counter0=0;
 reg                         clk_en=0; 
///////////////////////////////////////////////////////////////////////////////////////////////////
assign rstn1=&{delay_rst[5],!delay_rst[4],!delay_rst[3],!delay_rst[2],!delay_rst[1],!delay_rst[0]};

assign start=&{delay[5],!delay[4],!delay[3],!delay[2],!delay[1],!delay[0]};

always @(posedge clk_50m) 
     if(counter0==16'd49999) begin
	    counter0 <= 16'd0;
		clk_en <= 1'b1;
	 end
	 else begin
	    counter0 <= counter0 + 16'd1;
		clk_en <= 1'b0;	 
	 end

always @(posedge clk_50m)
     if(clk_en==1'b1) begin
        delay[7:1] <= delay[6:0];
        delay[0] <= key2;	 
	 
        delay_rst[7:1] <= delay_rst[6:0];
        delay_rst[0] <= rst_n;
     end
	 
/////////////////////////////////////////////////////////////////////
  master_sram_iic 	    u_master_sram_iic
  (
      .I_CLK              ( clk_50m                 ),
      .I_RESETN           ( ~rstn1                  ),
	  .start              ( start                   ),
      .I_TX_EN            ( I_TX_EN                 ),
      .I_WADDR            ( I_WADDR                 ),
      .I_WDATA            ( I_WDATA                 ),
      .I_RX_EN            ( I_RX_EN                 ),
      .I_RADDR            ( I_RADDR                 ),
      .O_RDATA            ( O_RDATA                 ),
      .cstate_flag        ( cstate_f                ),
      .error_flag         ( wr_error_flag           )
  );

  I2C_MASTER_Top        u_i2c_master_top
  (
      .I_CLK              ( clk_50m                 ),
      .I_RESETN           ( ~rstn1                  ),
      .I_TX_EN            ( I_TX_EN                 ),
      .I_WADDR            ( I_WADDR                 ),
      .I_WDATA            ( I_WDATA                 ),
      .I_RX_EN            ( I_RX_EN                 ),
      .I_RADDR            ( I_RADDR                 ),
      .O_RDATA            ( O_RDATA                 ),
      .O_IIC_INT          ( interupt                ),
      .SCL                ( scl                     ),
      .SDA                ( sda                     )
  );               
 I2C_SLAVE_Top 
(
    .clk(clk_50m),
    .rstn(~retn1),
    .scl(scl),
    .sda(sda),
    .int_o()
);
assign scl_pull =1'b1;	
assign sda_pull =1'b1;

endmodule