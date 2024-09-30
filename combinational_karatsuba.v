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


module karatsuba_2 (
    input [1:0] X , Y,
    output [3:0] Z
);
assign Z[0] = X[0]&Y[0];
assign Z[1] = (X[1]&Y[0])^(X[0]&Y[1]);
assign Z[2] = (X[1]&Y[0]&X[0]&Y[1])^(X[1]&Y[1]);
assign Z[3] = X[1]&Y[0]&X[0]&Y[1];
    
endmodule


module karatsuba_4(
    input[3:0] X , Y,
    output[7:0] Z
);
wire[7:0] A , B , C , ZZ;
wire cx , cy;
generate
    genvar i;
    for(i = 0 ; i < 4 ; i = i+1) begin
      assign A[i] = 1'b0;
      assign B[i] = 1'b0;
    end
    assign C[0] = 1'b0;
    assign C[1] = 1'b0;
    assign C[7] = 1'b0;
    for(i = 6 ; i < 8 ; i = i+1) begin
      assign A[i] = 1'b0;
      assign B[i] = 1'b0;
    end
endgenerate
karatsuba_2 u1(.X(X[3:2]) , .Y(Y[3:2]) , .Z(ZZ[7:4]));
karatsuba_2 u2(.X(X[1:0]) , .Y(Y[1:0]) , .Z(ZZ[3:0]));
rca_Nbit #(2) u3(.a(X[3:2]) , .b(X[1:0]) , .cin(1'b0) , .S(A[5:4]) , .cout(cx));
rca_Nbit #(2) u4(.a(Y[3:2]) , .b(Y[1:0]) , .cin(1'b0) , .S(B[5:4]) , .cout(cy));
karatsuba_2 u5(.X(A[5:4]) , .Y(B[5:4]) , .Z(C[5:2]));
assign C[6] = cx&cy;
wire[7:0] AA , BB , C1 , C2 , C3 , C4;
generate
    for(i = 0 ; i < 8 ; i = i+1) begin
      assign AA[i] = A[i]&cy;
      assign BB[i] = B[i]&cx;
    end
endgenerate
rca_Nbit #(8) u6(.a(AA) , .b(C) , .cin(1'b0) , .S(C1) , .cout());
rca_Nbit #(8) u7(.a(BB) , .b(C1) , .cin(1'b0) , .S(C2) , .cout());
Nbit_subtractor #(8) u8(.a(C2) , .b({2'b0 , ZZ[7:4] , 2'b0}) , .D(C3) , .bout());
Nbit_subtractor #(8) u9(.a(C3) , .b({2'b0 , ZZ[3:0] , 2'b0}) , .D(C4) , .bout());
rca_Nbit #(8) u10(.a(C4) , .b(ZZ) , .cin(1'b0) , .S(Z) , .cout());

endmodule


module karatsuba_8(input[7:0] X , Y , output [15:0] Z);
wire [15:0] A , B , C , ZZ;
wire cx , cy;
generate
    genvar i;
    for(i = 0 ; i < 8 ; i = i+1) begin
      assign A[i] = 1'b0;
      assign B[i] = 1'b0;
    end
    assign C[0] = 1'b0;
    assign C[1] = 1'b0;
    assign C[2] = 1'b0;
    assign C[3] = 1'b0;
    assign C[13] = 1'b0;
    assign C[14] = 1'b0;
    assign C[15] = 1'b0;
    for(i = 12 ; i < 16 ; i = i+1) begin
      assign A[i] = 1'b0;
      assign B[i] = 1'b0;
    end
endgenerate
karatsuba_4 u1(.X(X[7:4]) , .Y(Y[7:4]) , .Z(ZZ[15:8]));
karatsuba_4 u2(.X(X[3:0]) , .Y(Y[3:0]) , .Z(ZZ[7:0]));
rca_Nbit #(4) u3(.a(X[7:4]) , .b(X[3:0]) , .cin(1'b0) , .S(A[11:8]) , .cout(cx));
rca_Nbit #(4) u4(.a(Y[7:4]) , .b(Y[3:0]) , .cin(1'b0) , .S(B[11:8]) , .cout(cy));
karatsuba_4 u5(.X(A[11:8]) , .Y(B[11:8]) , .Z(C[11:4]));
assign C[12] = cx&cy;
wire[15:0] AA , BB , C1 , C2 , C3 , C4;
generate
    for(i = 0 ; i < 16 ; i = i+1) begin
      assign AA[i] = A[i]&cy;
      assign BB[i] = B[i]&cx;
    end
