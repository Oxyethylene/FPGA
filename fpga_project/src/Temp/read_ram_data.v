module read_ram_data(
        ram_do,     //数据输出
        ram_ce,     // CE时钟使能
        clk_50m,    // 时钟          
        ram_address, // 接AD       
        ram_wre,      // 0 读出     
        key2,         // 控制CE时钟使能的信号，控制该模块是否进行实际读操作
        tempture      // 温度数据
);

input clk_50m;
input key2;
output [13:0]ram_address;
output ram_wre;
output ram_ce;
output [7:0]ram_do; 
output [15:0]tempture;

// 与ram 相连接
  i2c_slave       i2c_slave (
        .CLK        (   clk_50m         ),
        .CE         (   ram_ce          ),
        .WRE        (   ram_wre         ),
        .AD         (   ram_address     ),
        .DO         (   ram_do[7:0]     )  
        ); 
    
// 与控制led模块连接
   control_led    control_led(
      .clk   (clk_50m),
      .tempture(tempture)
);


/*分频*/
reg [27:0]cnt; //计数
reg clk_1Hz;   //50M -> 1Hz

always @(posedge clk_50m) begin
	if (!key2) begin
		// reset
		cnt <= 28'b0;
	end
	else if (cnt == 28'd24999999) begin
		cnt <= 28'b0;
	end
	else begin
		cnt <= cnt + 1'b1;
	end
end

always @(posedge clk_50m) begin
	if (!key2) begin
		// reset
		clk_1Hz <= 1'b0;
	end
	else if (cnt == 28'd24999999) begin
		clk_1Hz <= ~clk_1Hz;
	end
	else begin
		clk_1Hz <= clk_1Hz;
	end
end
/* 分频结束*/
    wire clk = clk_1Hz;
    //FSM parameter
    parameter                   START               =   4'b0000; //开始状态给CE为高电平
    parameter                   READ1               =   4'b0001; //取ram中有关数据的低八位
    parameter                   READ2               =   4'b0010; //取ram中有关数据的低八位
    reg [3:0] cstate;

    reg [3:0] bit_counter;
    reg [7:0] ram_address_reg = 8'h55;  //取温度的地址数
    reg [7:0] read1_reg;  
    reg [7:0] read2_reg;
    reg ram_ce_reg;
always @(posedge clk ) begin
	if (key2) begin
		// reset
		bit_counter <= 8'b0;
        ram_ce_reg <= 0;
	end
   else begin
         case(cstate)
            START :  begin
                            ram_ce_reg <= 1'b1 ;
                            cstate <= READ1;
                     end
            READ1 :  begin     //读取温度的低八位
                        if(bit_counter==0) begin
                            ram_address_reg <= ram_address_reg;
                            bit_counter <= bit_counter + 1;
                        end
                        if(bit_counter < 7)begin
                            bit_counter <= bit_counter + 1;
                        end
                        if(bit_counter == 7)begin
                            bit_counter <= 0 ;
                            ram_address_reg <= ram_address_reg + 1;
                             read1_reg <= ram_do;
                            cstate <= READ2;
                        end
                      end
            READ2 :  begin     //读取温度的高八位
                        if(bit_counter==0) begin
                            ram_address_reg <= ram_address_reg;
                            bit_counter <= bit_counter + 1;
                        end
                        if(bit_counter < 7)begin
                            bit_counter <= bit_counter + 1;
                        end
                        if(bit_counter == 7)begin
                            bit_counter <= 0 ;
                            ram_address_reg <= ram_address_reg + 9;
                            read2_reg <= ram_do;
                            ram_ce_reg <= 1'b0;
                            cstate <= START;
                        end
                      end
              endcase              
        end
end
assign tempture = { read1_reg, read2_reg };
assign ram_address1 = {1'b0,1'b0,1'b0, ram_address_reg[7:0],1'b0,1'b0,1'b0};  //地址
assign ram_wre = 1'b0; // 写使能输入信号读出
assign ram_ce =  ram_ce_reg; // 时钟使能输入

endmodule