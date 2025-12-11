// This module is mainly responsible for data scheduling (testing the unified NTT/INTT architecture)

module OP_TEST_sca #(parameter WIDTH = 'd23, parameter Q = 23'd8380417, parameter k = 'd4, parameter l = 'd4) (
    input                   clk     ,
    input                   rst     ,
    input                   start   ,
    input       [  2:0]     mode    ,
    input       [135:0]     in      ,
    input                   validi  ,         // External write enable for memory port a  
    output reg  [135:0]     text_out, 
    output                  dvld              // End Signal
);

    reg  [ 6:0]  cnt           ;
    reg  [15:0]  buffer        ;
    reg          ntt_start     ;
    wire [5:0]   addra_ram1_NTT;              // Address for reading coefficients

    wire [5:0]   addra_ram1    ;              // External write coefficient address for memory port a
    wire [131:0] doa_ram1      ;              // Memory port a NTT reads coefficient output data
    wire         web_ram1      ;              // Memory port b NTT write coefficient enable
    wire [5:0]   addrb_ram1    ;              // Memory port b NTT write coefficient address
    wire [131:0] dib_ram1      ;              // Memory port b NTT write coefficient input data
    wire [131:0] dob_ram1      ;              // Memory port b NTT write coefficient output data (not connected)
    
    // Coefficient and random twiddle factor address memory (without IP core)
    dual_port_ram #(.WIDTH(132), .LENGTH(64), .INIT_FILE("D:/Date/work/Dlilithium/NTT_sca/NTT_INTT_sca/seed.txt")) BRAM_1 (
 // dual_port_ram #(.WIDTH(132), .LENGTH(64))BRAM_1 (
        .clka       (clk       ), 
        .clkb       (clk       ),
        .ena        (1         ),
        .enb        (1         ),
        .wea        (validi    ),
        .web        (web_ram1  ),
        .addra      (addra_ram1),
        .addrb      (addrb_ram1),
        .dia        (in[131:0] ),
        .dib        (dib_ram1  ),
        .doa        (doa_ram1  ),
        .dob        (dob_ram1  )
    );  

    // Write data externally to memory (such as Uart)
    assign addra_ram1 = ntt_start ? addra_ram1_NTT : cnt;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt         <= 'd0;
            ntt_start   <= 'd0;
            text_out    <= 'd0;
        end else begin

            // cnt 
            if(cnt == 'd64 && validi) begin
                cnt <= 'd0;
            end else if(validi) begin
                cnt <= cnt + 1'd1;
            end else begin
                cnt <= cnt;
            end
            if(cnt == 'd64 && validi)         // The 65th number is used to generate a random twiddle factor address
               buffer <= in;
            
            // ntt_start
            if(start) begin
                ntt_start <= 'b1;
            end else if(dvld) begin
                ntt_start <= 'b0;
            end else begin
                ntt_start <= ntt_start;
            end

            // text_out
            text_out <= {4'b0,dib_ram1[131:0]};
        end
    end

    // PRNG (Generate random twiddle factor address, note that this is a pseudo-random number generator)
    wire [15:0] radom;
    PRNG PRNG_1(
        .clk        (clk    ),
        .rst_n      (rst    ), 
        .ivalid     (start  ),
        .seed       (in     ),
        .data       (radom  )
    );

    // Generate random twiddle factor addresses that meet INTT index requirements
    wire [8:0] zeta_new_2       , zeta_new_3       , zeta_new_4       , zeta_new_5       ;
    wire [8:0] zeta_new_2_delay , zeta_new_3_delay , zeta_new_4_delay , zeta_new_5_delay ;
    wire [8:0] zeta_new_2_delay2, zeta_new_3_delay3, zeta_new_4_delay4, zeta_new_5_delay5;

    reg [1:0] cnt_1 ; 
    reg       flag  ; 
    reg       enfifo;
    cofe_regs #(.Q(Q),.WIDTH(9)) cofe_regs1 (clk, flag, {radom[8:0], radom[8:0], radom[8:0], radom[8:0]}, {zeta_new_2, zeta_new_3, zeta_new_4, zeta_new_5});

    delay #( 2, 9) delay_1 (clk, zeta_new_2, zeta_new_2_delay );
    delay #( 2, 9) delay_2 (clk, zeta_new_3, zeta_new_3_delay );
    delay #( 2, 9) delay_3 (clk, zeta_new_4, zeta_new_4_delay );
    delay #( 2, 9) delay_4 (clk, zeta_new_5, zeta_new_5_delay );
    delay #(13, 9) delay_5 (clk, zeta_new_2, zeta_new_2_delay2);
    delay #(13, 9) delay_6 (clk, zeta_new_3, zeta_new_3_delay3);
    delay #(13, 9) delay_7 (clk, zeta_new_4, zeta_new_4_delay4);
    delay #(13, 9) delay_8 (clk, zeta_new_5, zeta_new_5_delay5);

    always @(posedge clk) begin
        if (~rst) begin
            cnt_1  <= 'd0;
            flag   <= 'd1;
            enfifo <= 'd0;
        end else begin
            if(start) 
                enfifo <= 'b1;
            else if(dvld)
                enfifo <= 'b0;
            else
                enfifo <= enfifo;

            cnt_1 <= enfifo ? cnt_1 + 1 : 0;

            if(!enfifo) begin
                flag <= 1;
            end else if(cnt_1[0] & cnt_1[1]) begin
                flag <=  ~flag;
            end else begin
                flag <=  flag;
            end 
        end
    end

    // Unified NTT/INTT Top Level
    operation_module #(.Q(Q),.WIDTH(WIDTH)) operation_module (   
        .clk              (clk              ),
        .rst              (!rst             ),
        .start            (start            ),
        .mode             (mode             ),    
        .done             (dvld             ),

        .zeta_new_1       (radom            ),      // NTT random twiddle factor addresses

        .zeta_new_2       (zeta_new_2_delay ),      // Random rotation factor address that conforms to INTT index (four in total)
        .zeta_new_3       (zeta_new_3_delay ),
        .zeta_new_4       (zeta_new_4_delay ),
        .zeta_new_5       (zeta_new_5_delay ),
        .zeta_new_2_delay (zeta_new_2_delay2),
        .zeta_new_3_delay (zeta_new_3_delay3),
        .zeta_new_4_delay (zeta_new_4_delay4),
        .zeta_new_5_delay (zeta_new_5_delay5),

        .doa1             (doa_ram1         ),     
        .addra1           (addra_ram1_NTT   ),     
        .web1             (web_ram1         ),      
        .dib1             (dib_ram1         ),      
        .addrb1           (addrb_ram1       )     
    );

endmodule