module half_adder(a, b, S, cout);
    input a , b;
    output S , cout;
    assign S = (a^b);
    assign cout = (a&b);
endmodule


module full_adder(a, b, cin, S, cout);
    input a , b , cin;
    output S , cout;
    wire S1 , cout1;
    half_adder init(.a(a) , .b(b) , .S(S1) , .cout(cout1));
    assign cout = (cout1|(S1&cin));
    assign S = (S1^cin);
endmodule


module rca_Nbit #(parameter N = 32) (a, b, cin, S, cout);
    input[N-1:0] a;
    input[N-1:0] b;
    input cin;
    output[N-1:0] S;
    output cout;
    wire[N-1:0] SS;
    wire[N-1:0] carries;
    full_adder init(.a(a[0]) , .b(b[0]) , .cin(cin) , .S(SS[0]) , .cout(carries[0]));
    generate
        genvar i;
        for(i = 1 ; i < N ; i = i + 1) begin
            full_adder andi(.a(a[i]) , .b(b[i]) , .cin(carries[i-1]) , .S(SS[i]) , .cout(carries[i]));
            // assign carries1 = carries2;
        end
    endgenerate
    assign S = SS;
    assign cout = carries[N-1];
endmodule


module Nbit_subtractor #(parameter N = 32) (
    input [N-1:0] a , b,
    output [N-1:0] D,
    output bout
);
wire [N-1:0] bb;
assign bb = ~b;
rca_Nbit #(N) u(.a(a) , .b(bb) , .cin(1'b1) , .S(D) , .cout(bout));

endmodule

module karatsuba_2 (a , b , S
);
    input[1:0] a , b;
    output [3:0] S;
    assign S[0] = a[0]&b[0];
    wire c;
    half_adder u(.a(a[0]&b[1]) , .b(a[1]&b[0]) , .S(S[1]) , .cout(c));
    assign S[2] = c^(a[1]&b[1]);
    assign S[3] = c&a[1]&b[1];
endmodule

module karatsuba_4 (a , b , S
);
    input [3:0] a , b;
    output [7:0] S;
    wire [7:0] S1 , S2 , S3 , S4 , S5 , S6;
    karatsuba_2 u(.a(a[3:2]) , .b(b[3:2]) , .S(S1[7:4]));
    karatsuba_2 v(.a(a[1:0]) , .b(b[1:0]) , .S(S1[3:0]));
    wire [1:0] top , bot;
    wire c1 , c2 , c3;
    rca_Nbit #(2) w(.a(a[3:2]) , .b(a[1:0]) , .cin(1'b0) , .S(bot) , .cout(c1));
    rca_Nbit #(2) aa(.a(b[3:2]) , .b(b[1:0]) , .cin(1'b0) , .S(top) , .cout(c2));
    assign c3 = c1&c2;
    rca_Nbit #(8) bb(.a((c1 ? {2'b0 , top , 4'b0} : 8'b0)) , .b(S1) , .cin(1'b0) , .S(S2) , .cout());
    rca_Nbit #(8) cc(.a((c2 ? {2'b0 , bot , 4'b0} : 8'b0)) , .b(S2) , .cin(1'b0) , .S(S3) , .cout());
    wire [3:0] x;
    karatsuba_2 ee(.a(top) , .b(bot) , .S(x));
    rca_Nbit #(8) dd(.a({2'b0 , x , 2'b0}) , .b(S3) , .cin(1'b0) , .S(S4) , .cout());
    rca_Nbit #(8) eee(.a({1'b0 , c3 , 6'b0}) , .b(S4) , .cin(1'b0) , .S(S5) , .cout());
    Nbit_subtractor #(8) ff(.a(S5) , .b({2'b0 , S1[7:4] , 2'b0}) , .D(S6) , .bout());
    Nbit_subtractor #(8) gg(.a(S6) , .b({2'b0 , S1[3:0] , 2'b0}) , .D(S) , .bout());
endmodule

