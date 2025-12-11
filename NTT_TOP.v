// -----------------------------------------------------------------------------
// Copyright (c) 2025-2035 All rights reserved
// -----------------------------------------------------------------------------
// Author : chencongwei
// File   : NTT_TOP.v
// Create : 2024-10-27 15:10:47
// Revise : 2025-12-04 15:10:47
// Editor : sublime text3, tab size (4)
// Project:
// Content: 
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

// Unified NTT/INTT architecture Top Level

// NTT ：15-stage pipeline
// INTT：17-stage pipeline

module operation_module#(parameter WIDTH = 'd23, Q = 23'd8380417)(  
    input                           clk              ,
    input                           rst              ,
    input                           start            ,
    input       [2:0]               mode             ,  // When using Vivado logic to synthesize NTT area, this line needs to be commented out
    output reg                      done             ,
 
    input       [8:0]               zeta_new_1       ,  
 
    input       [8:0]               zeta_new_2       , 
    input       [8:0]               zeta_new_3       , 
    input       [8:0]               zeta_new_4       , 
    input       [8:0]               zeta_new_5       , 
    input       [8:0]               zeta_new_2_delay ,
    input       [8:0]               zeta_new_3_delay ,
    input       [8:0]               zeta_new_4_delay ,
    input       [8:0]               zeta_new_5_delay ,
 
    // BRAM 
    output reg  [5:0]               addra1 = 0       , 
    output reg  [5:0]               addrb1 = 0       ,
    input       [131:0]             doa1             ,   
    output reg                      web1   = 0       , 
    output reg  [131:0]             dib1   = 0     
);

    localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1; 

    // wire [2:0]   mode = 0; // Used for Vivado logic synthesis  NTT area
    // wire [2:0]   mode = 1; // Used for Vivado logic synthesis INTT area

    // counter
    reg [1:0] cnt   ; // Count four cycles
    reg       flag  ; // Buffer registers transformation signal
    reg       enfifo;

    // butterfly
    reg                     validi_bf = 0;      // Butterfly unit input enable
    reg  [4*WIDTH-1    :0]  datai_bf  = 0;      // Polynomial coefficients
    reg  [6*WIDTH-1    :0]  zetai_bf  = 0;      // Twiddle factor
    wire [4*(WIDTH+1)-1:0]  datao_bf     ;      // The output of butterfly unit
    wire                    valido_bf    ;      // The output enable of butterfly unit

    // address
    reg        en_addr  ;                                                             // Start generating address enablement
    wire [5:0] ram_addr ;                                                             // Coefficient address
    wire       done_addr;                                                             // Address mapping completion signal, not NTT end signal
    wire [8:0] zeta0_old_1,zeta1_old_2,zeta2_old_3,zeta3_old_4;                       // Random twiddle factor address of the previous layer 
    wire [8:0] twi_addr_0,twi_addr_1,twi_addr_2,twi_addr_3,twi_addr_4,twi_addr_5;     // twiddle factor address                      

    /********************************* The address resolver ***************************************/
    address_unit ADDR(
        .clk            (clk        ),
        .rst            (rst        ),
        .mode           (mode       ),
        .en             (en_addr    ),
        // Address of the random twiddle factor for the new layer
        .zeta_new_1     (zeta_new_1 ),
        .zeta_new_2     (zeta_new_2 ),
        .zeta_new_3     (zeta_new_3 ),
        .zeta_new_4     (zeta_new_4 ),
        .zeta_new_5     (zeta_new_5 ),
        // Random twiddle factor address of the previous layer
        .zeta0_old_1    (zeta0_old_1),
        .zeta1_old_2    (zeta1_old_2),
        .zeta2_old_3    (zeta2_old_3),
        .zeta3_old_4    (zeta3_old_4),
        // Coefficient address
        .ram_addr1      (ram_addr   ),
        // twiddle factor address
        .twi_addr0      (twi_addr_0 ),
        .twi_addr1      (twi_addr_1 ),
        .twi_addr2      (twi_addr_2 ),
        .twi_addr3      (twi_addr_3 ),
        .twi_addr4      (twi_addr_4 ),
        .twi_addr5      (twi_addr_5 ),
        // End signal of address mapping
        .done           (done_addr  )
    );
    
    /********************************* twiddle factor storage unit ***************************************/
    wire [WIDTH:0] do0_twi,do1_twi,do2_twi,do3_twi,do4_twi,do5_twi;

    // No need for IP core
    dual_port_rom #(.WIDTH(WIDTH+1), .LENGTH(256), .INIT_FILE("D:/Date/work/Dlilithium/NTT_sca/NTT_INTT_sca/zetas.txt")) 
            TWIDDLE_RAM1  (clk, 1, twi_addr_0[7:0], twi_addr_1[7:0],do0_twi,do1_twi);
    dual_port_rom #(.WIDTH(WIDTH+1), .LENGTH(256), .INIT_FILE("D:/Date/work/Dlilithium/NTT_sca/NTT_INTT_sca/zetas.txt")) 
            TWIDDLE_RAM2  (clk, 1, twi_addr_2[7:0], twi_addr_3[7:0],do2_twi,do3_twi);
    dual_port_rom #(.WIDTH(WIDTH+1), .LENGTH(256), .INIT_FILE("D:/Date/work/Dlilithium/NTT_sca/NTT_INTT_sca/zetas.txt")) 
            TWIDDLE_RAM3  (clk, 1, twi_addr_4[7:0], twi_addr_5[7:0],do4_twi,do5_twi);

    /********************************* buffer registers ***************************************/
    wire [127:0]       data_in_1 ; 
    wire [127:0]       data_out_1;
    wire [4*WIDTH-1:0] data_out  ; 
    wire [131:0]       datao_bf_1;

    assign data_in_1 = (mode == FORWARD_NTT_MODE) ? {doa1      [130:99],       doa1[97:66],       doa1[ 64:33],       doa1[31: 0]}: 
                                                    {datao_bf_1[ 64:33], datao_bf_1[31: 0], datao_bf_1[130:99], datao_bf_1[97:66]};
    cofe_regs #(.Q(Q),.WIDTH(32))cofe_regs(clk, flag, data_in_1, data_out_1); 

    assign data_out = {data_out_1[127:105],data_out_1[95:73],data_out_1[63:41],data_out_1[31:9]};
    assign zeta0_old_1 = (mode == FORWARD_NTT_MODE) ? data_out_1[104:96] : {doa1_sr[  8: 0]};
    assign zeta1_old_2 = (mode == FORWARD_NTT_MODE) ? data_out_1[72 :64] : {doa1_sr[ 41:33]};
    assign zeta2_old_3 = (mode == FORWARD_NTT_MODE) ? data_out_1[40 :32] : {doa1_sr[ 74:66]};
    assign zeta3_old_4 = (mode == FORWARD_NTT_MODE) ? data_out_1[8  :0 ] : {doa1_sr[107:99]};

    /********************************* the twiddle factor pre-processing unit ***************************************/
    // NTT：2-stage pipeline INTT：3-stage pipeline
    wire [6*WIDTH-1:0] in_pipo ;
    wire [6*WIDTH-1:0] out_pipo;
    reg pre_flag0,pre_flag1,pre_flag2,pre_flag3,pre_flag4,pre_flag5; // Temporarily store the highest bit of the twiddle factor address

    assign in_pipo = {do0_twi[WIDTH-1:0],do1_twi[WIDTH-1:0],do2_twi[WIDTH-1:0],do3_twi[WIDTH-1:0],do4_twi[WIDTH-1:0],do5_twi[WIDTH-1:0]};
    twiddle_regs #(.Q(Q),.WIDTH(WIDTH)) twiddle_regs(clk,mode,{pre_flag0,pre_flag1,pre_flag2,pre_flag3,pre_flag4,pre_flag5},in_pipo,out_pipo);

    /********************************* the BF4 unit ***************************************/
    butterfly2x2_csa #(.Q(Q),.WIDTH(WIDTH)) butterfly2x2_csa(
        .clk            (clk      ),
        .rst            (rst      ),
        .mode           (mode     ),
        .validi         (validi_bf),
        .datai          (datai_bf ),
        .zetai          (zetai_bf ),
        .data_o         (datao_bf ),
        .valido         (valido_bf)
    );

    assign datao_bf_1 = (mode == FORWARD_NTT_MODE) ? 
                        {datao_bf[95:72],  zeta_new_sr[14], datao_bf[71:48],  zeta_new_sr[14], datao_bf[47:24],  zeta_new_sr[14], datao_bf[23:0],  zeta_new_sr[14]}:
                        {datao_bf[95:72], zeta_new_4_delay, datao_bf[71:48], zeta_new_2_delay, datao_bf[47:24], zeta_new_5_delay, datao_bf[23:0], zeta_new_3_delay};                

    always @(*) begin
        case(mode)
        FORWARD_NTT_MODE: begin
            // the BF4 unit
            zetai_bf  = out_pipo       ; 
            datai_bf  = date_sr[2]     ; 
            validi_bf = validi_bf_sr[7]; 
            // BRAM
            addra1    = ram_addr       ; 
            addrb1    = addrb1_sr[14]  ; 
            web1      = valido_bf      ;
            dib1      = datao_bf_1     ; 
            done      = done_sr[15]    ; 
        end

        INVERSE_NTT_MODE: begin
            // the BF4 unit
            zetai_bf  = out_pipo       ; 
            datai_bf  = date_sr[3]     ;                         
            validi_bf = validi_bf_sr[5]; 
            // BRAM
            addra1    = ram_addr       ; 
            addrb1    = addrb1_sr[16]  ;
            web1      = valido_bf_sr[3];
            dib1      = {1'b0,data_out_1[31:0],1'b0,data_out_1[95:64],1'b0,data_out_1[63:32],1'b0,data_out_1[127:96]}; 
            done      = done_sr[17]    ; 
        end
        endcase
    end

    /********************************* counter ***************************************/
    always @(posedge clk) begin
        if (rst) begin
            cnt <= 'd0;
            flag <= 1 ;
        end else begin
            // cnt
            if(mode == FORWARD_NTT_MODE) begin
                cnt <= enfifo ? cnt + 1 : 0;
            end else begin
                cnt <= valido_bf ? cnt + 1 : 0;
            end

            // flag 
            if(!enfifo) begin
                flag <= 1;
            end else if(cnt[0] & cnt[1]) begin
                flag <=  ~flag;
            end else begin
                flag <=  flag;
            end 
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            enfifo    <= 0;
            en_addr   <= 0;
            pre_flag0 <= 0;
            pre_flag1 <= 0;
            pre_flag2 <= 0;
            pre_flag3 <= 0;
            pre_flag4 <= 0;
            pre_flag5 <= 0;
        end else begin
            if(mode == FORWARD_NTT_MODE || mode == INVERSE_NTT_MODE) begin
                pre_flag0 <= twi_addr_0[8]; // Does the highest position represent the need to multiply by -1
                pre_flag1 <= twi_addr_1[8];
                pre_flag2 <= twi_addr_2[8];
                pre_flag3 <= twi_addr_3[8];
                pre_flag4 <= twi_addr_4[8];
                pre_flag5 <= twi_addr_5[8];
            end else begin 
                pre_flag0 <= 0;
                pre_flag1 <= 0;
                pre_flag2 <= 0;
                pre_flag3 <= 0;
                pre_flag4 <= 0;
                pre_flag5 <= 0;
            end

            // en_addr  
            if(start) 
                en_addr <= 'b1;
            else if(done_addr) 
                en_addr <= 'b0;
            else
                en_addr <= en_addr;

            // enfifo
            if(en_addr)
                enfifo <= 'b1;
            else if(done)
                enfifo <= 0;
            else
                enfifo <= enfifo;
        end
    end

    /********************************* Pipeline of its data ***************************************/
    reg [17:0] done_sr;
    integer i;
    initial begin
        for (i = 0; i < 17; i = i + 1)
            done_sr[i] = 0;
    end 

    reg [7:0] validi_bf_sr;
    integer j;
    initial begin
        for (j = 0; j < 7; j = j + 1)
            validi_bf_sr[j] = 0;
    end 

    reg [8:0] zeta_new_sr [14:0];
    integer k;
    initial begin
        for (k = 0; k < 14; k = k + 1)
            zeta_new_sr[k] = 0;
    end 

    reg [5:0] addrb1_sr [16:0];
    integer l;
    initial begin
        for (l = 0; l < 16; l = l + 1)
            addrb1_sr[l] = 0;
    end 

    reg [3:0] valido_bf_sr;
    integer m;
    initial begin
        for (m = 0; m < 3; m = m + 1)
            valido_bf_sr[m] = 0;
    end 

    reg [91:0] date_sr [3:0];
    integer n;
    initial begin
        for (n = 0; n < 3; n = n + 1)
            date_sr[n] = 0;
    end 

    reg [131:0] doa1_sr;

    always @(posedge clk) begin
        doa1_sr      <= doa1;
        done_sr      <= {done_sr     [16:0], done_addr};  
        validi_bf_sr <= {validi_bf_sr[ 6:0], en_addr  }; 
        valido_bf_sr <= {valido_bf_sr[ 2:0], valido_bf}; 
        
        zeta_new_sr[0] <= zeta_new_1;
            for (k = 0; k < 14; k = k + 1)
                zeta_new_sr[k+1] <= zeta_new_sr[k];

        addrb1_sr[0] <= ram_addr;
            for (l = 0; l < 16; l = l + 1)
                addrb1_sr[l+1] <= addrb1_sr[l];
        
        date_sr[0] <= (mode == FORWARD_NTT_MODE) ? data_out : {doa1_sr[31:9],doa1_sr[64:42],doa1_sr[97:75],doa1_sr[130:108]};
            for (n = 0; n < 3; n = n + 1)
                date_sr[n+1] <= date_sr[n];
    end

endmodule



