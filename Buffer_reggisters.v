`timescale 1ns / 1ps
// buffer registers
module cofe_regs#(parameter WIDTH = 'd32, Q = 23'd8380417)(
   input                     clk,
   input                     en ,
   input      [4*WIDTH-1:0]  In ,  
   output reg [4*WIDTH-1:0]  Out   
	);

   reg [WIDTH-1:0] S00xDN, S10xDN, S20xDN, S30xDN;
   reg [WIDTH-1:0] S00xDP, S10xDP, S20xDP, S30xDP;
   reg [WIDTH-1:0] S01xDN, S11xDN, S21xDN, S31xDN;
   reg [WIDTH-1:0] S01xDP, S11xDP, S21xDP, S31xDP;
   reg [WIDTH-1:0] S02xDN, S12xDN, S22xDN, S32xDN;
   reg [WIDTH-1:0] S02xDP, S12xDP, S22xDP, S32xDP;
   reg [WIDTH-1:0] S03xDN, S13xDN, S23xDN, S33xDN;
   reg [WIDTH-1:0] S03xDP, S13xDP, S23xDP, S33xDP;

   always @(*) begin
      Out = en ? {S00xDP,S20xDP,S10xDP,S30xDP} : {S00xDP,S02xDP,S01xDP,S03xDP};

      if(en) begin
         S00xDN = S01xDP;
         S01xDN = S02xDP;
         S02xDN = S03xDP;
         S03xDN = In[WIDTH-1:0];
         S10xDN = S11xDP;
         S11xDN = S12xDP;
         S12xDN = S13xDP;
         S13xDN = In[2*WIDTH-1:WIDTH];
         S20xDN = S21xDP;
         S21xDN = S22xDP;
         S22xDN = S23xDP;
         S23xDN = In[3*WIDTH-1:2*WIDTH];
         S30xDN = S31xDP;
         S31xDN = S32xDP;
         S32xDN = S33xDP;
         S33xDN = In[4*WIDTH-1:3*WIDTH];
      end else begin
         S00xDN = S10xDP;
         S01xDN = S11xDP;
         S02xDN = S12xDP;
         S03xDN = S13xDP;
         S10xDN = S20xDP;
         S11xDN = S21xDP;
         S12xDN = S22xDP;
         S13xDN = S23xDP;
         S20xDN = S30xDP;
         S21xDN = S31xDP;
         S22xDN = S32xDP;
         S23xDN = S33xDP;
         S30xDN = In[  WIDTH-1:      0];
         S31xDN = In[2*WIDTH-1:  WIDTH];
         S32xDN = In[3*WIDTH-1:2*WIDTH];
         S33xDN = In[4*WIDTH-1:3*WIDTH];
      end
   end

   always @(posedge clk) begin
         S00xDP <= S00xDN; S10xDP <= S10xDN; S20xDP <= S20xDN; S30xDP <= S30xDN;
         S01xDP <= S01xDN; S11xDP <= S11xDN; S21xDP <= S21xDN; S31xDP <= S31xDN;
         S02xDP <= S02xDN; S12xDP <= S12xDN; S22xDP <= S22xDN; S32xDP <= S32xDN;
         S03xDP <= S03xDN; S13xDP <= S13xDN; S23xDP <= S23xDN; S33xDP <= S33xDN;  
   end

endmodule