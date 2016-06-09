`ifndef _my_centered_check_node_admm_
`define _my_centered_check_node_admm_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the check node operation for ADMM LP decoding.
It takes in array of messages from variable nodes as well as the dual
variable state. Outputs array of messages to variables and new dual variable state.
Messages from variable must be centered on 0.

*/

`include "2dArrayMacros.v"
`include "Summer.v"
`include "CenteredProjectParityPolytope.v"
`include "VectorFormat.v"
`include "WagnerRule.v"

module CenteredCheckNodeADMM # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter DATA_WIDTH = 8,
	//fraction width for all other things..assuming estimate in integer width is 0.
	parameter OTHER_FRACTION_WIDTH = 6 
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] messages_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] duals_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output checkNotSatisfied, 
	output [DATA_WIDTH*BLOCKLENGTH-1:0] messages_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] duals_out
);
localparam MI_FRACTION_WIDTH = DATA_WIDTH-1;
localparam MI_INTEGER_WIDTH = DATA_WIDTH - MI_FRACTION_WIDTH - 1;
localparam OTHER_INTEGER_WIDTH = DATA_WIDTH - OTHER_FRACTION_WIDTH - 1;

wire inSumReady;
wire ppProjectReady;
wire dualUpdateReady;
wire messageOutReady;
wire dualTrimReady;
wire messageTrimReady;

//ADD DUALS TO MESSAGES IN
//also check if the check is satisfied.

//first put duals and messages in same format.
localparam IN_SUM_INTEGER_WIDTH = OTHER_INTEGER_WIDTH + 1; 
localparam IN_SUM_FRACTION_WIDTH = MI_FRACTION_WIDTH; 
localparam IN_SUM_DATA_WIDTH = IN_SUM_INTEGER_WIDTH + IN_SUM_FRACTION_WIDTH + 1;

wire signed [DATA_WIDTH-1:0] messageIn [0:BLOCKLENGTH-1];
wire signed [DATA_WIDTH-1:0] dualIn [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,messageIn,messages_in,unpackIndex1,unpackLoop1)
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,dualIn,duals_in,unpackIndex2,unpackLoop2)

wire signed [IN_SUM_DATA_WIDTH-1:0] messageInExt [0:BLOCKLENGTH-1];
wire signed [IN_SUM_DATA_WIDTH-1:0] dualInExt [0:BLOCKLENGTH-1];
genvar j;
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : sumExtend_loop
		//messages in
		assign messageInExt[j] = {{(IN_SUM_INTEGER_WIDTH - MI_INTEGER_WIDTH){messageIn[j][DATA_WIDTH-1]}}, messageIn[j]};

		//duals
		if(IN_SUM_FRACTION_WIDTH > OTHER_FRACTION_WIDTH) begin
			assign dualInExt[j] = {{(IN_SUM_INTEGER_WIDTH - OTHER_INTEGER_WIDTH){dualIn[j][DATA_WIDTH-1]}}, dualIn[j], {(IN_SUM_FRACTION_WIDTH-OTHER_FRACTION_WIDTH){1'b0}}};
		end else begin
			assign dualInExt[j] = {{(IN_SUM_INTEGER_WIDTH - OTHER_INTEGER_WIDTH){dualIn[j][DATA_WIDTH-1]}}, dualIn[j]};
		end
	end
endgenerate

wire [IN_SUM_DATA_WIDTH*BLOCKLENGTH-1:0] messageInExt_flat;
wire [IN_SUM_DATA_WIDTH*BLOCKLENGTH-1:0] dualInExt_flat;
`PACK_ARRAY2(IN_SUM_DATA_WIDTH,BLOCKLENGTH,messageInExt,messageInExt_flat,packIndex1,packLoop1)
`PACK_ARRAY2(IN_SUM_DATA_WIDTH,BLOCKLENGTH,dualInExt,dualInExt_flat,packIndex2,packLoop2)

//seeing if the check is satisfied
wire [0:BLOCKLENGTH-1] bitValues;
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : createBits_loop
		assign bitValues[j] = ~messageIn[j][DATA_WIDTH-1]; //-1/2 corresponds to 0...take sign bit then not it to get a hard decision
	end
endgenerate
wire immediateCheckNotSatisfied;
assign immediateCheckNotSatisfied = ^bitValues; //XOR together all the bit values. if non-zero, then check isnt satisfied.

//instantiate sum module
localparam IN_SUM_TAG_WIDTH = TAG_WIDTH+1; //adding the check not satisfied bit.
wire inSumBusy;
wire inSumValid;
wire [IN_SUM_DATA_WIDTH*BLOCKLENGTH-1:0] inSumDataOut_flat;
wire [IN_SUM_TAG_WIDTH-1:0] inSumTag_in;
wire [IN_SUM_TAG_WIDTH-1:0] inSumTag_out;

assign inSumTag_in = {tag_in,immediateCheckNotSatisfied};

VectorSummer #( 
	.TAG_WIDTH(IN_SUM_TAG_WIDTH), 
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(IN_SUM_DATA_WIDTH)) inSum(clk, reset, ppProjectReady, valid_in, inSumTag_in, messageInExt_flat, dualInExt_flat,
												inSumBusy, inSumReady, inSumValid, inSumTag_out, inSumDataOut_flat);


//PERFORM PARITY POLYTOPE PROJECTION
localparam PP_PROJECT_TAG_WIDTH = IN_SUM_TAG_WIDTH + IN_SUM_DATA_WIDTH*BLOCKLENGTH; //need the initial addition for output calculation later

//instantiate projection module
wire ppProjectBusy;
wire ppProjectValid;
wire [PP_PROJECT_TAG_WIDTH-1:0] ppProjectTag_in;
wire [PP_PROJECT_TAG_WIDTH-1:0] ppProjectTag_out;

assign ppProjectTag_in = {inSumTag_out, inSumDataOut_flat};

wire [IN_SUM_DATA_WIDTH*BLOCKLENGTH-1:0] ppProjectDataOut_flat;

CenteredProjectParityPolytope #( 
	.TAG_WIDTH(PP_PROJECT_TAG_WIDTH), 
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(IN_SUM_DATA_WIDTH),
	.IN_FRACTION_WIDTH(IN_SUM_FRACTION_WIDTH)) ppProject(clk, reset, (messageOutReady & dualUpdateReady), inSumValid, ppProjectTag_in, inSumDataOut_flat,
														ppProjectBusy, ppProjectReady, ppProjectValid, ppProjectTag_out, ppProjectDataOut_flat);

//crude approximation of polytope projection which fails horribly.
/*CenteredWagnerRule #( 
	.TAG_WIDTH(PP_PROJECT_TAG_WIDTH), 
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(IN_SUM_DATA_WIDTH),
	.IN_FRACTION_WIDTH(IN_SUM_FRACTION_WIDTH)) ppProject(clk, reset, (messageOutReady & dualUpdateReady), inSumValid, ppProjectTag_in, inSumDataOut_flat,
														ppProjectBusy, ppProjectReady, ppProjectValid, ppProjectTag_out, ppProjectDataOut_flat);
*/

//The output integer width of the parity polytope projection is 0 since it is in the -1/2 to 1/2 unit cube
														
//PERFORM THE MESSAGE SUM AND DUAL VARIABLE SUM IN PARALLEL -- CALLS TWO SEPARATE VectorSummer MODULES WITH SAME PIPELINE CONTROLS
//FIRST THE DUAL VARIABLE UPDATE.

//make data available from previous module
wire [IN_SUM_DATA_WIDTH*BLOCKLENGTH-1:0] storedInSum_flat;
assign storedInSum_flat = ppProjectTag_out[IN_SUM_DATA_WIDTH*BLOCKLENGTH-1:0];
wire [IN_SUM_TAG_WIDTH-1:0] outSumTag_in;
assign outSumTag_in = ppProjectTag_out[PP_PROJECT_TAG_WIDTH-1:IN_SUM_DATA_WIDTH*BLOCKLENGTH];
wire [IN_SUM_TAG_WIDTH-1:0] outSumTag_out;

wire signed [IN_SUM_DATA_WIDTH-1:0] storedInSum [0:BLOCKLENGTH-1];
wire signed [IN_SUM_DATA_WIDTH-1:0] projection [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(IN_SUM_DATA_WIDTH,BLOCKLENGTH,storedInSum,storedInSum_flat,unpackIndex3,unpackLoop3)
`UNPACK_ARRAY2(IN_SUM_DATA_WIDTH,BLOCKLENGTH,projection,ppProjectDataOut_flat,unpackIndex4,unpackLoop4)

