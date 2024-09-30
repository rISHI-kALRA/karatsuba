`timescale 1ns/1ps
`include "practice.v"

module tb_combinational_karatsuba;

parameter N = 16;

// declare your signals as reg or wire
reg[N-1:0] a , b;
wire[2*N-1:0] D;
reg[2*N-1:0] c;
wire bout;

initial begin

// write the stimuli conditions
repeat(10) begin
    a = $random;
    b = $random;
    c = a*b;
    #1;
    $display("X=%b , Y=%b , Z=%b , c=%b" , a , b , D , c);
    if(c == D) begin
      $display("SAX");
    end else begin
      $display("hug diya");
    end
end

end

// Nbit_subtractor #(N) u(.a(a) , .b(b) , .S(D) , .bout(bout));
karatsuba_16 #(N) dut (.a(a), .b(b), .S(D));

initial begin
    $dumpfile("combinational_karatsuba.vcd");
    $dumpvars(0, tb_combinational_karatsuba);
end

endmodule
