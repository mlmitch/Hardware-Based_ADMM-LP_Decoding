`ifndef _my_arg_min_
`define _my_arg_min_

/*
Mitch Wasson (mitch.wasson@gmail.com)

Input is an array of unsigned integers.

This module returns a one hot vector where the high bit corresponds to
the location of the minimum number in the input vector

Note that there is only clk, reset, and enable for control signals.
This module is to be used in parallel with pipeline train.

This module always takes ceil(log2(BLOCKLENGTH)) time steps.
No input registering.

*/

`include "2dArrayMacros.v"


module ArgMin # 
(
	parameter BLOCKLENGTH = 1, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

generate
	if( 1 == BLOCKLENGTH ) begin
		assign arg[0] = 1'b1;
	end else if( 2 == BLOCKLENGTH) begin
		am2 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 3 == BLOCKLENGTH) begin
		am3 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 4 == BLOCKLENGTH) begin
		am4 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 5 == BLOCKLENGTH) begin
		am5 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 6 == BLOCKLENGTH) begin
		am6 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 7 == BLOCKLENGTH) begin
		am7 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 8 == BLOCKLENGTH) begin
		am8 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 14 == BLOCKLENGTH) begin
		am14 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 15 == BLOCKLENGTH) begin
		am15 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end else if( 16 == BLOCKLENGTH) begin
		am16 #(	.BLOCKLENGTH(BLOCKLENGTH),
					.DATA_WIDTH(DATA_WIDTH)) amin(clk, reset, enable, data_in, arg);
	end

endgenerate

endmodule

//TWO INPUT ARGMIN - ONE SET OF REGISTERS
module am2 # 
(
	parameter BLOCKLENGTH = 2, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

reg [0:BLOCKLENGTH-1] out;
wire leq;

assign leq = in[0] <= in[1];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		out <= 0;
	end else if (1'b1 == enable) begin
		out[0] <= leq;
		out[1] <= ~leq;
	end
end

assign arg = out;

endmodule

//THREE INPUT ARGMIN - TWO SET OF REGISTERS
module am3 # 
(
	parameter BLOCKLENGTH = 3, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:1];
wire leq1;

assign leq1 = in[0] <= in[1];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1;
		arg1[1] <= ~leq1;
		arg1[2] <= 1'b1;
		
		min1[0] <= leq1 ? in[0] : in[1];
		min1[1] <= in[2];
	end
end

//second layer of comparison
reg [0:BLOCKLENGTH-1] arg2;
wire leq2;
assign leq2 = min1[0] <= min1[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2;
		arg2[1] <= arg1[1] & leq2;
		arg2[2] <= arg1[2] & ~leq2;
	end
end

//assign output
assign arg = arg2;

endmodule


//FOUR INPUT ARGMIN - TWO SET OF REGISTERS
module am4 # 
(
	parameter BLOCKLENGTH = 4, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:1];
wire [0:1] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
	end
end

//second layer of comparison
reg [0:BLOCKLENGTH-1] arg2;
wire leq2;
assign leq2 = min1[0] <= min1[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2;
		arg2[1] <= arg1[1] & leq2;
		arg2[2] <= arg1[2] & ~leq2;
		arg2[3] <= arg1[3] & ~leq2;
	end
end

//assign output
assign arg = arg2;

endmodule

//FIVE INPUT ARGMIN - THREE SET OF REGISTERS
module am5 # 
(
	parameter BLOCKLENGTH = 5, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:2];
wire [0:1] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= 1'b1;
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= in[4];
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:1];
reg [0:BLOCKLENGTH-1] arg2;
wire leq2;
assign leq2 = min1[0] <= min1[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2;
		arg2[1] <= arg1[1] & leq2;
		arg2[2] <= arg1[2] & ~leq2;
		arg2[3] <= arg1[3] & ~leq2;
		arg2[4] <= arg1[4];
		
		min2[0] <= leq2 ? min1[0] : min1[1];
		min2[1] <= min1[2]; 
	end
end

//third layer of comparison
reg [0:BLOCKLENGTH-1] arg3;
wire leq3;
assign leq3 = min2[0] <= min2[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3;
		arg3[1] <= arg2[1] & leq3;
		arg3[2] <= arg2[2] & leq3;
		arg3[3] <= arg2[3] & leq3;
		arg3[4] <= arg2[4] & ~leq3;
	end
end

//assign output
assign arg = arg3;

endmodule

//SIX INPUT ARGMIN - THREE SET OF REGISTERS
module am6 # 
(
	parameter BLOCKLENGTH = 6, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:2];
wire [0:2] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];
assign leq1[2] = in[4] <= in[5];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= leq1[2];
		arg1[5] <= ~leq1[2];
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= leq1[2] ? in[4] : in[5];	
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:1];
reg [0:BLOCKLENGTH-1] arg2;
wire leq2;
assign leq2 = min1[0] <= min1[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2;
		arg2[1] <= arg1[1] & leq2;
		arg2[2] <= arg1[2] & ~leq2;
		arg2[3] <= arg1[3] & ~leq2;
		arg2[4] <= arg1[4];
		arg2[5] <= arg1[5];
		
		min2[0] <= leq2 ? min1[0] : min1[1];
		min2[1] <= min1[2]; 
	end
end

//third layer of comparison
reg [0:BLOCKLENGTH-1] arg3;
wire leq3;
assign leq3 = min2[0] <= min2[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3;
		arg3[1] <= arg2[1] & leq3;
		arg3[2] <= arg2[2] & leq3;
		arg3[3] <= arg2[3] & leq3;
		arg3[4] <= arg2[4] & ~leq3;
		arg3[5] <= arg2[5] & ~leq3;
	end
end

//assign output
assign arg = arg3;

endmodule

//SEVEN INPUT ARGMIN - THREE SET OF REGISTERS
module am7 # 
(
	parameter BLOCKLENGTH = 7, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:3];
wire [0:2] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];
assign leq1[2] = in[4] <= in[5];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		min1[3] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= leq1[2];
		arg1[5] <= ~leq1[2];
		arg1[6] <= 1'b1;
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= leq1[2] ? in[4] : in[5];	
		min1[3] <= in[6];
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:1];
reg [0:BLOCKLENGTH-1] arg2;
wire [0:1] leq2;
assign leq2[0] = min1[0] <= min1[1];
assign leq2[1] = min1[2] <= min1[3];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2[0];
		arg2[1] <= arg1[1] & leq2[0];
		arg2[2] <= arg1[2] & ~leq2[0];
		arg2[3] <= arg1[3] & ~leq2[0];
		arg2[4] <= arg1[4] & leq2[1];
		arg2[5] <= arg1[5] & leq2[1];
		arg2[6] <= arg1[6] & ~leq2[1];
		
		min2[0] <= leq2[0] ? min1[0] : min1[1];
		min2[1] <= leq2[1] ? min1[2] : min1[3]; 
	end
end

//third layer of comparison
reg [0:BLOCKLENGTH-1] arg3;
wire leq3;
assign leq3 = min2[0] <= min2[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3;
		arg3[1] <= arg2[1] & leq3;
		arg3[2] <= arg2[2] & leq3;
		arg3[3] <= arg2[3] & leq3;
		arg3[4] <= arg2[4] & ~leq3;
		arg3[5] <= arg2[5] & ~leq3;
		arg3[6] <= arg2[6] & ~leq3;
	end
end

//assign output
assign arg = arg3;

endmodule

//EIGHT INPUT ARGMIN - THREE SET OF REGISTERS
module am8 # 
(
	parameter BLOCKLENGTH = 8, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:3];
wire [0:3] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];
assign leq1[2] = in[4] <= in[5];
assign leq1[3] = in[6] <= in[7];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		min1[3] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= leq1[2];
		arg1[5] <= ~leq1[2];
		arg1[6] <= leq1[3];
		arg1[7] <= ~leq1[3];
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= leq1[2] ? in[4] : in[5];	
		min1[3] <= leq1[3] ? in[6] : in[7];	
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:1];
reg [0:BLOCKLENGTH-1] arg2;
wire [0:1] leq2;
assign leq2[0] = min1[0] <= min1[1];
assign leq2[1] = min1[2] <= min1[3];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2[0];
		arg2[1] <= arg1[1] & leq2[0];
		arg2[2] <= arg1[2] & ~leq2[0];
		arg2[3] <= arg1[3] & ~leq2[0];
		arg2[4] <= arg1[4] & leq2[1];
		arg2[5] <= arg1[5] & leq2[1];
		arg2[6] <= arg1[6] & ~leq2[1];
		arg2[7] <= arg1[7] & ~leq2[1];
		
		min2[0] <= leq2[0] ? min1[0] : min1[1];
		min2[1] <= leq2[1] ? min1[2] : min1[3]; 
	end
end

//third layer of comparison
reg [0:BLOCKLENGTH-1] arg3;
wire leq3;
assign leq3 = min2[0] <= min2[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3;
		arg3[1] <= arg2[1] & leq3;
		arg3[2] <= arg2[2] & leq3;
		arg3[3] <= arg2[3] & leq3;
		arg3[4] <= arg2[4] & ~leq3;
		arg3[5] <= arg2[5] & ~leq3;
		arg3[6] <= arg2[6] & ~leq3;
		arg3[7] <= arg2[7] & ~leq3;
	end
end

//assign output
assign arg = arg3;

endmodule

//FOURTEEN INPUT ARGMIN - FOUR SET OF REGISTERS
module am14 # 
(
	parameter BLOCKLENGTH = 14, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:6];
wire [0:6] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];
assign leq1[2] = in[4] <= in[5];
assign leq1[3] = in[6] <= in[7];
assign leq1[4] = in[8] <= in[9];
assign leq1[5] = in[10] <= in[11];
assign leq1[6] = in[12] <= in[13];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		min1[3] <= 0;
		min1[4] <= 0;
		min1[5] <= 0;
		min1[6] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= leq1[2];
		arg1[5] <= ~leq1[2];
		arg1[6] <= leq1[3];
		arg1[7] <= ~leq1[3];
		arg1[8] <= leq1[4];
		arg1[9] <= ~leq1[4];
		arg1[10] <= leq1[5];
		arg1[11] <= ~leq1[5];
		arg1[12] <= leq1[6];
		arg1[13] <= ~leq1[6];
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= leq1[2] ? in[4] : in[5];	
		min1[3] <= leq1[3] ? in[6] : in[7];
		min1[4] <= leq1[4] ? in[8] : in[9];
		min1[5] <= leq1[5] ? in[10] : in[11];
		min1[6] <= leq1[6] ? in[12] : in[13];		
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:3];
reg [0:BLOCKLENGTH-1] arg2;
wire [0:2] leq2;
assign leq2[0] = min1[0] <= min1[1];
assign leq2[1] = min1[2] <= min1[3];
assign leq2[2] = min1[4] <= min1[5];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		min2[2] <= 0;
		min2[3] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2[0];
		arg2[1] <= arg1[1] & leq2[0];
		arg2[2] <= arg1[2] & ~leq2[0];
		arg2[3] <= arg1[3] & ~leq2[0];
		arg2[4] <= arg1[4] & leq2[1];
		arg2[5] <= arg1[5] & leq2[1];
		arg2[6] <= arg1[6] & ~leq2[1];
		arg2[7] <= arg1[7] & ~leq2[1];
		arg2[8] <= arg1[8] & leq2[2];
		arg2[9] <= arg1[9] & leq2[2];
		arg2[10] <= arg1[10] & ~leq2[2];
		arg2[11] <= arg1[11] & ~leq2[2];
		arg2[12] <= arg1[12] & 1'b1;
		arg2[13] <= arg1[13] & 1'b1;
		
		min2[0] <= leq2[0] ? min1[0] : min1[1];
		min2[1] <= leq2[1] ? min1[2] : min1[3];
		min2[2] <= leq2[2] ? min1[4] : min1[5];
		min2[3] <= min1[6]; 		
	end
end

//third layer of comparison
reg [DATA_WIDTH-1:0] min3 [0:1];
reg [0:BLOCKLENGTH-1] arg3;
wire [0:1] leq3;
assign leq3[0] = min2[0] <= min2[1];
assign leq3[1] = min2[2] <= min2[3];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
		min3[0] <= 0;
		min3[1] <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3[0];
		arg3[1] <= arg2[1] & leq3[0];
		arg3[2] <= arg2[2] & leq3[0];
		arg3[3] <= arg2[3] & leq3[0];
		arg3[4] <= arg2[4] & ~leq3[0];
		arg3[5] <= arg2[5] & ~leq3[0];
		arg3[6] <= arg2[6] & ~leq3[0];
		arg3[7] <= arg2[7] & ~leq3[0];
		arg3[8] <= arg2[8] & leq3[1];
		arg3[9] <= arg2[9] & leq3[1];
		arg3[10] <= arg2[10] & leq3[1];
		arg3[11] <= arg2[11] & leq3[1];
		arg3[12] <= arg2[12] & ~leq3[1];
		arg3[13] <= arg2[13] & ~leq3[1];	
		
		min3[0] <= leq3[0] ? min2[0] : min2[1];
		min3[1] <= leq3[1] ? min2[2] : min2[3];
	end
end

//fourth layer of comparison
reg [0:BLOCKLENGTH-1] arg4;
wire leq4;
assign leq4 = min3[0] <= min3[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg4 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg4[0] <= arg3[0] & leq4;
		arg4[1] <= arg3[1] & leq4;
		arg4[2] <= arg3[2] & leq4;
		arg4[3] <= arg3[3] & leq4;
		arg4[4] <= arg3[4] & leq4;
		arg4[5] <= arg3[5] & leq4;
		arg4[6] <= arg3[6] & leq4;
		arg4[7] <= arg3[7] & leq4;
		arg4[8] <= arg3[8] & ~leq4;
		arg4[9] <= arg3[9] & ~leq4;
		arg4[10] <= arg3[10] & ~leq4;
		arg4[11] <= arg3[11] & ~leq4;
		arg4[12] <= arg3[12] & ~leq4;
		arg4[13] <= arg3[13] & ~leq4;
	end
end

assign arg = arg4;

endmodule

//FIFTEEN INPUT ARGMIN - FOUR SET OF REGISTERS
module am15 # 
(
	parameter BLOCKLENGTH = 15, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:7];
wire [0:6] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];
assign leq1[2] = in[4] <= in[5];
assign leq1[3] = in[6] <= in[7];
assign leq1[4] = in[8] <= in[9];
assign leq1[5] = in[10] <= in[11];
assign leq1[6] = in[12] <= in[13];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		min1[3] <= 0;
		min1[4] <= 0;
		min1[5] <= 0;
		min1[6] <= 0;
		min1[7] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= leq1[2];
		arg1[5] <= ~leq1[2];
		arg1[6] <= leq1[3];
		arg1[7] <= ~leq1[3];
		arg1[8] <= leq1[4];
		arg1[9] <= ~leq1[4];
		arg1[10] <= leq1[5];
		arg1[11] <= ~leq1[5];
		arg1[12] <= leq1[6];
		arg1[13] <= ~leq1[6];
		arg1[14] <= 1'b1;
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= leq1[2] ? in[4] : in[5];	
		min1[3] <= leq1[3] ? in[6] : in[7];
		min1[4] <= leq1[4] ? in[8] : in[9];
		min1[5] <= leq1[5] ? in[10] : in[11];
		min1[6] <= leq1[6] ? in[12] : in[13];	
		min1[7] <= in[14];	
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:3];
reg [0:BLOCKLENGTH-1] arg2;
wire [0:3] leq2;
assign leq2[0] = min1[0] <= min1[1];
assign leq2[1] = min1[2] <= min1[3];
assign leq2[2] = min1[4] <= min1[5];
assign leq2[3] = min1[6] <= min1[7];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		min2[2] <= 0;
		min2[3] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2[0];
		arg2[1] <= arg1[1] & leq2[0];
		arg2[2] <= arg1[2] & ~leq2[0];
		arg2[3] <= arg1[3] & ~leq2[0];
		arg2[4] <= arg1[4] & leq2[1];
		arg2[5] <= arg1[5] & leq2[1];
		arg2[6] <= arg1[6] & ~leq2[1];
		arg2[7] <= arg1[7] & ~leq2[1];
		arg2[8] <= arg1[8] & leq2[2];
		arg2[9] <= arg1[9] & leq2[2];
		arg2[10] <= arg1[10] & ~leq2[2];
		arg2[11] <= arg1[11] & ~leq2[2];
		arg2[12] <= arg1[12] & leq2[3];
		arg2[13] <= arg1[13] & leq2[3];
		arg2[14] <= arg1[14] & ~leq2[3];
		
		min2[0] <= leq2[0] ? min1[0] : min1[1];
		min2[1] <= leq2[1] ? min1[2] : min1[3];
		min2[2] <= leq2[2] ? min1[4] : min1[5];
		min2[3] <= leq2[3] ? min1[6] : min1[7]; 		
	end
end

//third layer of comparison
reg [DATA_WIDTH-1:0] min3 [0:1];
reg [0:BLOCKLENGTH-1] arg3;
wire [0:1] leq3;
assign leq3[0] = min2[0] <= min2[1];
assign leq3[1] = min2[2] <= min2[3];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
		min3[0] <= 0;
		min3[1] <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3[0];
		arg3[1] <= arg2[1] & leq3[0];
		arg3[2] <= arg2[2] & leq3[0];
		arg3[3] <= arg2[3] & leq3[0];
		arg3[4] <= arg2[4] & ~leq3[0];
		arg3[5] <= arg2[5] & ~leq3[0];
		arg3[6] <= arg2[6] & ~leq3[0];
		arg3[7] <= arg2[7] & ~leq3[0];
		arg3[8] <= arg2[8] & leq3[1];
		arg3[9] <= arg2[9] & leq3[1];
		arg3[10] <= arg2[10] & leq3[1];
		arg3[11] <= arg2[11] & leq3[1];
		arg3[12] <= arg2[12] & ~leq3[1];
		arg3[13] <= arg2[13] & ~leq3[1];
		arg3[14] <= arg2[14] & ~leq3[1];		
		
		min3[0] <= leq3[0] ? min2[0] : min2[1];
		min3[1] <= leq3[1] ? min2[2] : min2[3];
	end
end

//fourth layer of comparison
reg [0:BLOCKLENGTH-1] arg4;
wire leq4;
assign leq4 = min3[0] <= min3[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg4 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg4[0] <= arg3[0] & leq4;
		arg4[1] <= arg3[1] & leq4;
		arg4[2] <= arg3[2] & leq4;
		arg4[3] <= arg3[3] & leq4;
		arg4[4] <= arg3[4] & leq4;
		arg4[5] <= arg3[5] & leq4;
		arg4[6] <= arg3[6] & leq4;
		arg4[7] <= arg3[7] & leq4;
		arg4[8] <= arg3[8] & ~leq4;
		arg4[9] <= arg3[9] & ~leq4;
		arg4[10] <= arg3[10] & ~leq4;
		arg4[11] <= arg3[11] & ~leq4;
		arg4[12] <= arg3[12] & ~leq4;
		arg4[13] <= arg3[13] & ~leq4;
		arg4[14] <= arg3[14] & ~leq4;	
	end
end

assign arg = arg4;

endmodule


//SIXTEEN INPUT ARGMIN - FOUR SET OF REGISTERS
module am16 # 
(
	parameter BLOCKLENGTH = 16, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output [0:BLOCKLENGTH-1] arg	
);

wire [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//first layer of comparison
reg [0:BLOCKLENGTH-1] arg1;
reg [DATA_WIDTH-1:0] min1 [0:7];
wire [0:7] leq1;

assign leq1[0] = in[0] <= in[1];
assign leq1[1] = in[2] <= in[3];
assign leq1[2] = in[4] <= in[5];
assign leq1[3] = in[6] <= in[7];
assign leq1[4] = in[8] <= in[9];
assign leq1[5] = in[10] <= in[11];
assign leq1[6] = in[12] <= in[13];
assign leq1[7] = in[14] <= in[15];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min1[0] <= 0;
		min1[1] <= 0;
		min1[2] <= 0;
		min1[3] <= 0;
		min1[4] <= 0;
		min1[5] <= 0;
		min1[6] <= 0;
		min1[7] <= 0;
		arg1 <= 0;
	end else if (1'b1 == enable) begin
		arg1[0] <= leq1[0];
		arg1[1] <= ~leq1[0];
		arg1[2] <= leq1[1];
		arg1[3] <= ~leq1[1];
		arg1[4] <= leq1[2];
		arg1[5] <= ~leq1[2];
		arg1[6] <= leq1[3];
		arg1[7] <= ~leq1[3];
		arg1[8] <= leq1[4];
		arg1[9] <= ~leq1[4];
		arg1[10] <= leq1[5];
		arg1[11] <= ~leq1[5];
		arg1[12] <= leq1[6];
		arg1[13] <= ~leq1[6];
		arg1[14] <= leq1[7];
		arg1[15] <= ~leq1[7];
		
		min1[0] <= leq1[0] ? in[0] : in[1];
		min1[1] <= leq1[1] ? in[2] : in[3];
		min1[2] <= leq1[2] ? in[4] : in[5];	
		min1[3] <= leq1[3] ? in[6] : in[7];
		min1[4] <= leq1[4] ? in[8] : in[9];
		min1[5] <= leq1[5] ? in[10] : in[11];
		min1[6] <= leq1[6] ? in[12] : in[13];	
		min1[7] <= leq1[7] ? in[14] : in[15];	
	end
end

//second layer of comparison
reg [DATA_WIDTH-1:0] min2 [0:3];
reg [0:BLOCKLENGTH-1] arg2;
wire [0:3] leq2;
assign leq2[0] = min1[0] <= min1[1];
assign leq2[1] = min1[2] <= min1[3];
assign leq2[2] = min1[4] <= min1[5];
assign leq2[3] = min1[6] <= min1[7];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		min2[0] <= 0;
		min2[1] <= 0;
		min2[2] <= 0;
		min2[3] <= 0;
		arg2 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg2[0] <= arg1[0] & leq2[0];
		arg2[1] <= arg1[1] & leq2[0];
		arg2[2] <= arg1[2] & ~leq2[0];
		arg2[3] <= arg1[3] & ~leq2[0];
		arg2[4] <= arg1[4] & leq2[1];
		arg2[5] <= arg1[5] & leq2[1];
		arg2[6] <= arg1[6] & ~leq2[1];
		arg2[7] <= arg1[7] & ~leq2[1];
		arg2[8] <= arg1[8] & leq2[2];
		arg2[9] <= arg1[9] & leq2[2];
		arg2[10] <= arg1[10] & ~leq2[2];
		arg2[11] <= arg1[11] & ~leq2[2];
		arg2[12] <= arg1[12] & leq2[3];
		arg2[13] <= arg1[13] & leq2[3];
		arg2[14] <= arg1[14] & ~leq2[3];
		arg2[15] <= arg1[15] & ~leq2[3];
		
		min2[0] <= leq2[0] ? min1[0] : min1[1];
		min2[1] <= leq2[1] ? min1[2] : min1[3];
		min2[2] <= leq2[2] ? min1[4] : min1[5];
		min2[3] <= leq2[3] ? min1[6] : min1[7]; 		
	end
end

//third layer of comparison
reg [DATA_WIDTH-1:0] min3 [0:1];
reg [0:BLOCKLENGTH-1] arg3;
wire [0:1] leq3;
assign leq3[0] = min2[0] <= min2[1];
assign leq3[1] = min2[2] <= min2[3];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg3 <= 0;
		min3[0] <= 0;
		min3[1] <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg3[0] <= arg2[0] & leq3[0];
		arg3[1] <= arg2[1] & leq3[0];
		arg3[2] <= arg2[2] & leq3[0];
		arg3[3] <= arg2[3] & leq3[0];
		arg3[4] <= arg2[4] & ~leq3[0];
		arg3[5] <= arg2[5] & ~leq3[0];
		arg3[6] <= arg2[6] & ~leq3[0];
		arg3[7] <= arg2[7] & ~leq3[0];
		arg3[8] <= arg2[8] & leq3[1];
		arg3[9] <= arg2[9] & leq3[1];
		arg3[10] <= arg2[10] & leq3[1];
		arg3[11] <= arg2[11] & leq3[1];
		arg3[12] <= arg2[12] & ~leq3[1];
		arg3[13] <= arg2[13] & ~leq3[1];
		arg3[14] <= arg2[14] & ~leq3[1];
		arg3[15] <= arg2[15] & ~leq3[1];		
		
		min3[0] <= leq3[0] ? min2[0] : min2[1];
		min3[1] <= leq3[1] ? min2[2] : min2[3];
	end
end

//fourth layer of comparison
reg [0:BLOCKLENGTH-1] arg4;
wire leq4;
assign leq4 = min3[0] <= min3[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		arg4 <= 0;
	end else if (1'b1 == enable) begin
		//mask off the arg vectors from previous clock cycle
		arg4[0] <= arg3[0] & leq4;
		arg4[1] <= arg3[1] & leq4;
		arg4[2] <= arg3[2] & leq4;
		arg4[3] <= arg3[3] & leq4;
		arg4[4] <= arg3[4] & leq4;
		arg4[5] <= arg3[5] & leq4;
		arg4[6] <= arg3[6] & leq4;
		arg4[7] <= arg3[7] & leq4;
		arg4[8] <= arg3[8] & ~leq4;
		arg4[9] <= arg3[9] & ~leq4;
		arg4[10] <= arg3[10] & ~leq4;
		arg4[11] <= arg3[11] & ~leq4;
		arg4[12] <= arg3[12] & ~leq4;
		arg4[13] <= arg3[13] & ~leq4;
		arg4[14] <= arg3[14] & ~leq4;
		arg4[15] <= arg3[15] & ~leq4;		
	end
end

assign arg = arg4;

endmodule

`endif //_my_arg_min_