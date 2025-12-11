// Generate pseudo-random numbers
module PRNG(
  input  wire        clk   ,
  input  wire        rst_n ,
  input  wire        ivalid,
  input  wire [15:0] seed  ,
  output reg  [15:0] data
);

    always @ (posedge clk,negedge rst_n) begin
        if (rst_n == 1'b0)
            data <= 16'd0;
        else if (ivalid == 1'b1)
            data <= seed; 
        else begin
            data[ 0] <= data[15]            ;
            data[ 1] <= data[ 0] ^ data[15] ;
            data[ 2] <= data[ 1] ^ data[15] ;
            data[ 3] <= data[ 2] ^ data[15] ;
            data[ 4] <= data[ 3]            ;
            data[ 5] <= data[ 4] ^ data[15] ;
            data[ 6] <= data[ 5]            ;
            data[ 7] <= data[ 6] ^ data[15] ;
            data[ 8] <= data[ 7]            ;
            data[ 9] <= data[ 8]            ;
            data[10] <= data[ 9]            ;
            data[11] <= data[10]            ;
            data[12] <= data[11]            ;
            data[13] <= data[12]            ;
            data[14] <= data[13]            ;
            data[15] <= data[14]            ;
        end
    end
 
endmodule