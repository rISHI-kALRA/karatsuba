/* 32-bit simple karatsuba multiplier */

/*32-bit Karatsuba multipliction using a single 16-bit module*/

module iterative_karatsuba_32_16(clk, rst, enable, A, B, C);
    input clk;
    input rst;
    input [31:0] A;
    input [31:0] B;
    output [63:0] C;
    
    input enable;
    
    
    wire [1:0] sel_x;
    wire [1:0] sel_y;
    
    wire [1:0] sel_z;
    wire [1:0] sel_T;
    
    
    wire done;
    wire en_z;
    wire en_T;
    
    
    wire [32:0] h1;
    wire [32:0] h2;
    wire [63:0] g1;
    wire [63:0] g2;
    
    assign C = g2;
    reg_with_enable #(.N(63)) Z(.clk(clk), .rst(rst), .en(en_z), .X(g1), .O(g2) );  // Fill in the proper size of the register
    reg_with_enable #(.N(32)) T(.clk(clk), .rst(rst), .en(en_T), .X(h1), .O(h2) );  // Fill in the proper size of the register
    
    iterative_karatsuba_datapath dp(.clk(clk), .rst(rst), .X(A), .Y(B), .Z(g2), .T(h2), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done), .W1(g1), .W2(h1));
    iterative_karatsuba_control control(.clk(clk),.rst(rst), .enable(enable), .sel_x(sel_x), .sel_y(sel_y), .sel_z(sel_z), .sel_T(sel_T), .en_z(en_z), .en_T(en_T), .done(done));
    
endmodule

