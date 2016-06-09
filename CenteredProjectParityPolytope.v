`ifndef _my_centered_project_parity_polytope_
`define _my_centered_project_parity_polytope_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the projection onto the parity polytope centered at the origin

output is assumed to have 0 integer bits.
*/

`include "2dArrayMacros.v"
`include "CenteredProjectBox.v"
`include "CenteredCutSearch.v"
`include "CenteredSimilarityTransform.v"
`include "CenteredSelectionTest.v"
`include "OutSelect.v"

module CenteredProjectParityPolytope # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter DATA_WIDTH = 8,
	parameter IN_FRACTION_WIDTH = 6
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out	
);
localparam OUT_FRACTION_WIDTH = DATA_WIDTH - 1;

wire inBoxProjReady;
wire cutSearchReady;
wire simTranOneReady;
wire simpProjReady;
wire simTranTwoReady;
wire boxProjTwoReady;
wire selectTestReady;
wire outSelectReady;

//FIRST STEP - Project input onto unit box
localparam IN_BOX_PROJ_TAG_WIDTH = TAG_WIDTH + BLOCKLENGTH*DATA_WIDTH; //we need the original vector later

wire inBoxProjBusy;
wire inBoxProjValid;
wire [IN_BOX_PROJ_TAG_WIDTH-1:0] inBoxProjTag_out;
wire [IN_BOX_PROJ_TAG_WIDTH-1:0] inBoxProjTag_in;
wire [DATA_WIDTH*BLOCKLENGTH-1:0] inBoxProjData_out;
assign inBoxProjTag_in = {tag_in, data_in}; //need original vector later

CenteredProjectBox #( 
	.TAG_WIDTH(IN_BOX_PROJ_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(DATA_WIDTH),
	.IN_FRACTION_WIDTH(IN_FRACTION_WIDTH)) boxProj(clk, reset, cutSearchReady, valid_in, inBoxProjTag_in, data_in,
													inBoxProjBusy, inBoxProjReady, inBoxProjValid, inBoxProjTag_out, inBoxProjData_out);
																	
//FIND THE TRANSFORM DEFINING VECTOR WITH CUT SEARCH METHOD
localparam CUT_SEARCH_TAG_WIDTH = IN_BOX_PROJ_TAG_WIDTH + BLOCKLENGTH*DATA_WIDTH;

wire cutSearchBusy;
wire cutSearchValid;
wire [CUT_SEARCH_TAG_WIDTH-1:0] cutSearchTag_out;
wire [CUT_SEARCH_TAG_WIDTH-1:0] cutSearchTag_in;
wire [0:BLOCKLENGTH-1] cutSearchData_out;
assign cutSearchTag_in = {inBoxProjTag_out, inBoxProjData_out}; //need box proj vector later

//.IN_FRACTION_WIDTH(OUT_FRACTION_WIDTH) since the box projection has 0 integer bits.
CenteredCutSearch #( 
	.TAG_WIDTH(CUT_SEARCH_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(DATA_WIDTH),
	.IN_FRACTION_WIDTH(OUT_FRACTION_WIDTH)) cutSearch(clk, reset, simTranOneReady, inBoxProjValid, cutSearchTag_in, inBoxProjData_out,
																	cutSearchBusy, cutSearchReady, cutSearchValid, cutSearchTag_out, cutSearchData_out);


//PERFORM THE FIRST SIMILARITY TRANSFORM
localparam SIM_TRAN_ONE_TAG_WIDTH = CUT_SEARCH_TAG_WIDTH - BLOCKLENGTH*DATA_WIDTH + BLOCKLENGTH; //we're extracting the input vector and putting the cut vector in
localparam SIM_TRAN_ONE_DATA_WIDTH = DATA_WIDTH+1;

