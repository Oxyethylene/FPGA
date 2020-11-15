module distance_top(
   input  clk_50m,
   input  rst,
   input  trig,
   output echo,
   output led
);


PosCounter PosCounter(
        .rst(rst),
        .echo(echo),
        .Led(Led),
        .clk_50m(clk_50m)
);


Trig1Signal Trig1Signal (
      .clk_50m(clk_50m),
      .rst (rst),
      .trig1(trig)
);

endmodule