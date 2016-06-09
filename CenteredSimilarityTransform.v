`ifndef _my_centered_similarity_transform_
`define _my_centered_similarity_transform_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module takes in an array of signed integers and performs the parity polytope projection similarity 
transform using f to define the transform.

Doing this for the centered parity polytope projection though.

we assume the fixed point representation has at least one integer bit.
we also assume that the input vector does not contain components that are 
the most negative number.
*/

`include "2dArrayMacros.v"

module CenteredSimilarityTransform # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	input [0:BLOCKLENGTH-1] f,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out	
);
localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);


wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg [0:BLOCKLENGTH-1] fReg0;

//BRING IN INPUT
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= in[i];
		end
	end
end
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		fReg0 <= 0;
	end else if (1'b1 == enable) begin
		fReg0 <= f;
	end
end

//PERFORM THE TRANSFORMATION
//way simpler now that it is centered around 0.
reg signed [DATA_WIDTH-1:0] transform [0:BLOCKLENGTH-1];

always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			transform[i] <= 0;
		end else if (1'b1 == enable) begin
			transform[i] <= fReg0[i] ? -reg0[i] : reg0[i];
		end
	end
end

`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,transform,data_out)

endmodule



`endif //_my_centered_similarity_transform_