//extract input vector from tag and sign extend a bit onto it for the transformation
wire [DATA_WIDTH*BLOCKLENGTH-1:0] inForSimTranOne_flat;
assign inForSimTranOne_flat = cutSearchTag_out[CUT_SEARCH_TAG_WIDTH-TAG_WIDTH-1 : CUT_SEARCH_TAG_WIDTH-TAG_WIDTH-BLOCKLENGTH*DATA_WIDTH];
wire [DATA_WIDTH-1:0] inForSimTranOne [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,inForSimTranOne,inForSimTranOne_flat,unpackIndex1,unpackLoop1)
wire [SIM_TRAN_ONE_DATA_WIDTH-1:0] inForSimTranOne_ext [0:BLOCKLENGTH-1];
genvar j;
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : tranOneExtend_loop
		assign inForSimTranOne_ext[j] = {inForSimTranOne[j][DATA_WIDTH-1],inForSimTranOne[j]};
	end
endgenerate
wire [SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0] inForSimTranOne_ext_flat;
`PACK_ARRAY2(SIM_TRAN_ONE_DATA_WIDTH,BLOCKLENGTH,inForSimTranOne_ext,inForSimTranOne_ext_flat,packIndex1,packLoop1)

//set the tag forthe similarity transform
wire simTranOneBusy;
wire simTranOneValid;
wire [SIM_TRAN_ONE_TAG_WIDTH-1:0] simTranOneTag_in;
wire [SIM_TRAN_ONE_TAG_WIDTH-1:0] simTranOneTag_out;
//the cut search out tag excluding the input vector and the cut search output
assign simTranOneTag_in = {cutSearchTag_out[CUT_SEARCH_TAG_WIDTH-1 : CUT_SEARCH_TAG_WIDTH-TAG_WIDTH], cutSearchTag_out[CUT_SEARCH_TAG_WIDTH-TAG_WIDTH-BLOCKLENGTH*DATA_WIDTH - 1 : 0], cutSearchData_out };

wire [SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0] simTranOneData_out;

CenteredSimilarityTransform #( 
	.TAG_WIDTH(SIM_TRAN_ONE_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(SIM_TRAN_ONE_DATA_WIDTH)) simTranOne(clk, reset, simpProjReady, cutSearchValid, simTranOneTag_in, inForSimTranOne_ext_flat, cutSearchData_out,
																	simTranOneBusy, simTranOneReady, simTranOneValid, simTranOneTag_out, simTranOneData_out);

//PERFORM THE SIMPLEX PROJECTION
localparam SIMP_PROJ_TAG_WIDTH = SIM_TRAN_ONE_TAG_WIDTH + SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH; //need the transform vector later

wire simpProjBusy;
wire simpProjValid;
wire [SIMP_PROJ_TAG_WIDTH-1:0] simpProjTag_in;
wire [SIMP_PROJ_TAG_WIDTH-1:0] simpProjTag_out;
assign simpProjTag_in = {simTranOneTag_out, simTranOneData_out}; //need the transform vector later

wire [SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0] simProjData_out;

//call the simplex projection to output with no integer bits
CenteredProjectSimplex #( 
	.TAG_WIDTH(SIMP_PROJ_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(SIM_TRAN_ONE_DATA_WIDTH),
	.IN_FRACTION_WIDTH(IN_FRACTION_WIDTH)) simpProj(clk, reset, simTranTwoReady, simTranOneValid, simpProjTag_in, simTranOneData_out,
																	simpProjBusy, simpProjReady, simpProjValid, simpProjTag_out, simProjData_out);

//PERFORM THE SIMILARITY TRANSFORM AGAIN
localparam SIM_TRAN_TWO_TAG_WIDTH = SIMP_PROJ_TAG_WIDTH - BLOCKLENGTH; //we're extracting the f vector from the tag now and using it
localparam SIM_TRAN_TWO_DATA_WIDTH = SIM_TRAN_ONE_DATA_WIDTH; //the output of the simplex projection cant be the most negative number in its representation. therefore no extra bit needed for overflow

wire simTranTwoBusy;
wire simTranTwoValid;
wire [SIM_TRAN_TWO_TAG_WIDTH-1:0] simTranTwoTag_in;
wire [SIM_TRAN_TWO_TAG_WIDTH-1:0] simTranTwoTag_out;
wire [SIM_TRAN_TWO_DATA_WIDTH*BLOCKLENGTH-1:0] simTranTwoData_out;
wire [0:BLOCKLENGTH-1] transformVector;

//very easy to pop f vector off tag
assign transformVector = simpProjTag_out[SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH+BLOCKLENGTH-1:SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH];
assign simTranTwoTag_in = {simpProjTag_out[SIMP_PROJ_TAG_WIDTH-1:SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH+BLOCKLENGTH],simpProjTag_out[SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0]};

CenteredSimilarityTransform #( 
	.TAG_WIDTH(SIM_TRAN_TWO_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(SIM_TRAN_TWO_DATA_WIDTH)) simTranTwo(clk, reset, boxProjTwoReady, simpProjValid, simTranTwoTag_in, simProjData_out, transformVector,
													simTranTwoBusy, simTranTwoReady, simTranTwoValid, simTranTwoTag_out, simTranTwoData_out);

//BOX PROJECT THE FIRST TRANSFORMED VECTOR TO PREPARE FOR SELECTION TEST
//First format the second similarity transform output to be placed in the tag
wire signed [SIM_TRAN_TWO_DATA_WIDTH-1:0] simplexRouteOutput_ext [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(SIM_TRAN_TWO_DATA_WIDTH,BLOCKLENGTH,simplexRouteOutput_ext,simTranTwoData_out,unpackIndex2,unpackLoop2)
wire signed [DATA_WIDTH-1:0] simplexRouteOutput [0:BLOCKLENGTH-1];
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : simplexRouteFormat_loop
		//don't think this can overflow
		//need to round to symmetrize decoder
		assign simplexRouteOutput[j] = simplexRouteOutput_ext[j][SIM_TRAN_TWO_DATA_WIDTH-1:1] + {{(SIM_TRAN_TWO_DATA_WIDTH-2){1'b0}},simplexRouteOutput_ext[j][0]}; //SIM_TRAN_TWO_DATA_WIDTH = DATA_WIDTH+!
	end
endgenerate
wire [DATA_WIDTH*BLOCKLENGTH-1:0] simplexRouteOutput_flat;
`PACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,simplexRouteOutput,simplexRouteOutput_flat,packIndex2,packLoop2)

