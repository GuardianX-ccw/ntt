`timescale 1ns / 1ps
// The address resolver
module address_unit(
    input            clk        ,
    input            rst        ,
    input      [2:0] mode       ,
    input            en         ,
    // the random twiddle factor addresses from the new round 
    input      [8:0] zeta_new_1 ,  
    input      [8:0] zeta_new_2 ,  
    input      [8:0] zeta_new_3 ,  
    input      [8:0] zeta_new_4 , 
    input      [8:0] zeta_new_5 ,  
    // the random twiddle factor addresses from the previous round
    input      [8:0] zeta0_old_1,                                           
    input      [8:0] zeta1_old_2,
    input      [8:0] zeta2_old_3,
    input      [8:0] zeta3_old_4,                                           
    // Coefficient Address
    output reg [5:0] ram_addr1  ,
    // the twiddle factor addresses
    output reg [8:0] twi_addr0  ,
    output reg [8:0] twi_addr1  ,   
    output reg [8:0] twi_addr2  ,
    output reg [8:0] twi_addr3  ,
    output reg [8:0] twi_addr4  ,
    output reg [8:0] twi_addr5  ,
    // Address Generation Completion Signal
    output           done       
);

    localparam N2 = 512;
    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1; 

    wire [1:0] floor    ; // number of layers 
    reg  [7:0] round    ; // number of layers       
    reg  [5:0] cnt_64   ; // counter
    reg  [7:0] j_inv    ; // bit reversal
    reg  [7:0] j_inv_1  ; // bit reversal
    reg  [8:0] zeta_new1;
    reg  [8:0] zeta_new2;
    reg  [8:0] zeta_new3; 
    reg  [8:0] zeta_new4; 
    reg  [8:0] zeta_new5;

    // Random twiddle factor address (eliminate the previous round's random twiddle factor address)
    reg [8:0] zeta0_old; 
    reg [8:0] zeta1_old;
    reg [8:0] zeta2_old;
 // reg [8:0] zeta3_old;
    reg [8:0] zeta4_old;
 // reg [8:0] zeta5_old;  

    // The twiddle factor address of the butterfly unit itself
    reg [8:0] zeta1; 
    reg [8:0] zeta2;
    reg [8:0] zeta3;
    reg [8:0] zeta4;
    reg [8:0] zeta5;                               

    /********************************* twiddle factor address generation ***************************************/
    always@(*) begin 
        twi_addr0 = 0; twi_addr1 = 0; twi_addr2 = 0; twi_addr3 = 0; twi_addr4 = 0; twi_addr5 = 0;
        // Address calculation
        case(mode)
            FORWARD_NTT_MODE : begin
                // the random twiddle factor addresses from the new round 
                zeta0_old = (floor_sr[4] == 'd0 ) ? N2 : (N2 - zeta0_old_1);      
                zeta1_old = (floor_sr[4] == 'd0 ) ? N2 : (N2 - zeta1_old_2);      
                zeta2_old = (floor_sr[4] == 'd0 ) ? N2 : (N2 - zeta2_old_3);      
             // zeta3_old = (floor_sr[4] == 'd0 ) ? N2 : (N2 - zeta2_old_3);     
                zeta4_old = (floor_sr[4] == 'd0 ) ? N2 : (N2 - zeta3_old_4);      
             // zeta5_old = (floor_sr[4] == 'd0 ) ? N2 : (N2 - zeta3_old_4);      

                // the random twiddle factor addresses from the previous round
                zeta_new1 = (floor_sr[4] == 'd3) ? 9'd0 : zeta_new_sr[4];   
             // zeta_new2 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_2;  
             // zeta_new3 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_3;  
             // zeta_new4 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_4;  
             // zeta_new5 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_5;                  
        
                // NTT Operation Twiddle Factor Address
             // zeta0; 
                zeta1 = j_inv;
                zeta2 = j_inv >> 1;
                zeta3 = {1'b1,j_inv[7:1]}; 
                zeta4 = zeta1 + zeta2;
                zeta5 = zeta1 + zeta3;
               
                // local masking Twiddle Factor Address
                twi_addr0 = (zeta_new1 + zeta0_old) & (N2-'d1);
                twi_addr1 = (zeta_new1 + zeta1_old + zeta1) & (N2-'d1);
                twi_addr2 = (zeta_new1 + zeta2_old + zeta2) & (N2-'d1);
                twi_addr3 = (zeta_new1 + zeta2_old + zeta3) & (N2-'d1);
                twi_addr4 = (zeta_new1 + zeta4_old + zeta4) & (N2-'d1);
                twi_addr5 = (zeta_new1 + zeta4_old + zeta5) & (N2-'d1);
            end

            INVERSE_NTT_MODE : begin
                // the random twiddle factor addresses from the new round 
                zeta0_old = (floor_sr[1] == 'd3 ) ? N2 : (N2 - zeta0_old_1);      
             // zeta1_old = (floor_sr[1] == 'd3 ) ? N2 : (N2 - zeta1_old_2);      
             // zeta2_old = (floor_sr[1] == 'd3 ) ? N2 : (N2 - zeta2_old_3);      
             // zeta3_old = (floor_sr[1] == 'd3 ) ? N2 : (N2 - zeta2_old_3);     
             // zeta4_old = (floor_sr[1] == 'd3 ) ? N2 : (N2 - zeta3_old_4);      
             // zeta5_old = (floor_sr[1] == 'd3 ) ? N2 : (N2 - zeta3_old_4);      

                // the random twiddle factor addresses from the previous round
             // zeta_new1 = (floor_sr[4] == 'd3) ? 9'd0 : zeta_new_sr[4];
                zeta_new2 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_2;  
                zeta_new3 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_3;  
                zeta_new4 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_4;  
                zeta_new5 = (floor_sr[1] == 'd0) ? 9'd0 : zeta_new_5;  

                // NTT Operation Twiddle Factor Address
             // zeta0; 
                zeta1 = N2 -  j_inv_1;
                zeta2 = N2 - (j_inv_1 >> 1);
                zeta3 = 384- (j_inv_1 >> 1); 
                zeta4 = zeta1 + zeta2;
                zeta5 = zeta1 + zeta3;

                // local masking Twiddle Factor Address
                twi_addr0 = (zeta_new2 + zeta0_old) & (N2-'d1);
                twi_addr1 = (zeta_new3 + zeta0_old + zeta1) & (N2-'d1);
                twi_addr2 = (zeta_new4 + zeta0_old + zeta2) & (N2-'d1);
                twi_addr3 = (zeta_new4 + zeta0_old + zeta3) & (N2-'d1);
                twi_addr4 = (zeta_new5 + zeta0_old + zeta4) & (N2-'d1);
                twi_addr5 = (zeta_new5 + zeta0_old + zeta5) & (N2-'d1);
            end
        endcase
    end    

    /********************************* Coefficient address generation ***************************************/
    always @(*) begin
        // Cnt-64 byte inversion
        if(floor == 0) begin                                                                  
            ram_addr1 = (cnt_64 << 4) + (cnt_64 >> 2);                                                                                                                            
        end else if(floor == 1) begin                                                                   
            ram_addr1 = (cnt_64 << 2) + (cnt_64 >> 4);
        end else if(floor == 2) begin
            ram_addr1 = cnt_64;
        end else begin
            ram_addr1 = (cnt_64 << 4) + (cnt_64 >> 2);
        end
    end

    /*************************** Generation of twiddle factor address for butterfly unit itself ***********************************/
    always @(*) begin
        case(mode)
            FORWARD_NTT_MODE : begin
                // cnt_64字节反转
                if(floor_sr[4] == 0) begin
                    j_inv = 'd128;                                                                                                      // First layer fixed bit 128                                                                                  
                end else if(floor_sr[4] == 1) begin                                                            
                    j_inv = {cnt_64_sr[4][0],cnt_64_sr[4][1],6'b100000};                                                                // the second layer
                end else if(floor_sr[4] == 2) begin
                    j_inv = {cnt_64_sr[4][0],cnt_64_sr[4][1],cnt_64_sr[4][2],cnt_64_sr[4][3],4'b1000};                                  // the third layer
                end else begin
                    j_inv = {cnt_64_sr[4][0],cnt_64_sr[4][1],cnt_64_sr[4][2],cnt_64_sr[4][3],cnt_64_sr[4][4],cnt_64_sr[4][5],2'b10};    // the fourth floor
                end
            end
            INVERSE_NTT_MODE : begin 
                // cnt_64字节反转
                if(floor_sr[1] == 0) begin
                    j_inv_1 = 'd128;                                                                                                    // fourth layer fixed bit 128                                                                                  
                end else if(floor_sr[1] == 1) begin                                                            
                    j_inv_1 = {cnt_64_sr[1][0],cnt_64_sr[1][1],6'b100000};                                                              // the third layer
                end else if(floor_sr[1] == 2) begin
                    j_inv_1 = {cnt_64_sr[1][0],cnt_64_sr[1][1],cnt_64_sr[1][2],cnt_64_sr[1][3],4'b1000};                                // the second layer
                end else begin
                    j_inv_1 = {cnt_64_sr[1][0],cnt_64_sr[1][1],cnt_64_sr[1][2],cnt_64_sr[1][3],cnt_64_sr[1][4],cnt_64_sr[1][5],2'b10};  // the First floor
                end
            end
        endcase    
    end

    // What round of conversion
    assign floor = (mode == FORWARD_NTT_MODE) ? round : 'd3 - round;

    // End signal for address generation
    assign done = (cnt_64 == 'd63) && (round == 'd3);

    /*************************** Variable transformation ***********************************/
    always @(posedge clk) begin
        if(rst) begin
            round     <= 'd0;
            cnt_64    <= 'd0;
        end else begin
            // Read the address 64 times to enter the next round
            if(cnt_64 == 'd63) begin    // NTT completes one iteration, accumulating 1
                round <= round + 'b1;
            end else begin
                round <= round;
            end

            // Read address count for each layer, requiring 64 address readings
            if(en) begin
                cnt_64 <= cnt_64 + 1;
            end else begin
                cnt_64 <= cnt_64;
            end
        end
    end

    /*************************** Pipeline of its data ***********************************/

    reg [1:0] floor_sr [4:0];
    integer i;
    initial begin
        for (i = 0; i < 4; i = i + 1)
            floor_sr[i] = 0;
    end 
    
    reg [8:0] zeta_new_sr [4:0];
    integer j;
    initial begin
        for (j = 0; j < 4; j = j + 1)
            zeta_new_sr[j] = 0;
    end 

    reg [5:0] cnt_64_sr [4:0];
    integer k;
    initial begin
        for (k = 0; k < 4; k = k + 1)
            cnt_64_sr[k] = 0;
    end 

    always @(posedge clk) begin
        floor_sr[0] <= floor;
            for (i = 0; i < 4; i = i + 1)
                floor_sr[i+1] <= floor_sr[i];

        zeta_new_sr[0] <= zeta_new_1;
            for (j = 0; j < 4; j = j + 1)
                zeta_new_sr[j+1] <= zeta_new_sr[j];
        
        cnt_64_sr[0] <= cnt_64;
            for (k = 0; k < 4; k = k + 1)
                cnt_64_sr[k+1] <= cnt_64_sr[k];
    end

endmodule
