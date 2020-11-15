module my_eth (
    // ----------------PHY芯片接口----------------
    input mii_rx_clk_i,         // MII 接收时钟
    input mii_rxd_i [3:0],            // MII 接收数据
    input mii_rx_dv_i,          // MII 接收使能
    input mii_rx_er_i,          // MII 接收错误
    input mii_tx_clk_i,         // MII 发送时钟
    output mii_txd_o [3:0],           // MII 发送数据
    output mii_tx_en_o,         // MII 发送使能
    output mii_tx_er_o,         // MII 发送错误
    input mii_col_i,            // MII 冲突信号
    input mii_crs_i,            // MII 载波信号

    // ----------------gw_mac接口----------------
    input duplex_status_i,      // 以太网双工模式配置信
    input data [255:0]                  // IP复位信号，低有效

);
    // //==========================================
    // // * PHY芯片接口
    // wire mii_rx_clk_i;          // MII 接收时钟
    // wire mii_rxd_i [3:0];       // MII 接收数据
    // wire mii_rx_dv_i;           // MII 接收使能
    // wire mii_rx_er_i;           // MII 接收错误
    // wire mii_tx_clk_i;          // MII 发送时钟
    // wire mii_txd_o [3:0];       // MII 发送数据
    // wire mii_tx_en_o;           // MII 发送使能
    // wire mii_tx_er_o;           // MII 发送错误
    // wire mii_col_i;             // MII 冲突信号
    // wire mii_crs_i;             // MII 载波信号
    // //==========================================

    // wire duplex_status_i;       // 以太网双工模式配置信号
    // wire rstn;                  // IP复位信号，低有效
    
    //==========================================
    // * 传输用户接口
    wire tx_mac_clk_o;          // 用户侧发送时钟
    wire tx_mac_valid_i;        // 用户侧发送使能
    reg tx_mac_data_i [7:0];   // 用户侧发送数据
    wire tx_mac_last_i;         // 用户侧发送最后字节指示
    wire tx_mac_error_i;        // 用户侧发送错误帧指示
    wire tx_mac_ready_o;        // 用户侧发送握手信号，为 1 表示 tx_mac_data 被接收
    //==========================================

    //==========================================
    // * IP部分
    parameter [3:0] ip_version = 4'h4;      // IP版本(4)
    parameter [3:0] ip_head_len = 4'h5;     // IP首部长度(5)
    parameter [7:0] ip_qufenfuwu = 8'h0;    // IP区分服务，不使用(填0)
    parameter [15:0]ip_total_len = 8'd32 + 8'd28;	// IP数据包总长度
    parameter [15:0] ip_identify = 16'h0;    // IP标识(数字无所谓,全0)
    parameter [2:0] ip_flag = 3'b010;         // IP标志,只有前两位有用, 最低位表示MF,为1表示还有分片,中间位表示DF,0表示允许分片(填0)
    parameter [12:0] ip_fragment_offset = 13'h0; // IP片偏移,不分片,没用
    parameter [7:0] ip_ttl = 8'h11;          // IP生存时间，最大跳数
    parameter [7:0] ip_protocol = 8'h11;     // IP协议，UDP为17
	wire [15:0]ip_checksum;     // IP首部校验和
	parameter [31:0]src_ip = 32'hC0_A8_01_02;          // 源IP地址
	parameter [31:0]dst_ip = 32'hC0_A8_01_03;          // 目的IP地址
    // IP数据
    //==========================================

    //==========================================
    // * UDP部分
	parameter [15:0]src_port = 16'd5000;        // 源端口号
	parameter [15:0]dst_port = 16'd6000;	    // 目标端口号
    parameter [15:0]udp_total_len = 16'd8 +16'd32;   // UDP数据包总长度
    parameter [15:0] udp_checksum = 32'hC0_A8_01_03;   // UDP校验和(全0可以不校验)
    // UDP数据
    //==========================================

    // wire [256:0] data;            // 要传输的数据