localparam BOX_PROJ_TWO_TAG_WIDTH = SIM_TRAN_TWO_TAG_WIDTH - SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH + DATA_WIDTH*BLOCKLENGTH; //using the first transformed vector
wire [BOX_PROJ_TWO_TAG_WIDTH-1:0] boxProjTwoTag_in;
wire [BOX_PROJ_TWO_TAG_WIDTH-1:0] boxProjTwoTag_out;
assign boxProjTwoTag_in = {simTranTwoTag_out[SIM_TRAN_TWO_TAG_WIDTH-1:SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH],simplexRouteOutput_flat};

wire [SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0] boxProjTwoData_in;
wire [SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0] boxProjTwoData_out;
assign boxProjTwoData_in = simTranTwoTag_out[SIM_TRAN_ONE_DATA_WIDTH*BLOCKLENGTH-1:0];

wire boxProjTwoBusy;
wire boxProjTwoValid;

//the input integer width here is at least 1
CenteredProjectBox #( 
	.TAG_WIDTH(BOX_PROJ_TWO_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(SIM_TRAN_ONE_DATA_WIDTH),
	.IN_FRACTION_WIDTH(IN_FRACTION_WIDTH)) boxProjTwo(clk, reset, selectTestReady, simTranTwoValid, boxProjTwoTag_in, boxProjTwoData_in,
																	boxProjTwoBusy, boxProjTwoReady, boxProjTwoValid, boxProjTwoTag_out, boxProjTwoData_out);

//PERFORM THE SELECTION TEST
localparam SELECT_TEST_DATA_WIDTH = SIM_TRAN_ONE_DATA_WIDTH + log2(BLOCKLENGTH); //there is a sum tree

