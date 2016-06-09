`ifndef _my_centered_decoder_admm_
`define _my_centered_decoder_admm_

/*
Mitch Wasson (mitch.wasson@gmail.com)

*/

`include "2dArrayMacros.v"
`include "CenteredCheckNodeADMM.v"
`include "CenteredVariableNodeADMM.v"
`include "BlockRam.v"

//This ADMM decoder has primal optimization variables centered around 0 instead of 1/2
//The hope is that this will reduce the asymmetry of truncations favouring 0 decodings over 1

//Estimates always have 1 sign bit and zero integer bits because they lie between -1/2 and 1/2
//Can specify the input fraction width. This numbers gives the number of fraction bits
//that the LLR fixed point representation has.
module CenteredDecoderADMM # 
(
	parameter IO_DATA_WIDTH = 8,
	parameter MESSAGE_DATA_WIDTH = IO_DATA_WIDTH + 3,
	parameter IN_FRACTION_WIDTH = 6
) 
(
	input clk,
	input reset,
	input [31:0] numIterations,
	input earlyStopping,
	
	input ready_in,
	input valid_in,
	input signed [MESSAGE_DATA_WIDTH-1:0] penaltyParam, //this is MESSAGE_DATA_WIDTH since it will be an internal parameter in practice. we just want to be able to tune it from pc right now.
	input signed [IO_DATA_WIDTH-1:0] negLLR_in,
	
	output ready_out,
	output valid_out,
	//the esmiates being passed around internally have a couple extra bits. we dont need those for the final estimates
	output signed [IO_DATA_WIDTH-1:0] estimate_out
);
localparam LLR_DATA_WIDTH = IO_DATA_WIDTH;
localparam ESTIMATE_INTEGER_WIDTH = 0; //always between -1/2 and 1/2
localparam ESTIMATE_FRACTION_WIDTH = MESSAGE_DATA_WIDTH - ESTIMATE_INTEGER_WIDTH - 1;

localparam ADDRESS_WIDTH = 32; //change from 32 at great risk! .. seriously... there is a bug

