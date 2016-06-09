`ifndef _my_centered_variable_node_penalty_
`define _my_centered_variable_node_penalty_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs L1 penalization when enabled in the admm decoding.
basically looks at the prepenalty and decides whether to add or subtract the 
penalty parameter.
*/

`include "2dArrayMacros.v"

module CenteredVariableNodeL1Penalty # 
(
	parameter TAG_WIDTH = 32,
	parameter DATA_WIDTH = 18,
	parameter FRACTION_WIDTH = 10
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input signed [DATA_WIDTH-1:0] prePenalty,
	input signed [DATA_WIDTH-1:0] penaltyParam, //assumed to be a positive number
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output signed [DATA_WIDTH-1:0] postPenalty	
);
localparam NUM_REGISTERS = 3;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(clk, reset, valid_in, ready_in, tag_in,
														valid_out, ready_out, busy, enable, tag_out);


localparam THRESHOLD = 0; //now that we are centered around 0, the thresholding operation is much simpler
		
//capture input											
reg signed [DATA_WIDTH-1:0] capturedPrePenalty;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		capturedPrePenalty <= 0;
	end else if (1'b1 == enable) begin
		capturedPrePenalty <= prePenalty;
	end
end

//choose the penalty that will take place
reg signed [DATA_WIDTH-1:0] penaltyAddition;
reg signed [DATA_WIDTH-1:0] capturedPrePenalty2;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		penaltyAddition <= 0;
		capturedPrePenalty2 <= 0;
	end else if (1'b1 == enable) begin
		penaltyAddition <= (capturedPrePenalty >= THRESHOLD) ? penaltyParam : -penaltyParam;
		capturedPrePenalty2 <= capturedPrePenalty;
	end
end

//apply the penalty
reg signed [DATA_WIDTH-1:0] penalized;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		penalized <= 0;
	end else if (1'b1 == enable) begin
		penalized <= capturedPrePenalty2 + penaltyAddition;
	end
end
assign postPenalty = penalized;

endmodule


`endif //_my_centered_variable_node_penalty_