module iterative_karatsuba_datapath(clk, rst, X, Y, T, Z, sel_x, sel_y, en_z, sel_z, en_T, sel_T, done, W1, W2);
    input clk;
    input rst;
    input [31:0] X;    // input X
    input [31:0] Y;    // Input Y
    input [32:0] T;    // input which sums X_h*Y_h and X_l*Y_l (its also a feedback through the register)
    input [63:0] Z;    // input which calculates the final outcome (its also a feedback through the register)
    output [63:0] W1;  // Signals going to the registers as input
    output [32:0] W2;  // signals hoing to the registers as input
    

    input [1:0] sel_x;  // control signal 
    input [1:0] sel_y;  // control signal 
    
    input en_z;         // control signal 
    input [1:0] sel_z;  // control signal 
    input en_T;         // control signal 
    input [1:0] sel_T;  // control signal 
    
    input done;         // Final done signal
    
    
   
    
    //-------------------------------------------------------------------------------------------------
    wire [15:0] a , b , c , d , e , f;
    wire [31:0] g , h;
    wire [33:0] i , j , k;
    wire [33:0] ww1;
    wire cout1 , cout2 , c1 , c2;
    assign a = (sel_x == 2'b00 ? X[15:0] : X[31:16]);
    assign b = (sel_x == 2'b00 ? Y[15:0] : Y[31:16]);
    adder_Nbit #(16) u(.a(X[15:0]) , .b(X[31:16]) , .cin(1'b0) , .S(c) , .cout(cout1));
    adder_Nbit #(16) v(.a(Y[15:0]) , .b(Y[31:16]) , .cin(1'b0) , .S(d) , .cout(cout2));
    assign e = (sel_x[0] ? c : a);
    assign f = (sel_x[0] ? d : b);
    assign g = (sel_x[0] == 1'b1 && cout2 == 1'b1 ? {e , 16'b0} : 32'b0);
    assign h = (sel_x[0] == 1'b1 && cout1 == 1'b1 ? {f , 16'b0} : 32'b0);
    assign c1 = (sel_x[0] ? cout1 : 1'b0);
    assign c2 = (sel_x[0] ? cout2 : 1'b0);
    mult_16 w(.X(e) , .Y(f) , .Z(i[31:0]));
    assign i[33:32] = 2'b0;
    adder_Nbit #(34) t(.a({2'b0 , g}) , .b(i) , .cin(1'b0) , .S(j) , .cout());
    adder_Nbit #(33) s(.a({1'b0 , h}) , .b(j[32:0]) , .cin(1'b0) , .S(k[32:0]) , .cout());
    assign k[33] = (c1&c2);
    subtract_Nbit #(34) x(.a(k) , .b({1'b0 , T}) , .cin(1'b0) , .S(ww1) , .ov() , .cout_sub());
    adder_Nbit #(32) y(.a(Z[63:32]) , .b(Z[31:0]) , .cin(1'b0) , .S(W2[31:0]) , .cout(W2[32]));
    wire [63:0] final;
    assign final = (sel_x[1] ? {ww1[31:0] , 32'b0} : (sel_x[0] ? {14'b0 , ww1 , 16'b0} : {32'b0 , ww1[31:0]}));
    adder_Nbit #(64) z(.a(Z) , .b(final) , .cin(1'b0) , .S(W1) , .cout());
    // Write your datapath here
    //--------------------------------------------------------

endmodule


module iterative_karatsuba_control(clk,rst, enable, sel_x, sel_y, sel_z, sel_T, en_z, en_T, done);
    input clk;
    input rst;
    input enable;
    
    output reg [1:0] sel_x;
    output reg [1:0] sel_y;
    
    output reg [1:0] sel_z;
    output reg [1:0] sel_T;    
    
    output reg en_z;
    output reg en_T;
    
    
    output reg done;
    
    reg [5:0] state, nxt_state;
    parameter S0 = 6'b000001;   // initial state
    parameter S1 = 6'b000010;
    parameter S2 = 6'b000100;
    parameter S3 = 6'b001000;
    parameter S4 = 6'b010000;
   // <define the rest of the states here>

    always @(posedge clk) begin
        if (rst) begin
            state <= S0;
        end
        else if (enable) begin
            state <= nxt_state;
        end
    end
    

    always@(*) begin
        case(state) 
            S0: 
                begin
					// Write your output and next state equations here
                    // sel_x = 2'b0;
                    nxt_state <= S1;
                    // en_z <= 1'b1;
                    // en_T <= 1'b0;
                end
            S1:
                begin
                    sel_x <= 2'b00;
                    nxt_state <= S2;
                    en_z <= 1'b1;
                    en_T <= 1'b0;
                end
            S2:
                begin
                    sel_x <= 2'b10;
                    nxt_state <= S3;
                    en_z <= 1'b1;
                    en_T <= 1'b1;
                end
            S3:
                begin
                    sel_x <= 2'b01;
                    en_z <= 1'b1;
                    en_T <= 1'b0;
                    nxt_state <= S4;
                end
            S4:
                begin
                    en_z <= 1'b0;
                    done <= 1'b1;
                end
			// Define the rest of the states
            default: 
                begin
				// Don't forget the default
                    sel_x <= 2'b0;
                end            
        endcase
        
    end

endmodule


module reg_with_enable #(parameter N = 32) (clk, rst, en, X, O );
    input [N:0] X;
    input clk;
    input rst;
    input en;
    output [N:0] O;
    
    reg [N:0] R;
    
    always@(posedge clk) begin
        if (rst) begin
            R <= {N{1'b0}};
        end
        if (en) begin
            R <= X;
        end
    end
    assign O = R;
endmodule







/*-------------------Supporting Modules--------------------*/
/*------------- Iterative Karatsuba: 32-bit Karatsuba using a single 16-bit Module*/

module mult_16(X, Y, Z);
input [15:0] X;
input [15:0] Y;
output [31:0] Z;

assign Z = X*Y;

endmodule


module mult_17(X, Y, Z);
input [16:0] X;
input [16:0] Y;
output [33:0] Z;

assign Z = X*Y;

endmodule

module full_adder(a, b, cin, S, cout);
input a;
input b;
input cin;
output S;
output cout;

assign S = a ^ b ^ cin;
assign cout = (a&b) ^ (b&cin) ^ (a&cin);

endmodule


module check_subtract (A, B, C);
 input [7:0] A;
 input [7:0] B;
 output [8:0] C;
 
 assign C = A - B; 
endmodule



/* N-bit RCA adder (Unsigned) */
module adder_Nbit #(parameter N = 32) (a, b, cin, S, cout);
input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output cout;

wire [N:0] cr;  

assign cr[0] = cin;


generate
    genvar i;
    for (i = 0; i < N; i = i + 1) begin
        full_adder addi (.a(a[i]), .b(b[i]), .cin(cr[i]), .S(S[i]), .cout(cr[i+1]));
    end
endgenerate    


assign cout = cr[N];

endmodule


module Not_Nbit #(parameter N = 32) (a,c);
input [N-1:0] a;
output [N-1:0] c;

generate
genvar i;
for (i = 0; i < N; i = i+1) begin
    assign c[i] = ~a[i];
end
endgenerate 

endmodule


/* 2's Complement (N-bit) */
module Complement2_Nbit #(parameter N = 32) (a, c, cout_comp);

input [N-1:0] a;
output [N-1:0] c;
output cout_comp;

wire [N-1:0] b;
wire ccomp;

Not_Nbit #(.N(N)) compl(.a(a),.c(b));
adder_Nbit #(.N(N)) addc(.a(b), .b({ {N-1{1'b0}} ,1'b1 }), .cin(1'b0), .S(c), .cout(ccomp));

assign cout_comp = ccomp;

endmodule


/* N-bit Subtract (Unsigned) */
module subtract_Nbit #(parameter N = 32) (a, b, cin, S, ov, cout_sub);

input [N-1:0] a;
input [N-1:0] b;
input cin;
output [N-1:0] S;
output ov;
output cout_sub;

wire [N-1:0] minusb;
wire cout;
wire ccomp;

Complement2_Nbit #(.N(N)) compl(.a(b), .c(minusb), .cout_comp(ccomp));
adder_Nbit #(.N(N)) addc(.a(a), .b(minusb), .cin(1'b0), .S(S), .cout(cout));

assign ov = (~(a[N-1] ^ minusb[N-1])) & (a[N-1] ^ S[N-1]);
assign cout_sub = cout | ccomp;

endmodule



/* n-bit Left-shift */

module Left_barrel_Nbit #(parameter N = 32)(a, n, c);

input [N-1:0] a;
input [$clog2(N)-1:0] n;
output [N-1:0] c;


generate
genvar i;
for (i = 0; i < $clog2(N); i = i + 1 ) begin: stage
    localparam integer t = 2**i;
    wire [N-1:0] si;
    if (i == 0) 
    begin 
        assign si = n[i]? {a[N-t:0], {t{1'b0}}} : a;
    end    
    else begin 
        assign si = n[i]? {stage[i-1].si[N-t:0], {t{1'b0}}} : stage[i-1].si;
    end
end
endgenerate

assign c = stage[$clog2(N)-1].si;

endmodule



