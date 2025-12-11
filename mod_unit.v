`timescale 1ns / 1ps
// modular addition: 1-stage pipeline
module mod_add #(parameter Q = 23'd8380417,parameter WIDTH = 'd23)(
	input              clk,
	input  [WIDTH-1:0] ina,
	input  [WIDTH-1:0] inb,
	output [WIDTH-1:0] out
);
    reg  [WIDTH  :0] add_res;
    wire [WIDTH  :0] temp;
	always@(posedge clk) begin
		add_res <= ina + inb;
	end
	assign temp = add_res - Q;
	assign out = temp[WIDTH] ? add_res : temp[22:0];
endmodule

// modular subtraction: 1-stage pipeline
module mod_sub #(parameter Q = 23'd8380417,parameter WIDTH = 'd23)(
	input              clk,
	input  [WIDTH-1:0] ina,
	input  [WIDTH-1:0] inb,
	output [WIDTH-1:0] out
);
    reg [WIDTH:0] sub_res;
    reg [WIDTH-1:0] temp;
	always@(posedge clk) begin
		sub_res <= ina - inb;
	end
	assign out = sub_res[WIDTH] ? sub_res + Q : sub_res;
endmodule

// x/4 unit design combinational logic (here, the/N operation is decomposed into each layer, and dividing each layer by 4 and 4 layers accumulates to divide by 256)
module x_4 #(parameter Q = 23'd8380417,parameter WIDTH = 'd23)(
	input  [WIDTH-1:0] ina,
	output [WIDTH-1:0] out
);
    wire [WIDTH-1:0] temp;
	assign temp =  ina[0] ? {1'd0,( ina >> 1) + ((Q + 1) >> 1)} : {1'd0, ina >>1};
	assign out  = temp[0] ? {1'd0,(temp >> 1) + ((Q + 1) >> 1)} : {1'd0,temp >>1};
endmodule

// modular multiplication: 5-stage pipeline
module mod_mult#(parameter Q = 23'd8380417,parameter WIDTH = 'd23)(
	input              clk,
	input  [WIDTH-1:0] ina,
	input  [WIDTH-1:0] inb,  
	output [WIDTH-1:0] out    
);
	wire a,b;
	wire [WIDTH:0] c;
  	(* keep = "true" *) reg [45:0] mult_res;
  	wire [45:0] m ;

	// multiplication operation
	mult_stage mult_stage(clk,ina,inb,m);
	always@(posedge clk) begin
		mult_res <= m ;					
	end

	// Barrett reduction 
	Barrett REDUCER1(clk,0,a,1,mult_res,1,b,out,c);
endmodule

/* In order to further improve the critical path, partial product parallel computing is adopted to implement 22 × 22 bit multiplication. 
   This method decomposes multiplication operations into multiple partial products, and uses parallel computing to simultaneously process 
   these partial products, ultimately accumulating them to obtain the final result */

module mult_stage(
    input               clk  ,
    input      [22:0]   mult0,
    input      [22:0]   mult1,
    output     [45:0]   data_o
);
    wire [13:0] mult1_0 = mult1[13: 0];       // Low 14 bits
    wire [ 8:0] mult1_1 = mult1[22:14];       // high 9 bits
    wire [32:0] add_res0 ;
    reg  [36:0] mult_res0;
    reg  [31:0] mult_res1;

    always@(posedge clk) begin
        (* keep = "true" *) mult_res0 <= mult1_0 * mult0;    // 37
        (* keep = "true" *) mult_res1 <= mult1_1 * mult0;    // 32 
    end

    assign add_res0 = mult_res0[36:14] + mult_res1;   // Key Delay
    assign data_o = {add_res0,mult_res0[13:0]};
endmodule