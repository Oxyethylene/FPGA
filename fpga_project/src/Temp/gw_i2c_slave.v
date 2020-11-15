`include "i2c_slave_defines.v"

`timescale 1ns/1ps

module gw_i2c_slave (
   clk_50m,
   rst_n,
   scl,
   scl_pull,
   sda,
   sda_pull,    
   int_o 
);
   //Controller Interface 
   input           clk_50m;
   input           rst_n;
   output          int_o;
   //i2c interface 
   inout           scl;
   output          scl_pull;
   inout           sda;
   output          sda_pull;

/////////////////////////////////////////////////////////////////////
/*reg/wire 												 		   */
   wire            rstn1;
   reg [7:0]       delay_rst=0;
   reg [7:0]       delay=0;
   reg [15:0]      counter0=0;
   reg             clk_en=0; 
   wire            clkout_50m;
///////////////////////////////////////////////////////////////////////////////////////////////////
assign rstn1=&{delay_rst[5],!delay_rst[4],!delay_rst[3],!delay_rst[2],!delay_rst[1],!delay_rst[0]};

always @(posedge clkout_50m) 
     if(counter0==16'd49999) begin
	    counter0 <= 16'd0;
		clk_en <= 1'b1;
	 end
	 else begin
	    counter0 <= counter0 + 16'd1;
		clk_en <= 1'b0;	 
	 end

always @(posedge clkout_50m)
     if(clk_en==1'b1) begin
        delay_rst[7:1] <= delay_rst[6:0];
        delay_rst[0] <= rst_n;
     end

Gowin_PLL your_instance_name(
    .clkout(clkout_50m), //output clkout
    .clkin(clk_50m) //input clkin
);	 
  
I2C_SLAVE_Top  u_i2c_slave_top ( 
  .clk(clkout_50m),
  .rstn(~rstn1),
  .scl(scl),
  .sda(sda),
  .int_o(int_o) 
);

assign scl_pull =1'b1;	
assign sda_pull =1'b1;

endmodule

