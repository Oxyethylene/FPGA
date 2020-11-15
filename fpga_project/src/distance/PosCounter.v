module PosCounter(clk_50m,rst,echo,/*dis_count,*/Led,Distance,trig);//检测回波高电平持续时间 
input clk_50m,rst,echo;
//output[19:0] dis_count;
output reg Led;
output reg Distance;
output reg trig;


parameter s0=2'b00,s1=2'b01,s2=2'b10;//状态定义 s0:限制，s1:开始测距计数，s2:结束测距计数
reg[1:0] curr_state,next_state;
reg echo_reg1,echo_reg2;
assign start=echo_reg1&~echo_reg2;//检测posedge
assign finish=~echo_reg1&echo_reg2;//检测negedge
reg[19:0] count,dis_reg;
//wire[19:0]dis_count;//测距计数
reg clk_1Hz;
reg [7:0]cnt;
//分频
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
//分频结束

always@(posedge clk)
begin
 if(!rst)//复位信号
 begin
         echo_reg1<=0;
         echo_reg2<=0;
         count<=0;
         dis_reg<=0;
         curr_state<=s0;
  end
  else
  begin
          echo_reg1<=echo;//当前
          echo_reg2<=echo_reg1;//后一个
          case(curr_state)
            s0:begin
                if(start)//检测到上升沿
                    curr_state<=next_state;//s0 to s1
                else
                    count<=0;
                end
           s1:begin
                if(finish)//检测到下降沿
                    curr_state<=next_state;//s2
                else
                    begin
                    count<=count+1;
                    end
               end
           s2:begin
                    dis_reg<=count;//缓存计数结果
                    count<=0;
                    curr_state<=next_state;//s0
                    Distance= dis_reg*17/1000;//距离cm
                    if(Distance<10)
                        Led<=1;
                    else 
                        Led<=1;
              end
         endcase
   end 
end
always@(curr_state)
begin
	case(curr_state)
	s0:next_state<=s1;
	s1:next_state<=s2;
	s2:next_state<=s0;
	endcase
end


 endmodule