endgenerate
rca_Nbit #(16) u6(.a(AA) , .b(C) , .cin(1'b0) , .S(C1) , .cout());
rca_Nbit #(16) u7(.a(BB) , .b(C1) , .cin(1'b0) , .S(C2) , .cout());
Nbit_subtractor #(16) u8(.a(C2) , .b({4'b0 , ZZ[15:8] , 4'b0}) , .D(C3) , .bout());
Nbit_subtractor #(16) u9(.a(C3) , .b({4'b0 , ZZ[7:0] , 4'b0}) , .D(C4) , .bout());
rca_Nbit #(16) u10(.a(C4) , .b(ZZ) , .cin(1'b0) , .S(Z) , .cout());

endmodule


module karatsuba_16 (X, Y, Z);
input [15:0] X , Y;
output [31:0] Z;
wire [31:0] A , B , C , ZZ;
wire cx , cy;
generate
    genvar i;
    for(i = 0 ; i < 16 ; i = i+1) begin
      assign A[i] = 1'b0;
      assign B[i] = 1'b0;
    end
    assign C[0] = 1'b0;
    assign C[1] = 1'b0;
    assign C[2] = 1'b0;
    assign C[3] = 1'b0;
    assign C[4] = 1'b0;
    assign C[5] = 1'b0;
    assign C[6] = 1'b0;
    assign C[7] = 1'b0;
    assign C[25] = 1'b0;
    assign C[26] = 1'b0;
    assign C[27] = 1'b0;
    assign C[28] = 1'b0;
    assign C[29] = 1'b0;
    assign C[30] = 1'b0;
    assign C[31] = 1'b0;
    for(i = 24 ; i < 32 ; i = i+1) begin
      assign A[i] = 1'b0;
      assign B[i] = 1'b0;
    end
endgenerate
karatsuba_8 u1(.X(X[15:8]) , .Y(Y[15:8]) , .Z(ZZ[31:16]));
karatsuba_8 u2(.X(X[7:0]) , .Y(Y[7:0]) , .Z(ZZ[15:0]));
rca_Nbit #(8) u3(.a(X[15:8]) , .b(X[7:0]) , .cin(1'b0) , .S(A[23:16]) , .cout(cx));
rca_Nbit #(8) u4(.a(Y[15:8]) , .b(Y[7:0]) , .cin(1'b0) , .S(B[23:16]) , .cout(cy));
karatsuba_8 u5(.X(A[23:16]) , .Y(B[23:16]) , .Z(C[23:8]));
assign C[24] = cx&cy;
wire[31:0] AA , BB , C1 , C2 , C3 , C4;
generate
    for(i = 0 ; i < 32 ; i = i+1) begin
      assign AA[i] = A[i]&cy;
      assign BB[i] = B[i]&cx;
    end
endgenerate
rca_Nbit #(32) u6(.a(AA) , .b(C) , .cin(1'b0) , .S(C1) , .cout());
rca_Nbit #(32) u7(.a(BB) , .b(C1) , .cin(1'b0) , .S(C2) , .cout());
Nbit_subtractor #(32) u8(.a(C2) , .b({8'b0 , ZZ[31:16] , 8'b0}) , .D(C3) , .bout());
Nbit_subtractor #(32) u9(.a(C3) , .b({8'b0 , ZZ[15:0] , 8'b0}) , .D(C4) , .bout());
rca_Nbit #(32) u10(.a(C4) , .b(ZZ) , .cin(1'b0) , .S(Z) , .cout());

initial begin
    $dumpfile("combinational_karatsuba.vcd");
    $dumpvars(0, karatsuba_16);
end

endmodule

module tb_combinational_karatsuba;

parameter N = 2;

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
karatsuba_2 #(N) dut (.X(a), .Y(b), .Z(D));

endmodule
