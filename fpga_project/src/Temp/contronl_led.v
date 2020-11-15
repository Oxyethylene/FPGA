module control_led(
      clk,
      tempture,
      key1
);
    input clk;
    output [15:0]tempture ;
    output key1 ; 
    reg [15:0]tempture_reg ;
    reg key1_reg = 0;
 always @(posedge clk ) 
begin 
    tempture_reg  =  tempture ;
    if(tempture_reg > 16'h0EA6  ) begin
       key1_reg <= 1'b1;
    end 
    else begin
    key1_reg <= 1'b0;
    end 
end
   assign key1 = key1_reg ; 

endmodule
    