//SPECIFY THE QC-LDPC CODE WITH THESE VARIABLES
localparam RAM_SIZE = 31; //this is the size of the shifted identity matrices in the parity check matrix
localparam CHECK_DEGREE = 5; //also the number of macro columns in parity check matrix
localparam VARIABLE_DEGREE = 3; //also the number of macro rows in parity check matrix
//ram offsets define the shifts in the parity check matrix
wire [CHECK_DEGREE*VARIABLE_DEGREE*ADDRESS_WIDTH-1:0] ramOffsets_in;
wire [ADDRESS_WIDTH-1:0] ramOffsetNums [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
`PACK_ARRAY2(ADDRESS_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,ramOffsetNums,ramOffsets_in,packIndex1,packLoop1)

//4,6 code stuff
/*
//first macro row
assign ramOffsetNums[0] = 0;
assign ramOffsetNums[1] = 0;
assign ramOffsetNums[2] = 0;
assign ramOffsetNums[3] = 0;
assign ramOffsetNums[4] = 0;
assign ramOffsetNums[5] = 0;

//second macro row
assign ramOffsetNums[6] = 0;
assign ramOffsetNums[7] = 13;
assign ramOffsetNums[8] = 25;
assign ramOffsetNums[9] = 9;
assign ramOffsetNums[10] = 29;
assign ramOffsetNums[11] = 14;

//third macro row
assign ramOffsetNums[12] = 0;
assign ramOffsetNums[13] = 28;
assign ramOffsetNums[14] = 5;
assign ramOffsetNums[15] = 13;
assign ramOffsetNums[16] = 10;
assign ramOffsetNums[17] = 6;

//fourth macro row
assign ramOffsetNums[18] = 0;
assign ramOffsetNums[19] = 30;
assign ramOffsetNums[20] = 28;
assign ramOffsetNums[21] = 3;
assign ramOffsetNums[22] = 8;
assign ramOffsetNums[23] = 10;
*/

//Tanner code stuff
//first macro row
assign ramOffsetNums[0] = 30;
assign ramOffsetNums[1] = 29;
assign ramOffsetNums[2] = 27;
assign ramOffsetNums[3] = 23;
assign ramOffsetNums[4] = 15;

//second macro row
assign ramOffsetNums[5] = 26;
assign ramOffsetNums[6] = 21;
assign ramOffsetNums[7] = 11;
assign ramOffsetNums[8] = 22;
assign ramOffsetNums[9] = 13;

//third macro row
assign ramOffsetNums[10] = 6;
assign ramOffsetNums[11] = 12;
assign ramOffsetNums[12] = 24;
assign ramOffsetNums[13] = 17;
assign ramOffsetNums[14] = 3;


//CREATE STATE MACHINE THAT MANAGES THE DECODER
reg [31:0] iterationCounter; //counts how many decoding iterations have occured
reg [ADDRESS_WIDTH-1:0] accessAddress; //the address fed into rams to read and write
reg [1:0] decoderState;
localparam LOAD_STATE = 2'd0; //initial state where decoder loads in LLRs
localparam VARIABLE_COMPUTE = 2'd1; //decoder is doing variable node computations
localparam CHECK_COMPUTE = 2'd2; //decoder is doing check node computations
localparam DONE = 2'd3; //decoder has finished the iterations. valid estimates are in estimate ram

reg messagesRead;

wire variableCalcValid;
wire variablePipelineBusy;
wire variablePipelineReady;
assign variableCalcValid = (decoderState == VARIABLE_COMPUTE) & (~messagesRead) & variablePipelineReady; //still in the process of starting the variable node computations

wire checkCalcValid;
wire checkPipelineBusy;
wire checkPipelineReady;
assign checkCalcValid = (decoderState == CHECK_COMPUTE) & (~messagesRead) & checkPipelineReady;

wire LLRsloaded; //signal from the llr ram saying that all llrs have been loaded

//these variables are used to track if all parity checks are satisfied
reg someCheckNotSatisfied; //this signal is high at the end of the check stage if at least one of the checks wasnt satisfied.
wire someCurrentCheckNotSatisfied; //one of the checks being looked at currently is not satisfied

//state evolution
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		decoderState <= LOAD_STATE;
		iterationCounter <= 0;
		accessAddress <= 0;
		messagesRead <= 0;
		someCheckNotSatisfied <= 1'b0;
	end else begin
		case(decoderState)
			LOAD_STATE:
				if(1'b1 == LLRsloaded) begin
					decoderState <= VARIABLE_COMPUTE;
					iterationCounter <= 0;
					accessAddress <= 0;
					messagesRead <= 1'b0;
				end
				
			VARIABLE_COMPUTE:
				if( messagesRead && 1'b0 == variablePipelineBusy ) begin //all variable computations are done
					if(iterationCounter >= numIterations) begin //we've ran the decoding iterations
						decoderState <= DONE;
					end else begin
						decoderState <= CHECK_COMPUTE;
						accessAddress <= 0;
						messagesRead <= 1'b0;
						someCheckNotSatisfied <= 1'b0;
					end
				end else if (1'b1 == variableCalcValid) begin 
					//advance the counter if a valid entry is being made to pipeline
					//note that this advancement condition caps the accessAddress at RAM_SIZE -1
					if(accessAddress < (RAM_SIZE-1)) begin
						accessAddress <= accessAddress + 1;
					end else begin
						messagesRead <= 1'b1;
					end
				end
				
			CHECK_COMPUTE:
				begin
					//update if the checks are satisfied if the check outputs are valid.
					//automatically say the check is not satisfied if EARLY STOPPING is not configured
					someCheckNotSatisfied <= someCheckNotSatisfied | someCurrentCheckNotSatisfied | (~earlyStopping);
				
					if( messagesRead && 1'b0 == checkPipelineBusy ) begin //all check computations are done at the end of this clock cycle
					
						if(someCheckNotSatisfied) begin
							decoderState <= VARIABLE_COMPUTE;
							accessAddress <= 0;
							iterationCounter <= iterationCounter + 1; //we've completed an iteration
							messagesRead <= 1'b0;
						
						end else begin //early stopping -- all checks are satisfied
							decoderState <= DONE;
						end
					end else if (1'b1 == checkCalcValid) begin
						//advance the counter if a valid entry is being made to pipeline
						//note that this advancement condition caps the accessAddress at RAM_SIZE-1
						if(accessAddress < (RAM_SIZE-1)) begin
							accessAddress <= accessAddress + 1;
						end else begin
							messagesRead <= 1'b1;
						end
					end
				end

			//ONCE WE REACH THE DONE STATE, NOTHING HAPPENS IN THE DECODER
		endcase
	end
end

//INSTANTIATE THE NEG LLR RAM -- A START OF THE VARIABLE PIPELINE
wire llrRamReadBusy;
wire llrRamReadValid;
wire llrRamReadReady;
wire [ADDRESS_WIDTH-1:0] llrRamReadTag;
wire [CHECK_DEGREE*LLR_DATA_WIDTH-1:0] llrRamReadData;

wire allVariablesReady; //downstream signal

NegLLRRam #(	.TAG_WIDTH(ADDRESS_WIDTH),
				.RAM_SIZE(RAM_SIZE),
				.VARIABLE_DEGREE(VARIABLE_DEGREE),
				.CHECK_DEGREE(CHECK_DEGREE),
				.DATA_WIDTH(LLR_DATA_WIDTH)) nLLRram(	clk, reset, LLRsloaded,
													allVariablesReady, variableCalcValid, accessAddress, accessAddress,
													llrRamReadBusy, llrRamReadReady, llrRamReadValid, llrRamReadTag, llrRamReadData,
													valid_in, negLLR_in, ready_out);

//INSTANTIATE THE CHECK MESSAGE RAM -- A START OF THE VARIABLE PIPELINE
wire checkMessageRamReadBusy;
wire checkMessageRamReadReady;
wire checkMessageRamReadValid;
wire [ADDRESS_WIDTH-1:0] checkMessageRamReadTag; //we dont actually use this tag. it will get trimmed.
wire [CHECK_DEGREE*VARIABLE_DEGREE*MESSAGE_DATA_WIDTH-1:0] checkMessageRamReadData;

assign variablePipelineReady = checkMessageRamReadReady & llrRamReadReady;

wire checkMessageRamWriteBusy;
wire checkMessageRamWriteReady;

wire allChecksValid;
wire [ADDRESS_WIDTH-1:0] checkTags [0:VARIABLE_DEGREE-1]; //we only actually use checkTags[0]. The rest of the tag pipelines for these bits should get trimmed.
wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE*CHECK_DEGREE-1:0] checkMessages_flat;

//Rams dont have reset so we just feed in hardwired constants on the first iteration
//Now we initialize check to variable messages to zero
wire [CHECK_DEGREE*VARIABLE_DEGREE*MESSAGE_DATA_WIDTH-1:0] rawCheckMessageRamReadData;
assign checkMessageRamReadData = (0 == iterationCounter) ?  0 : rawCheckMessageRamReadData;

CheckMessageRam #(	.TAG_WIDTH(ADDRESS_WIDTH),
					.RAM_SIZE(RAM_SIZE),
					.VARIABLE_DEGREE(VARIABLE_DEGREE),
					.CHECK_DEGREE(CHECK_DEGREE),
					.DATA_WIDTH(MESSAGE_DATA_WIDTH)) checkMessageRam(	clk, reset, ramOffsets_in,
														allVariablesReady, variableCalcValid, accessAddress, accessAddress,
														checkMessageRamReadBusy, checkMessageRamReadReady, checkMessageRamReadValid, checkMessageRamReadTag, rawCheckMessageRamReadData,
														allChecksValid,  checkTags[0], checkMessages_flat, checkMessageRamWriteBusy, checkMessageRamWriteReady );

//HOOK UP ESTIMATES RAM -- AN END OF THE VARIABLE PIPELINE
wire estimatesValid;
assign estimatesValid = (decoderState == DONE);
wire estimatesRamWriteBusy;
wire estimatesRamWriteReady;

wire allVariablesValid;
wire [ADDRESS_WIDTH-1:0] variableTags [0:CHECK_DEGREE-1]; //we only actually use variableTags[0]. The rest of the tag pipelines for these bits should get trimmed.
wire [MESSAGE_DATA_WIDTH*CHECK_DEGREE-1:0] variableEstimates_flat; //this goes off to the estimates ram write port.
wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE*CHECK_DEGREE-1:0] variableMessages_flat;

wire signed [MESSAGE_DATA_WIDTH-1:0] pre_estimate_out; 
//don't round this. or else early stopping wont work.
assign estimate_out = pre_estimate_out[MESSAGE_DATA_WIDTH-1:MESSAGE_DATA_WIDTH - LLR_DATA_WIDTH];// + {{(LLR_DATA_WIDTH-1){1'b0}},pre_estimate_out[MESSAGE_DATA_WIDTH - LLR_DATA_WIDTH - 1]} ; //only need LLR_DATA_WIDTH bits for the decoder output.

EstimateRam #(	.TAG_WIDTH(ADDRESS_WIDTH),
				.RAM_SIZE(RAM_SIZE),
				.VARIABLE_DEGREE(VARIABLE_DEGREE),
				.CHECK_DEGREE(CHECK_DEGREE),
				.DATA_WIDTH(MESSAGE_DATA_WIDTH)) estimatesram(	clk, reset, estimatesValid,
														ready_in, valid_out, pre_estimate_out,
														allVariablesValid, variableTags[0], variableEstimates_flat,
														estimatesRamWriteBusy, estimatesRamWriteReady);

//HOOK UP VARIABLE MESSAGES RAM
wire allChecksReady;

wire variableMessageRamWriteBusy;
wire variableMessageRamWriteReady;

wire variableMessageRamReadReady;
wire variableMessageRamReadBusy;
wire variableMessageRamReadValid;
wire [MESSAGE_DATA_WIDTH*CHECK_DEGREE*VARIABLE_DEGREE-1:0] variableMessageRamReadData;
wire [ADDRESS_WIDTH-1:0] variableMessageRamReadTag;

VariableMessageRam #(	.TAG_WIDTH(ADDRESS_WIDTH),
						.RAM_SIZE(RAM_SIZE),
						.VARIABLE_DEGREE(VARIABLE_DEGREE),
						.CHECK_DEGREE(CHECK_DEGREE),
						.DATA_WIDTH(MESSAGE_DATA_WIDTH)) variableRam(	clk, reset, ramOffsets_in,
																allChecksReady, checkCalcValid, accessAddress, accessAddress,
																variableMessageRamReadBusy, variableMessageRamReadReady,variableMessageRamReadValid,
																variableMessageRamReadTag, variableMessageRamReadData,
																allVariablesValid, variableTags[0], variableMessages_flat,
																variableMessageRamWriteBusy, variableMessageRamWriteReady);

//INSTANTIATE CHECK STATE RAM
wire checkStateRamReadBusy;
wire checkStateRamReadReady;
wire checkStateRamReadValid;
wire [ADDRESS_WIDTH-1:0] checkStateRamReadTag;
wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE*CHECK_DEGREE-1:0] checkStateRamReadData;

wire checkStateRamWriteBusy;
wire checkStateRamWriteReady;

assign checkPipelineReady = checkStateRamReadReady & variableMessageRamReadReady;

wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE*CHECK_DEGREE-1:0] checkStates_flat;

CheckStateRam #(	.TAG_WIDTH(ADDRESS_WIDTH),
					.RAM_SIZE(RAM_SIZE),
					.VARIABLE_DEGREE(VARIABLE_DEGREE),
					.CHECK_DEGREE(CHECK_DEGREE),
					.DATA_WIDTH(MESSAGE_DATA_WIDTH)) checkStateRam(	clk, reset,
																			allChecksReady, checkCalcValid, accessAddress, accessAddress,
																			checkStateRamReadBusy, checkStateRamReadReady, checkStateRamReadValid,
																			checkStateRamReadTag, checkStateRamReadData,
																			allChecksValid, checkTags[0], checkStates_flat, 
																			checkStateRamWriteBusy, checkStateRamWriteReady);



//INTSTANTIATE VARIABLE NODES
wire [0:CHECK_DEGREE-1] variablesBusy;
wire anyVariablesBusy;
wire [0:CHECK_DEGREE-1] variablesReady;
wire [0:CHECK_DEGREE-1] variablesValid;

wire signed [MESSAGE_DATA_WIDTH-1:0] variableEstimates [0:CHECK_DEGREE-1];
`PACK_ARRAY2(MESSAGE_DATA_WIDTH,CHECK_DEGREE,variableEstimates,variableEstimates_flat,packIndex2,packLoop2)

wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE-1:0] variableMessages [0:CHECK_DEGREE-1]; 
`PACK_ARRAY2(MESSAGE_DATA_WIDTH*VARIABLE_DEGREE,CHECK_DEGREE,variableMessages,variableMessages_flat,packIndex3,packLoop3)

wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE-1:0] checkToVariableMessages [0:CHECK_DEGREE-1]; 
`UNPACK_ARRAY2(MESSAGE_DATA_WIDTH*VARIABLE_DEGREE,CHECK_DEGREE,checkToVariableMessages,checkMessageRamReadData,unpackIndex1,unpackLoop1)