//first the dual update ---------------
//put in addition and projection into same format.
localparam DUAL_UPDATE_FRACTION_WIDTH = IN_SUM_DATA_WIDTH - 1; //the output fraction width of the projection will never be smaller.
localparam DUAL_UPDATE_INTEGER_WIDTH = IN_SUM_INTEGER_WIDTH + 1; //add another bit to prevent overflow
localparam DUAL_UPDATE_DATA_WIDTH = DUAL_UPDATE_FRACTION_WIDTH + DUAL_UPDATE_INTEGER_WIDTH + 1;

wire signed [DUAL_UPDATE_DATA_WIDTH-1:0] storedInSum_dualExt [0:BLOCKLENGTH-1];
wire signed [DUAL_UPDATE_DATA_WIDTH-1:0] projection_dualExt [0:BLOCKLENGTH-1];
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : dualUpdateExtend_loop
		//projection integer width is 1
		//we subtract the projection from the initial sum. so extend then take negative
		//shouldn't be overflow since we just added at least one integer bit.
		//again we extend here assuming 0 integer bits on the projection
		assign projection_dualExt[j] = -{{(DUAL_UPDATE_INTEGER_WIDTH ){projection[j][IN_SUM_DATA_WIDTH-1]}}, projection[j]};

		//stored sum
		if(DUAL_UPDATE_FRACTION_WIDTH > IN_SUM_FRACTION_WIDTH) begin
			assign storedInSum_dualExt[j] = {{(DUAL_UPDATE_INTEGER_WIDTH - IN_SUM_INTEGER_WIDTH){storedInSum[j][IN_SUM_DATA_WIDTH-1]}}, storedInSum[j], {(DUAL_UPDATE_FRACTION_WIDTH-IN_SUM_FRACTION_WIDTH){1'b0}}};
		end else begin
			assign storedInSum_dualExt[j] = {{(DUAL_UPDATE_INTEGER_WIDTH - IN_SUM_INTEGER_WIDTH){storedInSum[j][IN_SUM_DATA_WIDTH-1]}}, storedInSum[j]};
		end
	end
endgenerate
wire [DUAL_UPDATE_DATA_WIDTH*BLOCKLENGTH-1:0] storedInSum_dualExt_flat;
wire [DUAL_UPDATE_DATA_WIDTH*BLOCKLENGTH-1:0] projection_dualExt_flat;
`PACK_ARRAY2(DUAL_UPDATE_DATA_WIDTH,BLOCKLENGTH,storedInSum_dualExt,storedInSum_dualExt_flat,packIndex3,packLoop3)
`PACK_ARRAY2(DUAL_UPDATE_DATA_WIDTH,BLOCKLENGTH,projection_dualExt,projection_dualExt_flat,packIndex4,packLoop4)

//instantiate the sum now
wire dualUpdateBusy;
wire dualUpdateValid;

wire [DUAL_UPDATE_DATA_WIDTH*BLOCKLENGTH-1:0] dualUpdate_out;

VectorSummer #( 
	.TAG_WIDTH(IN_SUM_TAG_WIDTH), 
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(DUAL_UPDATE_DATA_WIDTH)) dualUpdate(clk, reset, (messageTrimReady & dualTrimReady), ppProjectValid, outSumTag_in, storedInSum_dualExt_flat, projection_dualExt_flat,
												dualUpdateBusy, dualUpdateReady, dualUpdateValid, outSumTag_out, dualUpdate_out);

//now the message out calculation -------- 
localparam TWICE_PROJECTION_INTEGER_WIDTH = 1; //assuming 0 integer bits on projection output
localparam TWICE_PROJECTION_FRACTION_WIDTH = IN_SUM_DATA_WIDTH - TWICE_PROJECTION_INTEGER_WIDTH - 1;

//this is a little messy since we don't have guarantees on which one has the bigger inter width
//will still probably be the in sum but we don't know for sure
localparam MESSAGE_OUT_FRACTION_WIDTH = (TWICE_PROJECTION_FRACTION_WIDTH > IN_SUM_FRACTION_WIDTH) ? TWICE_PROJECTION_FRACTION_WIDTH : IN_SUM_FRACTION_WIDTH;
localparam MESSAGE_OUT_INTEGER_WIDTH = (TWICE_PROJECTION_INTEGER_WIDTH > IN_SUM_INTEGER_WIDTH) ? TWICE_PROJECTION_INTEGER_WIDTH + 1 : IN_SUM_INTEGER_WIDTH + 1; //add another bit to prevent overflow
localparam MESSAGE_OUT_DATA_WIDTH = MESSAGE_OUT_FRACTION_WIDTH + MESSAGE_OUT_INTEGER_WIDTH + 1;

wire signed [DUAL_UPDATE_DATA_WIDTH-1:0] storedInSum_messageExt [0:BLOCKLENGTH-1];
wire signed [DUAL_UPDATE_DATA_WIDTH-1:0] projection_messageExt [0:BLOCKLENGTH-1];
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : messageOutExtend_loop
		//projection
		if(MESSAGE_OUT_FRACTION_WIDTH > TWICE_PROJECTION_FRACTION_WIDTH) begin
			assign projection_messageExt[j] = {{(MESSAGE_OUT_INTEGER_WIDTH - TWICE_PROJECTION_INTEGER_WIDTH){projection[j][IN_SUM_DATA_WIDTH-1]}}, projection[j], {(MESSAGE_OUT_FRACTION_WIDTH-TWICE_PROJECTION_FRACTION_WIDTH){1'b0}}};
		end else begin
			assign projection_messageExt[j] = {{(MESSAGE_OUT_INTEGER_WIDTH - TWICE_PROJECTION_INTEGER_WIDTH){projection[j][IN_SUM_DATA_WIDTH-1]}}, projection[j]};
		end

		//stored sum
		//we subtract the initial sum from twice the projection. so extend then take negative
		//shouldn't be overflow since we just added at least one integer bit.
		if(MESSAGE_OUT_FRACTION_WIDTH > IN_SUM_FRACTION_WIDTH) begin
			assign storedInSum_messageExt[j] = -{{(MESSAGE_OUT_INTEGER_WIDTH - IN_SUM_INTEGER_WIDTH){storedInSum[j][IN_SUM_DATA_WIDTH-1]}}, storedInSum[j], {(MESSAGE_OUT_FRACTION_WIDTH-IN_SUM_FRACTION_WIDTH){1'b0}}};
		end else begin
			assign storedInSum_messageExt[j] = -{{(MESSAGE_OUT_INTEGER_WIDTH - IN_SUM_INTEGER_WIDTH){storedInSum[j][IN_SUM_DATA_WIDTH-1]}}, storedInSum[j]};
		end
	end
endgenerate
wire [MESSAGE_OUT_DATA_WIDTH*BLOCKLENGTH-1:0] storedInSum_messageExt_flat;
wire [MESSAGE_OUT_DATA_WIDTH*BLOCKLENGTH-1:0] projection_messageExt_flat;
`PACK_ARRAY2(MESSAGE_OUT_DATA_WIDTH,BLOCKLENGTH,storedInSum_messageExt,storedInSum_messageExt_flat,packIndex5,packLoop5)
`PACK_ARRAY2(MESSAGE_OUT_DATA_WIDTH,BLOCKLENGTH,projection_messageExt,projection_messageExt_flat,packIndex6,packLoop6)

//instantiate the sum now
wire messageOutBusy;
wire messageOutValid;
wire messageOutTagOut_dummy;

wire [MESSAGE_OUT_DATA_WIDTH*BLOCKLENGTH-1:0] messageOut_out;

VectorSummer #( 
	.TAG_WIDTH(1), 
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(MESSAGE_OUT_DATA_WIDTH)) messageOut(clk, reset, (messageTrimReady & dualTrimReady), ppProjectValid, 1'b0, storedInSum_messageExt_flat, projection_messageExt_flat,
												messageOutBusy, messageOutReady, messageOutValid, messageOutTagOut_dummy, messageOut_out);

//NOW TRIM THE OUTPUT VECTORS INTO THE APPROPIATE RANGE
//We know the output integer widths are less than the input integer widths

//duals
wire dualTrimBusy;
wire dualTrimValid;
wire [IN_SUM_TAG_WIDTH-1:0] trimTag_out;

VectorTrim #(
		.TAG_WIDTH(IN_SUM_TAG_WIDTH),
		.BLOCKLENGTH(BLOCKLENGTH),
		.IN_DATA_WIDTH(DUAL_UPDATE_DATA_WIDTH),
		.IN_FRACTION_WIDTH(DUAL_UPDATE_FRACTION_WIDTH),
		.OUT_DATA_WIDTH(DATA_WIDTH),
		.OUT_FRACTION_WIDTH(OTHER_FRACTION_WIDTH)) dualOutTrim(clk, reset, ready_in, (dualUpdateValid & messageOutValid), outSumTag_out, dualUpdate_out,
														dualTrimBusy, dualTrimReady, dualTrimValid, trimTag_out, duals_out);


//selecting the tag out and check satisfied bit
assign tag_out = trimTag_out[IN_SUM_TAG_WIDTH-1:1];
assign checkNotSatisfied = trimTag_out[0];

//messages
wire messageTrimBusy;
wire messageTrimValid;
wire messageTrimTagOut_dummy;

VectorTrim #(
		.TAG_WIDTH(1),
		.BLOCKLENGTH(BLOCKLENGTH),
		.IN_DATA_WIDTH(MESSAGE_OUT_DATA_WIDTH),
		.IN_FRACTION_WIDTH(MESSAGE_OUT_FRACTION_WIDTH),
		.OUT_DATA_WIDTH(DATA_WIDTH),
		.OUT_FRACTION_WIDTH(OTHER_FRACTION_WIDTH)) messageOutTrim(clk, reset, ready_in, (dualUpdateValid & messageOutValid), messageOutTagOut_dummy, messageOut_out,
														messageTrimBusy, messageTrimReady, messageTrimValid, messageTrimTagOut_dummy, messages_out);


assign valid_out = messageTrimValid & dualTrimValid;
assign busy = inSumBusy | ppProjectBusy | dualUpdateBusy | messageOutBusy | dualTrimBusy | messageTrimBusy;
assign ready_out = inSumReady;

endmodule


`endif //_my_centered_check_node_admm_