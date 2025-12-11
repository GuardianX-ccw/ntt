`timescale 1ns/10ps
module op_test_tb( );

	reg          CLOCK ;
	reg          RST_N ;
	reg  [2 :0]  mode  ;
	reg 	     start ;
	wire [131:0] din   ; 	
	reg 		 validi;

	localparam
        FORWARD_NTT_MODE = 3'd0,
        INVERSE_NTT_MODE = 3'd1;                                                    

	assign din = 'h0000000000000000000ad046df4803ca8e;

	OP_TEST_sca OP_TEST_sca(
    	.clk		(CLOCK ),
    	.rst		(RST_N ),
    	.start		(start ),
    	.mode		(mode  ),
		.validi		(validi),
		.in			(din   )            
	);

	initial begin
		CLOCK = 1'b0;
		forever #10 CLOCK = ~CLOCK;
	end

	// Start testing
	initial begin
		// NTT
		validi = 0;
		RST_N  = 0					;
		repeat(129) @(posedge CLOCK);
		RST_N  = 1'b1				;
		mode   = 3'd0				;
		#100 
		start  = 1'b1				; 
		#20
		start  = 1'b0				;
		#10000 

		// INTT
		validi = 0				   ;
		RST_N  = 0				   ;
		repeat(129) @(posedge CLOCK);
		RST_N  = 1'b1			   ;
		mode   = 3'd1			   ;
		#100 
		start  = 1'b1			   ; 
		#20
		start  = 1'b0			   ;
		#10000 

		$stop;
	end

endmodule 