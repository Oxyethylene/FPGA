`timescale 1ns/1ps

`define UD #1

module green_led_light(
    input clk,      // 时钟频率50MHz
    input rstn,     // 使能信号判断是否常亮  

    output green_led    // 输出的led信号
);


    reg [ 1:0] green_led_status=1'b0;
 always @(posedge clk)
begin
    if(!rstn)
     green_led_status<=1'b0;
    else 
     green_led_status<=1'b1;
end

    assign green_led = green_led_status;

endmodule