wire signed [LLR_DATA_WIDTH-1:0] llrs [0:CHECK_DEGREE-1]; 
`UNPACK_ARRAY2(LLR_DATA_WIDTH,CHECK_DEGREE,llrs,llrRamReadData,unpackIndex2,unpackLoop2)

assign anyVariablesBusy = |variablesBusy;
assign allVariablesReady = &variablesReady;
assign allVariablesValid = &variablesValid;

//add this logic in to make sure that all the outputs of the variable modules are for the
//same memory read
wire [0:CHECK_DEGREE-2] variableTagAgree;
wire allVarsSynced;
genvar varSycCount;
generate
	for(varSycCount = 0; varSycCount < CHECK_DEGREE-1; varSycCount=varSycCount +1) begin : syncVarLoop
		assign variableTagAgree[varSycCount] = variableTags[varSycCount] == variableTags[varSycCount+1] ;
	end
endgenerate
assign allVarsSynced = &variableTagAgree;

genvar varNode;
generate
	for(varNode = 0; varNode < CHECK_DEGREE; varNode=varNode +1) begin : variableInstantiation
		CenteredVariableNodeADMM_Wrapper #(	.TAG_WIDTH(ADDRESS_WIDTH),
									.BLOCKLENGTH(VARIABLE_DEGREE),
									.LLR_DATA_WIDTH(LLR_DATA_WIDTH),
									.IN_FRACTION_WIDTH(IN_FRACTION_WIDTH),
									.MESSAGE_DATA_WIDTH(MESSAGE_DATA_WIDTH)) variable(	clk, reset, 
																							(variableMessageRamWriteReady & estimatesRamWriteReady & allVarsSynced), (checkMessageRamReadValid & llrRamReadValid), 
																							llrRamReadTag, penaltyParam, llrs[varNode], checkToVariableMessages[varNode],
																							variablesBusy[varNode], variablesReady[varNode], variablesValid[varNode], 
																							variableTags[varNode], variableEstimates[varNode], variableMessages[varNode]);
	end
endgenerate


//INSTANTIATE CHECK NODES
wire [0:VARIABLE_DEGREE-1] checksBusy;
wire anyChecksBusy;
wire [0:VARIABLE_DEGREE-1] checksReady;
wire [0:VARIABLE_DEGREE-1] checksValid;

wire [MESSAGE_DATA_WIDTH*CHECK_DEGREE-1:0] checkMessages [0:VARIABLE_DEGREE-1]; 
`PACK_ARRAY2(MESSAGE_DATA_WIDTH*CHECK_DEGREE,VARIABLE_DEGREE,checkMessages,checkMessages_flat,packIndex4,packLoop4)