//sign extend the box projection
wire signed [SIM_TRAN_ONE_DATA_WIDTH-1:0] box2DataOut [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(SIM_TRAN_ONE_DATA_WIDTH,BLOCKLENGTH,box2DataOut,boxProjTwoData_out,unpackIndex3,unpackLoop3)
wire signed [SELECT_TEST_DATA_WIDTH-1:0] box2DataOut_ext [0:BLOCKLENGTH-1];
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : selectTestExtend_loop
		if(log2(BLOCKLENGTH) > 0) begin
			assign box2DataOut_ext[j] = {{(log2(BLOCKLENGTH)){box2DataOut[j][SIM_TRAN_ONE_DATA_WIDTH-1]}},box2DataOut[j]};
		end else begin
			assign box2DataOut_ext[j] = box2DataOut[j];
		end
	end
endgenerate
wire [SELECT_TEST_DATA_WIDTH*BLOCKLENGTH-1:0] selectTestData_in;
`PACK_ARRAY2(SELECT_TEST_DATA_WIDTH,BLOCKLENGTH,box2DataOut_ext,selectTestData_in,packIndex3,packLoop3)

wire selectTestBusy;
wire selectTestValid;
wire [BOX_PROJ_TWO_TAG_WIDTH-1:0] selectTestTag_in;
wire [BOX_PROJ_TWO_TAG_WIDTH-1:0] selectTestTag_out;
assign selectTestTag_in = boxProjTwoTag_out;
wire selectTestData_out;

CenteredSelectionTest #(.TAG_WIDTH(BOX_PROJ_TWO_TAG_WIDTH),
						.BLOCKLENGTH(BLOCKLENGTH),
						.DATA_WIDTH(SELECT_TEST_DATA_WIDTH),
						.FRACTION_WIDTH(SIM_TRAN_ONE_DATA_WIDTH-1)) selectTest(clk, reset, outSelectReady, boxProjTwoValid, selectTestTag_in, selectTestData_in,
																								selectTestBusy, selectTestReady, selectTestValid, selectTestTag_out, selectTestData_out);

//SELECT THE OUTPUT
wire [TAG_WIDTH-1:0] outSelectTag_in;
wire [DATA_WIDTH*BLOCKLENGTH-1:0] inBoxProj;
wire [DATA_WIDTH*BLOCKLENGTH-1:0] transformedSimplexProj;

assign outSelectTag_in = selectTestTag_out[BOX_PROJ_TWO_TAG_WIDTH-1:BOX_PROJ_TWO_TAG_WIDTH-TAG_WIDTH];
assign inBoxProj = selectTestTag_out[BOX_PROJ_TWO_TAG_WIDTH-TAG_WIDTH-1:BOX_PROJ_TWO_TAG_WIDTH-TAG_WIDTH-DATA_WIDTH*BLOCKLENGTH];
assign transformedSimplexProj = selectTestTag_out[BOX_PROJ_TWO_TAG_WIDTH-TAG_WIDTH-DATA_WIDTH*BLOCKLENGTH-1:0];

wire outSelectBusy;
wire outSelectValid;

OutSelect #(.TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) outSelect(clk, reset, ready_in, selectTestValid, outSelectTag_in, inBoxProj, transformedSimplexProj, selectTestData_out,
																outSelectBusy, outSelectReady, outSelectValid, tag_out, data_out);

//OUPUT
/*wire [SIM_TRAN_TWO_DATA_WIDTH-1:0] outer [0:BLOCKLENGTH-1];
wire [DATA_WIDTH-1:0] outer2 [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(SIM_TRAN_TWO_DATA_WIDTH,BLOCKLENGTH,outer,simTranTwoData_out,unpackIndex2,unpackLoop2)
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : ol
		assign outer2[j] = outer[j][DATA_WIDTH:1];
	end
endgenerate
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,outer2,data_out)*/

assign busy = inBoxProjBusy | cutSearchBusy | simTranOneBusy | simpProjBusy | simTranTwoBusy | boxProjTwoBusy | selectTestBusy | outSelectBusy;
assign ready_out = inBoxProjReady;
assign valid_out = outSelectValid;
//assign tag_out = selectTestTag_out[SIM_TRAN_TWO_TAG_WIDTH-1:SIM_TRAN_TWO_TAG_WIDTH-TAG_WIDTH];




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



`endif //_my_centered_project_parity_polytope_