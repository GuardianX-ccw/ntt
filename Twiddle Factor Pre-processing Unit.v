`timescale 1ns / 1ps
// the twiddle factor pre-processing unit
// NTT : 2-stage pipeline
// INTT: 3-stage pipeline
module twiddle_regs#(parameter WIDTH = 'd23, Q = 23'd8380417)(
   input                     ClkxCI,
   input      [2:0]          mode  ,
   input      [5:0]          pre   ,   
   input      [6*WIDTH-1:0]  In    , 
   output reg [6*WIDTH-1:0]  Out     
	);

   localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1;

   reg [WIDTH-1:0] S00xDN, S10xDN, S20xDN, S30xDN, S40xDN, S50xDN;
   reg [WIDTH-1:0] S00xDP, S10xDP, S20xDP, S30xDP, S40xDP, S50xDP;
   reg [WIDTH-1:0] S01xDN, S11xDN, S21xDN, S31xDN, S41xDN, S51xDN;
   reg [WIDTH-1:0] S01xDP, S11xDP, S21xDP, S31xDP, S41xDP, S51xDP;
   reg [WIDTH-1:0] S02xDN, S12xDN, S22xDN, S32xDN, S42xDN, S52xDN;
   reg [WIDTH-1:0] S02xDP, S12xDP, S22xDP, S32xDP, S42xDP, S52xDP;
   reg [WIDTH-1:0] S03xDN, S13xDN, S23xDN, S33xDN, S43xDN, S53xDN;
   reg [WIDTH-1:0] S03xDP, S13xDP, S23xDP, S33xDP, S43xDP, S53xDP;
  
   wire [WIDTH-1:0] x1,x2,x3,x4,x5,x6;
   x_4 #(.Q(Q),.WIDTH(WIDTH)) x_41 (S02xDP,x1); 
   x_4 #(.Q(Q),.WIDTH(WIDTH)) x_42 (S12xDP,x2);
   x_4 #(.Q(Q),.WIDTH(WIDTH)) x_43 (S22xDP,x3);
   x_4 #(.Q(Q),.WIDTH(WIDTH)) x_44 (S32xDP,x4); 
   x_4 #(.Q(Q),.WIDTH(WIDTH)) x_45 (S42xDP,x5);  
   x_4 #(.Q(Q),.WIDTH(WIDTH)) x_46 (S52xDP,x6); 

   reg [5:0] pre_r; 
   always @(*) begin
      Out = (mode == INVERSE_NTT_MODE) ? {S51xDP,S31xDP,S11xDP,S21xDP,S01xDP,S41xDP} : {S52xDP,S42xDP,S32xDP,S22xDP,S12xDP,S02xDP};   

      S03xDN = In[  WIDTH-1 :       0];
      S13xDN = In[2*WIDTH-1 :   WIDTH];
      S23xDN = In[3*WIDTH-1 : 2*WIDTH];
      S33xDN = In[4*WIDTH-1 : 3*WIDTH];
      S43xDN = In[5*WIDTH-1 : 4*WIDTH];
      S53xDN = In[6*WIDTH-1 : 5*WIDTH];

      S02xDN = pre_r[0] ? Q - S03xDP : S03xDP;
      S12xDN = pre_r[1] ? Q - S13xDP : S13xDP;
      S22xDN = pre_r[2] ? Q - S23xDP : S23xDP;
      S32xDN = pre_r[3] ? Q - S33xDP : S33xDP;
      S42xDN = pre_r[4] ? Q - S43xDP : S43xDP;
      S52xDN = pre_r[5] ? Q - S53xDP : S53xDP;

      S01xDN = (mode == INVERSE_NTT_MODE) ? x1 : S02xDP;
      S11xDN = (mode == INVERSE_NTT_MODE) ? x2 : S12xDP;
      S21xDN = (mode == INVERSE_NTT_MODE) ? x3 : S22xDP;
      S31xDN = (mode == INVERSE_NTT_MODE) ? x4 : S32xDP;
      S41xDN = (mode == INVERSE_NTT_MODE) ? x5 : S42xDP;
      S51xDN = (mode == INVERSE_NTT_MODE) ? x6 : S52xDP;

      S00xDN = S01xDP;
      S10xDN = S11xDP;
      S20xDN = S21xDP;
      S30xDN = S31xDP;
      S40xDN = S41xDP;
      S50xDN = S51xDP;
   end

   always @(posedge ClkxCI) begin
         pre_r <= pre; 
         S00xDP <= S00xDN; S10xDP <= S10xDN; S20xDP <= S20xDN; S30xDP <= S30xDN; S40xDP <= S40xDN; S50xDP <= S50xDN;
         S01xDP <= S01xDN; S11xDP <= S11xDN; S21xDP <= S21xDN; S31xDP <= S31xDN; S41xDP <= S41xDN; S51xDP <= S51xDN;
         S02xDP <= S02xDN; S12xDP <= S12xDN; S22xDP <= S22xDN; S32xDP <= S32xDN; S42xDP <= S42xDN; S52xDP <= S52xDN;
         S03xDP <= S03xDN; S13xDP <= S13xDN; S23xDP <= S23xDN; S33xDP <= S33xDN; S43xDP <= S43xDN; S53xDP <= S53xDN;     
   end
endmodule