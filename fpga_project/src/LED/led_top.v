module led_lighttop(
    input clk,      // 时钟频率
    input key1,     // 使能信号,低电平有效    

    output red_led,    // 输出的led信号
     output green_led    
);

green_led_light green(
    .clk(clk) ,    // 时钟频率
    .rstn(key1),     // 使能信号   

    .green_led(green_led)    
);


red_led_light red (
     .clk(clk),      // 时钟频率
     .rstn(key1),   // 使能信号   

     .red_led(red_led)    
);

endmodule
