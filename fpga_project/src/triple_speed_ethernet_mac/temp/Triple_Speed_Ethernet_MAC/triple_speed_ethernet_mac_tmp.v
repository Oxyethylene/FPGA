//Copyright (C)2014-2020 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: GowinSynthesis V1.9.7Beta
//Part Number: GW2A-LV18PG484C8/I7
//Device: GW2A-18
//Created Time: Sat Nov 14 15:46:24 2020

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	Triple_Speed_Ethernet_MAC_Top your_instance_name(
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
		.duplex_status(duplex_status_i), //input duplex_status
		.rstn(rstn_i), //input rstn
		.rx_mac_clk(rx_mac_clk_o), //output rx_mac_clk
		.rx_mac_valid(rx_mac_valid_o), //output rx_mac_valid
		.rx_mac_data(rx_mac_data_o), //output [7:0] rx_mac_data
		.rx_mac_last(rx_mac_last_o), //output rx_mac_last
		.rx_mac_error(rx_mac_error_o), //output rx_mac_error
		.rx_statistics_valid(rx_statistics_valid_o), //output rx_statistics_valid
		.rx_statistics_vector(rx_statistics_vector_o), //output [26:0] rx_statistics_vector
		.tx_mac_clk(tx_mac_clk_o), //output tx_mac_clk
		.tx_mac_valid(tx_mac_valid_i), //input tx_mac_valid
		.tx_mac_data(tx_mac_data_i), //input [7:0] tx_mac_data
		.tx_mac_last(tx_mac_last_i), //input tx_mac_last
		.tx_mac_error(tx_mac_error_i), //input tx_mac_error
		.tx_mac_ready(tx_mac_ready_o), //output tx_mac_ready
		.tx_collision(tx_collision_o), //output tx_collision
		.tx_retransmit(tx_retransmit_o), //output tx_retransmit
		.tx_statistics_valid(tx_statistics_valid_o), //output tx_statistics_valid
		.tx_statistics_vector(tx_statistics_vector_o), //output [28:0] tx_statistics_vector
		.rx_fcs_fwd_ena(rx_fcs_fwd_ena_i), //input rx_fcs_fwd_ena
		.rx_jumbo_ena(rx_jumbo_ena_i), //input rx_jumbo_ena
		.rx_pause_req(rx_pause_req_o), //output rx_pause_req
		.rx_pause_val(rx_pause_val_o), //output [15:0] rx_pause_val
		.tx_fcs_fwd_ena(tx_fcs_fwd_ena_i), //input tx_fcs_fwd_ena
		.tx_ifg_delay_ena(tx_ifg_delay_ena_i), //input tx_ifg_delay_ena
		.tx_ifg_delay(tx_ifg_delay_i), //input [7:0] tx_ifg_delay
		.tx_pause_req(tx_pause_req_i), //input tx_pause_req
		.tx_pause_val(tx_pause_val_i), //input [15:0] tx_pause_val
		.tx_pause_source_addr(tx_pause_source_addr_i), //input [47:0] tx_pause_source_addr
		.clk(clk_i), //input clk
		.miim_phyad(miim_phyad_i), //input [4:0] miim_phyad
		.miim_regad(miim_regad_i), //input [4:0] miim_regad
		.miim_wrdata(miim_wrdata_i), //input [15:0] miim_wrdata
		.miim_wren(miim_wren_i), //input miim_wren
		.miim_rden(miim_rden_i), //input miim_rden
		.miim_rddata(miim_rddata_o), //output [15:0] miim_rddata
		.miim_rddata_valid(miim_rddata_valid_o), //output miim_rddata_valid
		.miim_busy(miim_busy_o), //output miim_busy
		.mdc(mdc_o), //output mdc
		.mdio_in(mdio_in_i), //input mdio_in
		.mdio_out(mdio_out_o), //output mdio_out
		.mdio_oen(mdio_oen_o) //output mdio_oen
	);

//--------Copy end-------------------
