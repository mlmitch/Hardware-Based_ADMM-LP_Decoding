`ifndef _my_centered_variable_node_admm_
`define _my_centered_variable_node_admm_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the variable node operation for ADMM LP decoding.
It takes in a single log likelihood ratio, an array of messages in,
and outputs the current variable estimate.

The llr input is supposed to be the negative llr.
This means <0 for observed 0 and >0 for observed 1.

LLR and messages have the same fraction with. However, messages have
a bigger data width to give some more dynamic range to override the
LLRs. We have two basic data widths. The data width of the channel information
and the data width of messages passed.

Estimate has 0 integer bits since always between -1/2 and 1/2
*/

`include "2dArrayMacros.v"
`include "Summer.v"
`include "Normalize.v"
`include "CenteredProjectBox.v"
`include "CenteredVariableNodePenalty.v"

module CenteredVariableNodeADMM # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 3, 
	parameter LLR_DATA_WIDTH = 12,
	parameter IN_FRACTION_WIDTH = LLR_DATA_WIDTH - 1,
	parameter MESSAGE_DATA_WIDTH = LLR_DATA_WIDTH + 3
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input signed [MESSAGE_DATA_WIDTH-1:0] penaltyParam,
	input signed [LLR_DATA_WIDTH-1:0] negLLR_in,
	input [MESSAGE_DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output signed [MESSAGE_DATA_WIDTH-1:0] data_out	
);
localparam ESTIMATE_DATA_WIDTH = MESSAGE_DATA_WIDTH;
localparam LLR_INTEGER_WIDTH = LLR_DATA_WIDTH - IN_FRACTION_WIDTH - 1;
localparam MESSAGE_INTEGER_WIDTH = MESSAGE_DATA_WIDTH - IN_FRACTION_WIDTH - 1;
localparam ESTIMATE_FRACTION_WIDTH = ESTIMATE_DATA_WIDTH - 1;
localparam ESTIMATE_INTEGER_WIDTH = ESTIMATE_DATA_WIDTH - ESTIMATE_FRACTION_WIDTH - 1; // = 0

//PREDECLARE READY SIGNALS
wire sumReady;
wire penReady;
wire normReady;
wire boxProjReady;

//PERFORM SUM OF INPUTS
localparam SUM_INTEGER_WIDTH = MESSAGE_INTEGER_WIDTH + log2(BLOCKLENGTH+1); //+1 because we add the llr to the sum 
localparam SUM_FRACTION_WIDTH = IN_FRACTION_WIDTH; 
localparam SUM_DATA_WIDTH = SUM_INTEGER_WIDTH + SUM_FRACTION_WIDTH + 1; 

//extend the inputs to have matching representations
wire signed [MESSAGE_DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(MESSAGE_DATA_WIDTH,BLOCKLENGTH,in,data_in,unpackIndex1,unpackLoop1)
wire signed [SUM_DATA_WIDTH-1:0] sumIn [0:BLOCKLENGTH];
genvar j;
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : sumExtend_loop
		assign sumIn[j] = {{(SUM_INTEGER_WIDTH - MESSAGE_INTEGER_WIDTH){in[j][MESSAGE_DATA_WIDTH-1]}},in[j]}; //sign extend log2(BLOCKLENGTH+1) bits
	end
	
	assign sumIn[BLOCKLENGTH] = {{(SUM_INTEGER_WIDTH - LLR_INTEGER_WIDTH){negLLR_in[LLR_DATA_WIDTH-1]}},negLLR_in}; //sign extend the llr
endgenerate
wire [SUM_DATA_WIDTH*(BLOCKLENGTH+1)-1:0] sumIn_flat;
`PACK_ARRAY2(SUM_DATA_WIDTH,(BLOCKLENGTH+1),sumIn,sumIn_flat,packIndex1,packLoop1)

wire sumBusy;
wire sumValid;
wire [TAG_WIDTH-1:0] sumTag_out;
wire signed [SUM_DATA_WIDTH-1:0] sumValue;

PipelineSummer #( 
	.TAG_WIDTH(TAG_WIDTH), 
	.BLOCKLENGTH((BLOCKLENGTH+1)),
	.DATA_WIDTH(SUM_DATA_WIDTH)) sum(clk, reset, penReady, valid_in, tag_in, sumIn_flat,
												sumBusy, sumReady, sumValid, sumTag_out, sumValue);

//APPLY PENALIZATION
localparam PENALTY_INTEGER_WIDTH = SUM_INTEGER_WIDTH + 1;
localparam PENALTY_FRACTION_WIDTH = SUM_FRACTION_WIDTH;
localparam PENALTY_DATA_WIDTH = PENALTY_INTEGER_WIDTH + PENALTY_FRACTION_WIDTH + 1;

wire penBusy;
wire penValid;
wire [TAG_WIDTH-1:0] penTag_out;
wire signed [PENALTY_DATA_WIDTH-1:0] extSumValue;
wire signed [PENALTY_DATA_WIDTH-1:0] extPenParam;
wire signed [PENALTY_DATA_WIDTH-1:0] penalizedSum;

