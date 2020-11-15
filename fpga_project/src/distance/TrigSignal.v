module Trig1Signal(rst,trig1,clk_50m);//产生10us的触发信号,0-39合计10us为高电平，10-999999为低电平
input clk_50m,rst;//定义输入
output trig1;

reg trig1;//存储器
reg[7:0] cnt;
reg clk_1Hz;

always @(posedge clk_50m) begin   //clk_50m 表示时钟频率为1MHz
 if (rst) begin
  // reset
  cnt <= 7'b0;
 end
 else if (cnt == 7'd25) begin
  cnt <= 7'b0;
 end
 else begin
  cnt <= cnt + 1'b1;
 end
end

always @(posedge clk_50m) begin
 if (rst) begin
  // reset
  clk_1Hz <= 1'b0;
 end
 else if (cnt == 7'd25) begin
  clk_1Hz <= ~clk_1Hz;
 end
 else begin
  clk_1Hz <= clk_1Hz;
 end
end
wire clk = clk_1Hz;
reg [9:0]count;

always @(posedge clk) 
begin 
 if(rst)//复位信号
        count=0;
 else
    begin
      if (count>=10'd45)
           begin
       trig1=0;
       count=count+1;
           end
     else
          begin
                if(count==10'd400)
                    begin
                    trig1=1;
                    count=0;
                   end
           else
        count=count+1;
   end
  end
end
endmodule