module karatsuba_8 (a , b , S
);
    input [7:0] a , b;
    output [15:0] S;
    wire [15:0] S1 , S2 , S3 , S4 , S5 , S6;
    karatsuba_4 u(.a(a[7:4]) , .b(b[7:4]) , .S(S1[15:8]));
    karatsuba_4 v(.a(a[3:0]) , .b(b[3:0]) , .S(S1[7:0]));
    wire [3:0] top , bot;
    wire c1 , c2 , c3 , c4;
    rca_Nbit #(4) aa(.a(a[3:0]) , .b(a[7:4]) , .cin(1'b0) , .S(bot) , .cout(c1));
    rca_Nbit #(4) bbb(.a(b[3:0]) , .b(b[7:4]) , .cin(1'b0) , .S(top) , .cout(c2));
    assign c3 = c1&c2;
    rca_Nbit #(16) ccc(.a((c1 ? {4'b0 , top , 8'b0} : 16'b0)) , .b(S1) , .cin(1'b0) , .S(S2) , .cout());
    rca_Nbit #(16) ddd(.a((c2 ? {4'b0 , bot , 8'b0} : 16'b0)) , .b(S2) , .cin(1'b0) , .S(S3) , .cout());
    wire [7:0] x;
    karatsuba_4 w(.a(top) , .b(bot) , .S(x));
    rca_Nbit #(16) eee(.a({4'b0 , x , 4'b0}) , .b(S3) , .cin(1'b0) , .S(S4) , .cout());
    rca_Nbit #(16) ee(.a({3'b0 , c3 , 12'b0}) , .b(S4) , .cin(1'b0) , .S(S5) , .cout());
    Nbit_subtractor #(16) ff(.a(S5) , .b({4'b0 , S1[15:8] , 4'b0}) , .D(S6) , .bout());
    Nbit_subtractor #(16) gg(.a(S6) , .b({4'b0 , S1[7:0] , 4'b0}) , .D(S) , .bout());
endmodule

module karatsuba_16 (a , b , S
);
    input [15:0] a , b;
    output [31:0] S;
    wire [31:0] S1 , S2 , S3 , S4 , S5 , S6;
    karatsuba_8 u(.a(a[15:8]) , .b(b[15:8]) , .S(S1[31:16]));
    karatsuba_8 v(.a(a[7:0]) , .b(b[7:0]) , .S(S1[15:0]));
    wire [7:0] top , bot;
    wire c1 , c2 , c3 , c4;
    rca_Nbit #(8) aaa(.a(a[7:0]) , .b(a[15:8]) , .cin(1'b0) , .S(bot) , .cout(c1));
    rca_Nbit #(8) bbb(.a(b[7:0]) , .b(b[15:8]) , .cin(1'b0) , .S(top) , .cout(c2));
    assign c3 = c1&c2;
    rca_Nbit #(32) ccc(.a((c1 ? {8'b0 , top , 16'b0} : 32'b0)) , .b(S1) , .cin(1'b0) , .S(S2) , .cout());
    rca_Nbit #(32) ddd(.a((c2 ? {8'b0 , bot , 16'b0} : 32'b0)) , .b(S2) , .cin(1'b0) , .S(S3) , .cout());
    wire [15:0] x;
    karatsuba_8 w(.a(top) , .b(bot) , .S(x));
    rca_Nbit #(32) eee(.a({8'b0 , x , 8'b0}) , .b(S3) , .cin(1'b0) , .S(S4) , .cout());
    rca_Nbit #(32) ee(.a({7'b0 , c3 , 24'b0}) , .b(S4) , .cin(1'b0) , .S(S5) , .cout());
    Nbit_subtractor #(32) ff(.a(S5) , .b({8'b0 , S1[31:16] , 8'b0}) , .D(S6) , .bout());
    Nbit_subtractor #(32) gg(.a(S6) , .b({8'b0 , S1[15:0] , 8'b0}) , .D(S) , .bout());
endmodule