wire [MESSAGE_DATA_WIDTH*CHECK_DEGREE-1:0] checkStates [0:VARIABLE_DEGREE-1];
`PACK_ARRAY2(MESSAGE_DATA_WIDTH*CHECK_DEGREE,VARIABLE_DEGREE,checkStates,checkStates_flat,packIndex5,packLoop5)

assign anyChecksBusy = |checksBusy;
assign allChecksReady = &checksReady;
assign allChecksValid = &checksValid;

wire [MESSAGE_DATA_WIDTH*CHECK_DEGREE-1:0] variableToCheckMessages [0:VARIABLE_DEGREE-1]; 
`UNPACK_ARRAY2(MESSAGE_DATA_WIDTH*CHECK_DEGREE,VARIABLE_DEGREE,variableToCheckMessages,variableMessageRamReadData,unpackIndex3,unpackLoop3)


//the initialization of the state variables is 0
wire [MESSAGE_DATA_WIDTH*CHECK_DEGREE-1:0] checkToCheckStates [0:VARIABLE_DEGREE-1]; 
wire [MESSAGE_DATA_WIDTH*VARIABLE_DEGREE*CHECK_DEGREE-1:0] checkStateRamReadData_gen;
assign checkStateRamReadData_gen = (0 == iterationCounter) ?  0 : checkStateRamReadData;
`UNPACK_ARRAY2(MESSAGE_DATA_WIDTH*CHECK_DEGREE,VARIABLE_DEGREE,checkToCheckStates,checkStateRamReadData_gen,unpackIndex4,unpackLoop4)

wire [0:VARIABLE_DEGREE-1]checkNotSatisfied;
assign someCurrentCheckNotSatisfied = |(checkNotSatisfied & checksValid);

//add this logic in to make sure that all the outputs of the check modules are for the
//same memory read
wire [0:VARIABLE_DEGREE-2] checkTagAgree;
wire allChecksSynced;
genvar chkSycCount;
generate
	for(chkSycCount = 0; chkSycCount < VARIABLE_DEGREE-1; chkSycCount=chkSycCount +1) begin : syncCheckLoop
		assign checkTagAgree[chkSycCount] = checkTags[chkSycCount] == checkTags[chkSycCount+1];
	end
endgenerate
assign allChecksSynced = &checkTagAgree;

genvar chkNode;
generate
	for(chkNode = 0; chkNode < VARIABLE_DEGREE; chkNode=chkNode +1) begin : checkInstantiation
		CenteredCheckNodeADMM #( 	.TAG_WIDTH(ADDRESS_WIDTH),
							.BLOCKLENGTH(CHECK_DEGREE),
							.DATA_WIDTH(MESSAGE_DATA_WIDTH),
							.OTHER_FRACTION_WIDTH(IN_FRACTION_WIDTH)) check(	clk, reset,
																				(checkMessageRamWriteReady & checkStateRamWriteReady & allChecksSynced), (checkStateRamReadValid & variableMessageRamReadValid), 
																				checkStateRamReadTag, variableToCheckMessages[chkNode], checkToCheckStates[chkNode],
																				checksBusy[chkNode], checksReady[chkNode], checksValid[chkNode], 
																				checkTags[chkNode], checkNotSatisfied[chkNode], checkMessages[chkNode], checkStates[chkNode]);						
	end
endgenerate


//calculate if the two pipelines are busy
assign variablePipelineBusy =  llrRamReadBusy | checkMessageRamReadBusy | anyVariablesBusy | estimatesRamWriteBusy | variableMessageRamWriteBusy;
assign checkPipelineBusy = variableMessageRamReadBusy | checkStateRamReadBusy | anyChecksBusy | checkMessageRamWriteBusy | checkStateRamWriteBusy;


endmodule


`endif //_my_centered_decoder_admm_