//    duplex_status_i <= 0;
	Triple_Speed_Ethernet_MAC_Top gw_mac(
		.mii_rx_clk(mii_rx_clk_i), //input mii_rx_clk
		.mii_rxd(mii_rxd_i), //input [3:0] mii_rxd
		.mii_rx_dv(mii_rx_dv_i), //input mii_rx_dv
		.mii_rx_er(mii_rx_er_i), //input mii_rx_er
		.mii_tx_clk(mii_tx_clk_i), //input mii_tx_clk
		.mii_txd(mii_txd_o), //output [3:0] mii_txd
		.mii_tx_en(mii_tx_en_o), //output mii_tx_en
		.mii_tx_er(mii_tx_er_o), //output mii_tx_er
		.mii_col(mii_col_i), //input mii_col
		.mii_crs(mii_crs_i), //input mii_crs
		.duplex_status(duplex_status_i), //input duplex_status 0 for 全双工
		.rstn(rstn_i), //input rstn
		.tx_mac_clk(tx_mac_clk_o), //output tx_mac_clk
		.tx_mac_valid(tx_mac_valid_i), //input tx_mac_valid
		.tx_mac_data(tx_mac_data_i), //input [7:0] tx_mac_data
		.tx_mac_last(tx_mac_last_i), //input tx_mac_last
		.tx_mac_error(tx_mac_error_i), //input tx_mac_error
		.tx_mac_ready(tx_mac_ready_o) //output tx_mac_ready
	);

    // //==========================================
    // // *　设置IP首部的值
    // ip_version = 4'h4;
    // ip_head_len = 4'h5;
    // ip_qufenfuwu = 8'h0;
    // ip_total_len = 8'd32 + 8'd28;   // IP首部+UDP首部(28)+数据部分
    // ip_identify = 16'h0;
    // ip_flag = 3'b010;
    // ip_fragment_offset = 13'h0;
    // ip_ttl = 8'h11;
    // src_ip = 32'hC0_A8_01_02;
    // dst_ip = 32'hC0_A8_01_03;
    checksum checksum(
        .ver(ip_version),
        .hdr_len(ip_head_len),
        .tos(ip_qufenfuwu),
        .total_len(ip_total_len),
        .id(ip_identify),
        .offset({ip_flag, ip_fragment_offset}),
        .ttl(ip_ttl),
        .protocol(ip_protocol),
        .src_ip(src_ip),
        .dst_ip(dst_ip),
        .checksum_result(ip_checksum)
    );
    //==========================================

    // //==========================================
    // // * 设置UDP首部的值
    // src_port = 16'd5000;
    // dst_port = 16'd6000;
    // udp_total_len = 16'd8 +16'd32;  // 首部(8) + 数据部分
    // udp_checksum = 16'h0;
    // //==========================================

    reg [11:0] data_count;

    always @(posedge get_data) begin
        tx_mac_valid_i <= 1;
        data_count <= 0;
        tx_mac_last_i <= 0;
    end 
	
	//UDP包	
	always@(posedge tx_mac_ready_o)
	begin
        case(data_count)
        //  版本和首部长度
        0   : tx_mac_data_i = {ip_head_len, ip_version};data_count = data_count + 1;
        // 服务类型
        1   : tx_mac_data_i = {ip_qufenfuwu[7:4], ip_qufenfuwu[3:0]};data_count = data_count + 1;
        // IP数据报总长度
        2   : tx_mac_data_i = ip_total_len[15:8];data_count = data_count + 1;
        3   : tx_mac_data_i = ip_total_len[7:0];data_count = data_count + 1;
        // IP数据包标识
        4   : tx_mac_data_i = ip_identify[15:8];data_count = data_count + 1;
        5   : tx_mac_data_i = ip_identify[7:0];data_count = data_count + 1;
        // IP标识+分段偏移
        6   : tx_mac_data_i = ip_fragment_offset[12:5];data_count = data_count + 1;
        7   : tx_mac_data_i = {ip_fragment_offset[4:0], ip_flag};data_count = data_count + 1;
        // TTL
        8   : tx_mac_data_i = ip_ttl;data_count = data_count + 1;
        // 数据报类型
        9   : tx_mac_data_i = ip_protocol;data_count = data_count + 1;
        // IP报头校验和
        10  : tx_mac_data_i = ip_checksum[15:8];data_count = data_count + 1;
        11  : tx_mac_data_i = ip_checksum[7:0];data_count = data_count + 1;
        // 源地址
        12  : tx_mac_data_i = src_ip[31:24];data_count = data_count + 1;
        13  : tx_mac_data_i = src_ip[23:16];data_count = data_count + 1;
        14  : tx_mac_data_i = src_ip[15:8];data_count = data_count + 1;
        15  : tx_mac_data_i = src_ip[7:0];data_count = data_count + 1;
        // 目的地址
        16  : tx_mac_data_i = dst_ip[31:24];data_count = data_count + 1;
        17  : tx_mac_data_i = dst_ip[23:16];data_count = data_count + 1;
        18  : tx_mac_data_i = dst_ip[15:8];data_count = data_count + 1;
        19  : tx_mac_data_i = dst_ip[7:0];data_count = data_count + 1;
        // 源端口
        20  : tx_mac_data_i = src_port[15:8];data_count = data_count + 1;
        21  : tx_mac_data_i = src_port[7:4];data_count = data_count + 1;
        // 目的端口
        22  : tx_mac_data_i = dst_port[15:8];data_count = data_count + 1;
        23  : tx_mac_data_i = dst_port[7:0];data_count = data_count + 1;
        // UDP数据报总长度
        24  : tx_mac_data_i = udp_total_len[15:8];data_count = data_count + 1;
        25  : tx_mac_data_i = udp_total_len[7:0];data_count = data_count + 1;
        // UDP报头校验和
        26  : tx_mac_data_i = udp_checksum[15:8];data_count = data_count + 1;
        27  : tx_mac_data_i = udp_checksum[7:0];data_count = data_count + 1;
        28  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        29  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        30  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        31  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        32  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        33  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        34  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        35  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        36  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        37  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        38  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        39  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        40  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        41  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        42  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        43  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        44  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        45  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        46  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        47  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        48  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        49  : tx_mac_last_i = 8'10101010;data_count = data_count + 1;
        50  : tx_mac_last_i = 8'10101010;tx_mac_last = 1;
        // default  : tx_mac_data_i = ;data_count = data_count + 1;
    end
 
 endmodule 