assign extSumValue = {sumValue[SUM_DATA_WIDTH-1],sumValue}; //add that extra bit
assign extPenParam = { {(PENALTY_INTEGER_WIDTH - MESSAGE_INTEGER_WIDTH){penaltyParam[MESSAGE_DATA_WIDTH-1]}}, penaltyParam};

CenteredVariableNodeL1Penalty #( 
	.TAG_WIDTH(TAG_WIDTH),
	.DATA_WIDTH(PENALTY_DATA_WIDTH),
	.FRACTION_WIDTH(PENALTY_FRACTION_WIDTH)) penMod(clk, reset, normReady, sumValid, sumTag_out, extSumValue, extPenParam,
									 		penBusy, penReady, penValid, penTag_out, penalizedSum);


//NORMALIZE THE SUM NOW
localparam NORM_DATA_WIDTH = 2*PENALTY_DATA_WIDTH; 
localparam NORM_FRACTION_WIDTH = PENALTY_FRACTION_WIDTH + (PENALTY_DATA_WIDTH-1); 
localparam NORM_INTEGER_WIDTH = NORM_DATA_WIDTH - NORM_FRACTION_WIDTH - 1; //this is at least 1

wire normBusy;
wire normValid;
wire [TAG_WIDTH-1:0] normTag_out;
wire signed [NORM_DATA_WIDTH-1:0] normedSum;

SingleNormalize #( 
	.TAG_WIDTH(TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(PENALTY_DATA_WIDTH)) norm(clk, reset, boxProjReady, penValid, penTag_out, penalizedSum,
									 	normBusy, normReady, normValid, normTag_out, normedSum);

//PROJECT THE NORMALIZATION ONTO THE UNIT BOX
wire boxProjBusy;
wire [NORM_DATA_WIDTH-1:0] boxProj_out;

//PROJ_FRACTION_WIDTH is guaranteed >= NORM_FRACTION_WIDTH
//since the normed value has at least one integer bit
localparam PROJ_FRACTION_WIDTH = NORM_DATA_WIDTH - ESTIMATE_INTEGER_WIDTH - 1;

//this projects on the -1/2 to 1/2 box
CenteredProjectBox #( 
	.TAG_WIDTH(TAG_WIDTH),
	.BLOCKLENGTH(1), //only one value to project
	.DATA_WIDTH(NORM_DATA_WIDTH),
	.IN_FRACTION_WIDTH(NORM_FRACTION_WIDTH)) boxProj(clk, reset, ready_in, normValid, normTag_out, normedSum,
														boxProjBusy, boxProjReady, valid_out, tag_out, boxProj_out);


assign ready_out = sumReady;
assign busy = sumBusy | penBusy | normBusy | boxProjBusy;
assign data_out = boxProj_out[NORM_DATA_WIDTH-1:NORM_DATA_WIDTH-MESSAGE_DATA_WIDTH]; //only want the most significant bits from the box projection


//constant function that calculates ceil(log2())
function integer log2;
	input integer value;
	begin
		value = value-1;
		for (log2=0; value>0; log2=log2+1) begin
			value = value>>1;
		end
	end
endfunction

endmodule


module CenteredVariableNodeADMM_Wrapper # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 3, 
	parameter LLR_DATA_WIDTH = 12,
	parameter IN_FRACTION_WIDTH = LLR_DATA_WIDTH - 2,
	parameter MESSAGE_DATA_WIDTH = LLR_DATA_WIDTH + 3
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input signed [MESSAGE_DATA_WIDTH-1:0] penaltyParam,
	input signed [LLR_DATA_WIDTH-1:0] negLLR_in,
	input [MESSAGE_DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output signed [MESSAGE_DATA_WIDTH-1:0] estimate,
	output [MESSAGE_DATA_WIDTH*BLOCKLENGTH-1:0] messages	
);

wire signed [MESSAGE_DATA_WIDTH-1:0] innerEstimate;

CenteredVariableNodeADMM #(	.TAG_WIDTH(TAG_WIDTH),
					.BLOCKLENGTH(BLOCKLENGTH),
					.LLR_DATA_WIDTH(LLR_DATA_WIDTH),
					.IN_FRACTION_WIDTH(IN_FRACTION_WIDTH),
					.MESSAGE_DATA_WIDTH(MESSAGE_DATA_WIDTH)) v(	clk, reset, 
																ready_in, valid_in, tag_in, penaltyParam, negLLR_in, data_in,
																busy, ready_out, valid_out, tag_out, innerEstimate);

assign estimate = innerEstimate;

genvar i;
generate
	for(i=0; i<BLOCKLENGTH; i=i+1) begin : filler
		//all messages are the same for admm.
		assign messages[MESSAGE_DATA_WIDTH*i + (MESSAGE_DATA_WIDTH-1):MESSAGE_DATA_WIDTH*i] =  innerEstimate;
	end
endgenerate

endmodule


`endif //_my_centered_variable_node_admm_