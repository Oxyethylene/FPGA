`timescale 1ns/1ps

`define UD #1

module red_led_light(
    input clk,      // 时钟频率，每25M闪烁一次
    input rstn,     // 使能信号判断是否执行红灯闪烁    

    output red_led    // 红灯输出
);

    reg [24:0] led_light_cnt;
    reg [ 1:0] red_led_status=1'b0;

    // 计数,每25M归零一次,旨只在rstn信号有效时从零开始计数    
    always @(posedge clk)
    begin
        if(rstn)
            led_light_cnt <= `UD 25'd0;
        else if(led_light_cnt == 25'd2499_9999)
            led_light_cnt <= `UD 25'd0;
        else 
            led_light_cnt <= `UD led_light_cnt + 25'd1;
    end

 // 根据led_light_cnt翻转red_led状态,达到闪烁效果
    always @(posedge clk)
    begin
        if(led_light_cnt == 25'd2499_9999)
            red_led_status <= `UD ~red_led_status;
         
    end

    assign red_led = red_led_status;

endmodule