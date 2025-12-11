`timescale 1ns / 1ps

// Top layer of BF4 unit
// 7-stage pipeline

module butterfly2x2_csa#(parameter WIDTH = 'd23, Q = 23'd8380417)(
    input                           clk   ,
    input                           rst   ,
    input  [2:0]                    mode  ,         
    input                           validi,    
    input  [WIDTH*4-1    :0]        datai , 
    input  [WIDTH*6-1    :0]        zetai , 
    output reg [(WIDTH+1)*4-1:0]    data_o,
    output reg                      valido
); 
    localparam
        FORWARD_NTT_MODE = 3'd0,    
        INVERSE_NTT_MODE = 3'd1; 

    reg  [  WIDTH-1:0] mult_a0=0,mult_a1=0,mult_a2=0,mult_a3=0,mult_a4=0,mult_a5=0; 
    reg  [  WIDTH-1:0] mult_b0=0,mult_b1=0,mult_b2=0,mult_b3=0,mult_b4=0,mult_b5=0; 
    wire [  WIDTH-1:0] mult_res0,mult_res1,mult_res2,mult_res3,mult_res4,mult_res5; 

    reg  [  WIDTH-1:0] add_a1=0,add_a2=0,add_a3=0,add_a4=0; 
    reg  [  WIDTH-1:0] add_b1=0,add_b2=0,add_b3=0,add_b4=0; 
    wire [  WIDTH-1:0] add_res1,add_res2,add_res3,add_res4; 

    reg  [  WIDTH-1:0] sub_a1=0,sub_a2=0,sub_a3=0,sub_a4=0;
    reg  [  WIDTH-1:0] sub_b1=0,sub_b2=0,sub_b3=0,sub_b4=0; 
    wire [  WIDTH-1:0] sub_res1,sub_res2,sub_res3,sub_res4; 

    // Data allocation
    always @(*) begin
        case(mode)
            FORWARD_NTT_MODE: begin
                valido = cnt[6];
                mult_a0 = datai[4*WIDTH-1:3*WIDTH]; mult_b0 = zetai[6*WIDTH-1:5*WIDTH];
                mult_a1 = datai[3*WIDTH-1:2*WIDTH]; mult_b1 = zetai[5*WIDTH-1:4*WIDTH];
                mult_a2 = datai[2*WIDTH-1:  WIDTH]; mult_b2 = zetai[4*WIDTH-1:3*WIDTH];
                mult_a3 = datai[2*WIDTH-1:  WIDTH]; mult_b3 = zetai[3*WIDTH-1:2*WIDTH];
                mult_a4 = datai[  WIDTH-1:      0]; mult_b4 = zetai[2*WIDTH-1:  WIDTH];
                mult_a5 = datai[  WIDTH-1:      0]; mult_b5 = zetai[  WIDTH-1:      0];

                add_a1 = mult_res0 ; add_b1 = mult_res1;
                add_a2 = mult_res2 ; add_b2 = mult_res4;
                add_a3 = add_res1  ; add_b3 = add_res2 ;
                add_a4 = sub_res1  ; add_b4 = sub_res2 ;

                sub_a1 = mult_res0 ; sub_b1 = mult_res1;
                sub_a2 = mult_res3 ; sub_b2 = mult_res5;
                sub_a3 = add_res1  ; sub_b3 = add_res2 ;
                sub_a4 = sub_res1  ; sub_b4 = sub_res2 ;

                data_o = {1'b0,sub_res4,1'b0,add_res4,1'b0,sub_res3,1'b0,add_res3};
            end
            INVERSE_NTT_MODE: begin
                valido = cnt[6];
                mult_a0 = add_res3; mult_b0 = tw1_fifo0;     
                mult_a1 = sub_res1; mult_b1 = zetai_1[5*WIDTH-1:4*WIDTH];
                mult_a2 = sub_res1; mult_b2 = zetai_1[4*WIDTH-1:3*WIDTH];
                mult_a3 = sub_res3; mult_b3 = tw1_fifo1; 
                mult_a4 = sub_res2; mult_b4 = zetai_1[3*WIDTH-1:2*WIDTH];
                mult_a5 = sub_res2; mult_b5 = zetai_1[2*WIDTH-1:  WIDTH];
                
                add_a1 = datai[4*WIDTH-1:3*WIDTH]; add_b1 = datai[3*WIDTH-1:2*WIDTH];
                add_a2 = datai[2*WIDTH-1:  WIDTH]; add_b2 = datai[  WIDTH-1:      0];
                add_a3 = add_res1  ; add_b3 = add_res2  ;
                add_a4 = mult_res1 ; add_b4 = mult_res4 ;

                sub_a1 = datai[4*WIDTH-1:3*WIDTH]; sub_b1 = datai[3*WIDTH-1:2*WIDTH];
                sub_a2 = datai[2*WIDTH-1:  WIDTH]; sub_b2 = datai[  WIDTH-1:      0];
                sub_a3 = add_res1  ; sub_b3  = add_res2 ;
                sub_a4 = mult_res2 ; sub_b4 = mult_res5 ;

                data_o = {1'b0,add_res4,1'b0,mult_res0,1'b0,sub_res4,1'b0,mult_res3};
            end
            default: begin  
            valido=0;mult_a0=0;mult_b0=0;mult_a1=0;mult_b1=0;mult_a2=0;mult_b2=0;mult_a3=0;mult_b3=0;mult_a4=0;mult_b4=0;mult_a5=0;mult_b5=0;add_a1=0;
            add_b1=0;add_a2 =0;add_b2 =0;add_a3 =0;add_b3 =0;add_a4 =0;add_b4 =0;sub_a1 =0;sub_b1 =0;sub_a2 =0;sub_b2 =0;sub_a3 =0;sub_b3 =0;sub_a4=0;sub_b4=0;
            end
        endcase
    end 

    /***** Reuse the underlying module of modular addition, modular subtraction, and modular multiplication ******/
    mod_mult#(.Q(Q),.WIDTH(WIDTH))mod_mult0(clk,mult_a0,mult_b0,mult_res0); // 0
    mod_mult#(.Q(Q),.WIDTH(WIDTH))mod_mult1(clk,mult_a1,mult_b1,mult_res1); // 1 
    mod_mult#(.Q(Q),.WIDTH(WIDTH))mod_mult2(clk,mult_a2,mult_b2,mult_res2); // 2 
    mod_mult#(.Q(Q),.WIDTH(WIDTH))mod_mult3(clk,mult_a3,mult_b3,mult_res3); // 3
    mod_mult#(.Q(Q),.WIDTH(WIDTH))mod_mult4(clk,mult_a4,mult_b4,mult_res4); // 4 
    mod_mult#(.Q(Q),.WIDTH(WIDTH))mod_mult5(clk,mult_a5,mult_b5,mult_res5); // 5

    mod_add#(.Q(Q),.WIDTH(WIDTH))mod_add1(clk,add_a1,add_b1,add_res1); // 0 
    mod_add#(.Q(Q),.WIDTH(WIDTH))mod_add2(clk,add_a2,add_b2,add_res2); // 1 
    mod_add#(.Q(Q),.WIDTH(WIDTH))mod_add3(clk,add_a3,add_b3,add_res3); // 2 
    mod_add#(.Q(Q),.WIDTH(WIDTH))mod_add4(clk,add_a4,add_b4,add_res4); // 3

    mod_sub#(.Q(Q),.WIDTH(WIDTH))mod_sub1(clk,sub_a1,sub_b1,sub_res1); // 0
    mod_sub#(.Q(Q),.WIDTH(WIDTH))mod_sub2(clk,sub_a2,sub_b2,sub_res2); // 1 
    mod_sub#(.Q(Q),.WIDTH(WIDTH))mod_sub3(clk,sub_a3,sub_b3,sub_res3); // 2
    mod_sub#(.Q(Q),.WIDTH(WIDTH))mod_sub4(clk,sub_a4,sub_b4,sub_res4); // 3

    /*************************** Pipeline of its data ***********************************/
    reg  [WIDTH*6-1:0] zetai_1;
    reg  [       10:0] cnt    ; 
    reg  [  WIDTH-1:0] tw1_fifo0;
    reg  [  WIDTH-1:0] tw1_fifo1; 

    always @(posedge clk) begin      
        if (rst) begin
            cnt <= 'd0;
        end else begin

            cnt <= {cnt[9:0], validi};  

            tw1_fifo0 <= zetai_1[6*WIDTH-1:5*WIDTH];

            tw1_fifo1 <= zetai_1[WIDTH-1:0];

            zetai_1 <= zetai;
        end
    end

endmodule
