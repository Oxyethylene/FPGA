/*============================================================================
*
*  LOGIC CORE:          以太网发送MAC层协议实现
*  MODULE NAME:         eth_send()
*  COMPANY:             武汉芯路恒科技有限公司
*                       http://xiaomeige.taobao.com
*	author:					小梅哥
*	Website:					www.corecourse.cn
*  REVISION HISTORY:  
*
*    Revision 1.0  04/10/2019     Description: Initial Release.
*
*  FUNCTIONAL DESCRIPTION:
===========================================================================*/

`timescale 1ns/1ns
module eth_send(
	rst_n,
	
	tx_go,
	data_length,
	
	des_mac,
	src_mac,
	type_length,
	CRC_Result,
	CRC_EN,
	send_done,
	
	//数据fifo
	fifo_rdreq,
	fifo_rddata,
	fifo_rdclk,
	
	//MII 接口信号	
	mii_tx_clk,
	mii_tx_en,
	mii_tx_er,
	mii_tx_data
);

	input rst_n; //复位输入
	input tx_go; //发送启动信号，单时钟周期高脉冲使能一次发送
	
	input [47:0]des_mac; //目标MAC地址
	input [47:0]src_mac; //本机/源MAC地址
	input [15:0]type_length;	//数据帧类型
	input [31:0]CRC_Result;	//CRC校验结果
	output CRC_EN;
	output reg send_done; //发送完成信号
	input [11:0]data_length;	//数据长度（因为MII接口一个字节分两个时钟，每个时钟4位的方式发送，因此本值为实际数据所占字节数的2倍）
	
	output fifo_rdreq;	//fifo读取请求	
	input [3:0]fifo_rddata;	//fifo读取到数据内容
	output fifo_rdclk;	//fifo读时钟
	
	//MII 接口信号	
	input mii_tx_clk; //MII接口发送时钟，由PHY芯片产生，25MHz
	output reg mii_tx_en;	//MII接口发送数据使能信号，高电平有效
	output mii_tx_er;	//发送错误，用以破坏数据包发送
	output reg [3:0]mii_tx_data;	//MII接口数据总线，FPGA通过该数据线将需要发送的数据依次送给PHY芯片

	reg [5:0] cnt;		//序列机计数器，本以太网帧发送系统使用线性序列机方式设计
	reg en_tx;	//内部的数据帧发送使能信号，高电平时将数据通过MII接口送出
	wire en_tx_data;	//发送MAC帧中数据部分使能信号，一个完整的MAC帧包含数据和MAC帧头以及结尾的校验部分，本信号用于标识帧中数据段部分
	reg [11:0]data_num;	//待发送的数据帧中数据部分数量
	
	reg [47:0]r_des_mac; //目标MAC地址
	reg [15:0]r_type_length;	//数据帧类型
	
	assign fifo_rdreq = en_tx_data;	//fifo读请求，fifo需要设置为show ahead模式
	
	assign fifo_rdclk = mii_tx_clk;	//fifo读时钟
	
	//每次启动发送时寄存目的网卡号
	always@(posedge mii_tx_clk)
	if(tx_go)
		r_des_mac <= des_mac;
	else
		r_des_mac <= r_des_mac;
	
	//每次启动发送时寄存协议类型
	always@(posedge mii_tx_clk)
	if(tx_go)
		r_type_length <= type_length;
	else
		r_type_length <= r_type_length;
	
	//根据发送启动信号产生内部发送使能信号
	always@(posedge mii_tx_clk or negedge rst_n)
	if(!rst_n)
		en_tx <= #1  1'd0;
	else if(tx_go)
		en_tx <= #1  1'd1;
	else if(cnt >= 53)//一帧数据发送完成，清零发送使能信号
		en_tx <= #1  1'd0;
	
	//主序列机计数器
	always@(posedge mii_tx_clk or negedge rst_n)
	if(!rst_n)
		cnt <= #1  6'd0;
	else if(en_tx)begin
		if(!en_tx_data) 
			cnt <= #1  cnt + 6'd1;
		else	//在发送整个帧中的数据部分时，计数器暂停
			cnt <= #1  cnt;
	end
	else
		cnt <= #1  6'd0;		
	
	//帧中数据发送使能信号
	assign en_tx_data = (cnt == 45) && (data_num > 1);
	
	//待发送数据计数器，每发送一个数据段中的数据，本计数器减1.
	always@(posedge mii_tx_clk or negedge rst_n)
	if(!rst_n)
		data_num <= #1  0;
	else if(tx_go)
		data_num <= #1  data_length;
	else if(en_tx_data)
		data_num <= #1  data_num - 1'b1;
	else
		data_num <= #1  data_num;
		
	assign CRC_EN = ((cnt > 17) && (cnt <= 46));
		
	//序列机部分，根据不同的时刻，切换MII接口数据线上的内容，包含前导码、分隔符、目的地址、源地址、以太网帧类型/长度、数据段数据、结尾CRC校验值
	always@(posedge mii_tx_clk or negedge rst_n)
	if(!rst_n)
		mii_tx_data <= #1  4'd0;
	else begin
		case(cnt)
			1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15:
				mii_tx_data <= #1  4'h5;	//前导码
				
			16: mii_tx_data <= #1  4'hd;	//分隔符
			
			//目的MAC地址
			17: mii_tx_data <= #1  r_des_mac[43:40];
			18: mii_tx_data <= #1  r_des_mac[47:44];
			19: mii_tx_data <= #1  r_des_mac[35:32];
			20: mii_tx_data <= #1  r_des_mac[39:36];
			21: mii_tx_data <= #1  r_des_mac[27:24];
			22: mii_tx_data <= #1  r_des_mac[31:28];
			23: mii_tx_data <= #1  r_des_mac[19:16];
			24: mii_tx_data <= #1  r_des_mac[23:20];
			25: mii_tx_data <= #1  r_des_mac[11:8];
			26: mii_tx_data <= #1  r_des_mac[15:12];
			27: mii_tx_data <= #1  r_des_mac[3:0];
			28: mii_tx_data <= #1  r_des_mac[7:4];
			
			//源MAC地址
			29: mii_tx_data <= #1  src_mac[43:40];
			30: mii_tx_data <= #1  src_mac[47:44];
			31: mii_tx_data <= #1  src_mac[35:32];
			32: mii_tx_data <= #1  src_mac[39:36];
			33: mii_tx_data <= #1  src_mac[27:24];
			34: mii_tx_data <= #1  src_mac[31:28];
			35: mii_tx_data <= #1  src_mac[19:16];
			36: mii_tx_data <= #1  src_mac[23:20];
			37: mii_tx_data <= #1  src_mac[11:8];
			38: mii_tx_data <= #1  src_mac[15:12];
			39: mii_tx_data <= #1  src_mac[3:0];
			40: mii_tx_data <= #1  src_mac[7:4];
			
			//以太网帧类型/长度
			41: mii_tx_data <= #1  r_type_length[11:8];
			42: mii_tx_data <= #1  r_type_length[15:12];
			43: mii_tx_data <= #1  r_type_length[3:0];
			44: mii_tx_data <= #1  r_type_length[7:4];
			
			//发送数据
			45: mii_tx_data <= #1  fifo_rddata;
			
			//发送CRC 校验结果
			46: mii_tx_data <= #1  CRC_Result[31:28];
			47: mii_tx_data <= #1  CRC_Result[27:24];
			48: mii_tx_data <= #1  CRC_Result[23:20];
			49: mii_tx_data <= #1  CRC_Result[19:16];
			50: mii_tx_data <= #1  CRC_Result[15:12];
			51: mii_tx_data <= #1  CRC_Result[11:8];
			52: mii_tx_data <= #1  CRC_Result[7:4];
			53: mii_tx_data <= #1  CRC_Result[3:0];
	
			54: mii_tx_data <= #1  4'd0;
			default: mii_tx_data <= #1  4'd0;
		endcase
	end
	
	//MII数据发送使能信号
	always@(posedge mii_tx_clk or negedge rst_n)
	if(!rst_n)
		mii_tx_en <= #1  1'b0;
	else if((cnt >= 1) && (cnt <= 53))
		mii_tx_en <= #1  1'b1;
	else
		mii_tx_en <= #1  1'b0;

	//每次发送完成，产生发送完成标志信号
	always@(posedge mii_tx_clk or negedge rst_n)
	if(!rst_n)
		send_done <= #1  1'b0;
	else if(cnt >= 53)
		send_done <= #1  1'b1;
	else
		send_done <= #1  1'b0;
		
endmodule
