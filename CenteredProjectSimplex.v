`ifndef _my_centered_project_simplex_
`define _my_centered_project_simplex_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the projection onto the probability simplex.
Currently only implemented for dimensions up to and including 8

Have to specify fixed point representation for this module.
This is dont by the FRACTION_WIDTH_IN and FRACTION_WIDTH_OUT parameters.

FRACTION_WIDTH_IN can be any positive number < DATA_WIDTH
FRACTION_WIDTH_OUT can either be DATA_WIDTH - 1 or DATA_WIDTH - 2
assume FRACTION_WIDTH_OUT >= FRACTION_WIDTH_IN
also assume FRACTION_WIDTH_OUT > 0


The idea of this module is that (almost) all logic is implemented in sub modules.
*/

`include "2dArrayMacros.v"
`include "SortNetwork.v"
`include "PrefixAdder.v"
`include "Normalize.v"
`include "MaxIndex.v"
`include "CenteredOutSubtract.v"

module CenteredProjectSimplex # 
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
localparam IN_INTEGER_WIDTH = DATA_WIDTH - IN_FRACTION_WIDTH - 1;

//need to declare readies up top
wire addReady;
wire sortReady;
wire normReady;
wire maxReady;
wire subCapReady;

//FIRST STEP - SORT THE INPUT
localparam SORT_TAG_WIDTH = TAG_WIDTH + BLOCKLENGTH*DATA_WIDTH; //we need the original vector later

wire sortBusy;
wire sortValid;
wire [SORT_TAG_WIDTH-1:0] sortTag_out;
wire [SORT_TAG_WIDTH-1:0] sortTag_in;
wire [DATA_WIDTH*BLOCKLENGTH-1:0] sortData_out;
assign sortTag_in = {tag_in, data_in};

SortNetwork #( 
	.TAG_WIDTH(SORT_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(DATA_WIDTH)) sorter(clk, reset, addReady, valid_in, sortTag_in, data_in,
													sortBusy, sortReady, sortValid, sortTag_out, sortData_out);


//SECOND STEP - PREFORM PREFIX ADDITION
//Note: we append -1 to the vector and up the prefix sum blocklength instead of subtracting 1 from the 
//first component manually. This sometimes results in 1 less pipeline stagedepending on blocklength.
//Also, the first output of the adder should get pruned, deleting unessecary pipeline registers.
localparam ADD_BLOCKLENGTH = BLOCKLENGTH + 1;
localparam ADD_TAG_WIDTH = SORT_TAG_WIDTH + BLOCKLENGTH*DATA_WIDTH; //we need the sorted vector later
localparam ADD_DATA_WIDTH = DATA_WIDTH + log2(ADD_BLOCKLENGTH); //add integer bits to prevent overflow
localparam ADD_FRACTION_WIDTH = IN_FRACTION_WIDTH;
localparam ADD_INTEGER_WIDTH = ADD_DATA_WIDTH - ADD_FRACTION_WIDTH - 1;

wire addBusy;
wire addValid;
wire [ADD_TAG_WIDTH-1:0] addTag_out;
wire [ADD_TAG_WIDTH-1:0] addTag_in;
wire [ADD_DATA_WIDTH*ADD_BLOCKLENGTH-1:0] addData_out;
wire [ADD_DATA_WIDTH*ADD_BLOCKLENGTH-1:0] addData_in;
assign addTag_in = {sortTag_out, sortData_out};

//Create the adder input from sort output. Just wire routing here. No actual logic.
wire signed [DATA_WIDTH-1:0] sortData [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,sortData,sortData_out,unpackIndex1,unpackLoop1)
wire signed [ADD_DATA_WIDTH-1:0] addData [0:ADD_BLOCKLENGTH-1];

genvar i;
generate
	for(i=1; i<ADD_BLOCKLENGTH; i=i+1) begin : ADD_EXTEND_LOOP
		//sign extend the sorted data
		assign addData[i] = {{(ADD_DATA_WIDTH - DATA_WIDTH){sortData[i-1][DATA_WIDTH-1]}},sortData[i-1]};
	end
endgenerate

//Creating negative 1 vector.
//We know there is always at least one integer bit added above.
//Therefore create one vector easily and slap a negative in front
wire signed [ADD_DATA_WIDTH-1:0] ADD_ONE;
assign ADD_ONE = {{(ADD_INTEGER_WIDTH){1'b0}},1'b1,{(ADD_FRACTION_WIDTH){1'b0}}};
assign addData[0] = -ADD_ONE; //impossible for overflow to happen here

`PACK_ARRAY2(ADD_DATA_WIDTH,ADD_BLOCKLENGTH,addData,addData_in,packIndex1,packLoop1)

PrefixAdder #( 
	.TAG_WIDTH(ADD_TAG_WIDTH),
	.BLOCKLENGTH(ADD_BLOCKLENGTH),
	.DATA_WIDTH(ADD_DATA_WIDTH)) adder(clk, reset, normReady, sortValid, addTag_in, addData_in,
													addBusy, addReady, addValid, addTag_out, addData_out);


//THIRD STEP - PERFORM NORMALIZATION
localparam NORM_INTEGER_WIDTH = IN_INTEGER_WIDTH+1; //+1 ensures no ovrflow.
localparam NORM_FRACTION_WIDTH = OUT_FRACTION_WIDTH; //this is the biggest number of fraction bits we'll need from the normalization.
localparam NORM_DATA_WIDTH = NORM_FRACTION_WIDTH + NORM_INTEGER_WIDTH + 1;
wire normBusy;
wire normValid;
wire [ADD_TAG_WIDTH-1:0] normTag_out;
wire [NORM_DATA_WIDTH*BLOCKLENGTH-1:0] normData_out;
wire [ADD_DATA_WIDTH*BLOCKLENGTH-1:0] normData_in;

wire signed [ADD_DATA_WIDTH-1:0] aData [0:ADD_BLOCKLENGTH-1];
`UNPACK_ARRAY2(ADD_DATA_WIDTH,ADD_BLOCKLENGTH,aData,addData_out,unpackIndex2,unpackLoop2)
wire signed [ADD_DATA_WIDTH-1:0] normData [0:BLOCKLENGTH-1];
generate
	for(i=0; i<BLOCKLENGTH; i=i+1) begin : PRE_NORM_LOOP
		//sign extend the sorted data
		assign normData[i] = aData[i+1];
	end
endgenerate
`PACK_ARRAY2(ADD_DATA_WIDTH,BLOCKLENGTH,normData,normData_in,packIndex2,packLoop2)

Normalize #( 
	.TAG_WIDTH(ADD_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.IN_DATA_WIDTH(ADD_DATA_WIDTH),
	.IN_FRACTION_WIDTH(ADD_FRACTION_WIDTH),
	.OUT_DATA_WIDTH(NORM_DATA_WIDTH),
	.OUT_FRACTION_WIDTH(NORM_FRACTION_WIDTH)) normalizer(clk, reset, maxReady, addValid, addTag_out, normData_in,
																	normBusy, normReady, normValid, normTag_out, normData_out);

//FOURTH STEP - FIND THE VALUE WE SUBTRACT FROM THE INPUT VECTOR
localparam MAX_TAG_WIDTH = SORT_TAG_WIDTH;
wire maxBusy;
wire maxValid;
wire [MAX_TAG_WIDTH-1:0] maxTag_in;
wire [MAX_TAG_WIDTH-1:0] maxTag_out;
wire signed [NORM_DATA_WIDTH-1:0] maxData_out; //Max Index onyl returns one number

//first extract the sorted vector from the normalized tag. again, no logic. just routing.
wire [DATA_WIDTH*BLOCKLENGTH-1:0] sortedFromNomalize_flat;
wire signed [DATA_WIDTH-1:0] sortedFromNomalize [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,sortedFromNomalize,sortedFromNomalize_flat,unpackIndex3,unpackLoop3)
wire signed [NORM_DATA_WIDTH-1:0] sortedFromNomalizeExtended [0:BLOCKLENGTH-1];
wire [NORM_DATA_WIDTH*BLOCKLENGTH-1:0] sortedFromNomalizeExtended_flat;
`PACK_ARRAY2(NORM_DATA_WIDTH,BLOCKLENGTH,sortedFromNomalizeExtended,sortedFromNomalizeExtended_flat,packIndex3,packLoop3)
generate
	for(i=0; i<BLOCKLENGTH; i=i+1) begin : SORTED_EXTEND_LOOP
		//seems like XST doesn't ignore or error length 0 replications..does something that I'm not sure of
		if(NORM_FRACTION_WIDTH > IN_FRACTION_WIDTH) begin
			assign sortedFromNomalizeExtended[i] = {sortedFromNomalize[i][DATA_WIDTH-1],sortedFromNomalize[i],{(NORM_FRACTION_WIDTH - IN_FRACTION_WIDTH){1'b0}}}; //sign extend and add extra fraction bits if nessecary	
		end else begin
			assign sortedFromNomalizeExtended[i] = {sortedFromNomalize[i][DATA_WIDTH-1],sortedFromNomalize[i]};
		end
	end
endgenerate
assign sortedFromNomalize_flat = normTag_out[DATA_WIDTH*BLOCKLENGTH-1:0];
assign maxTag_in = normTag_out[ADD_TAG_WIDTH-1:DATA_WIDTH*BLOCKLENGTH];

 MaxIndex #( 
	.TAG_WIDTH(MAX_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.DATA_WIDTH(NORM_DATA_WIDTH)) maxer(clk, reset, subCapReady, normValid, maxTag_in, sortedFromNomalizeExtended_flat, normData_out, 
													maxBusy, maxReady, maxValid, maxTag_out, maxData_out);

//FIFTH STEP - SUBTRACT THE VALUE MAX INDEX GIVES AND CAP BETWEEN 0 AND 1 IF NESSECARY.
localparam SUB_CAP_TAG_WIDTH = TAG_WIDTH;

wire subCapBusy;
wire subCapValid;
wire [SUB_CAP_TAG_WIDTH-1:0] subCapTag_in;
wire [SUB_CAP_TAG_WIDTH-1:0] subCapTag_out;


//first extract the iput vector from the max tag. again, no logic. just routing.
wire [DATA_WIDTH*BLOCKLENGTH-1:0] inputFromMax_flat;
wire signed [DATA_WIDTH-1:0] inputFromMax [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,inputFromMax,inputFromMax_flat,unpackIndex4,unpackLoop4)
wire signed [NORM_DATA_WIDTH-1:0] inputFromMaxExtended [0:BLOCKLENGTH-1];
wire [NORM_DATA_WIDTH*BLOCKLENGTH-1:0] inputFromMaxExtended_flat;
`PACK_ARRAY2(NORM_DATA_WIDTH,BLOCKLENGTH,inputFromMaxExtended,inputFromMaxExtended_flat,packIndex4,packLoop4)
generate
	for(i=0; i<BLOCKLENGTH; i=i+1) begin : INPUT_EXTEND_LOOP
		//seems like XST doesn't ignore or error length 0 replications..does something that I'm not sure of
		if(NORM_FRACTION_WIDTH > IN_FRACTION_WIDTH) begin
			assign inputFromMaxExtended[i] = {inputFromMax[i][DATA_WIDTH-1],inputFromMax[i],{(NORM_FRACTION_WIDTH - IN_FRACTION_WIDTH){1'b0}}}; //sign extend and add extra fraction bits if nessecary	
		end else begin
			assign inputFromMaxExtended[i] = {inputFromMax[i][DATA_WIDTH-1],inputFromMax[i]};
		end
	end
endgenerate
assign inputFromMax_flat = maxTag_out[DATA_WIDTH*BLOCKLENGTH-1:0];
assign subCapTag_in = maxTag_out[MAX_TAG_WIDTH-1:DATA_WIDTH*BLOCKLENGTH];

//this outputs numbers data_width wide with data_width-1 as the fraaction bits
 CenteredOutSubtract #( 
	.TAG_WIDTH(SUB_CAP_TAG_WIDTH),
	.BLOCKLENGTH(BLOCKLENGTH),
	.IN_DATA_WIDTH(NORM_DATA_WIDTH),
	.OUT_DATA_WIDTH(DATA_WIDTH)) subCap(clk, reset, ready_in, maxValid, subCapTag_in, inputFromMaxExtended_flat, maxData_out,
													subCapBusy, subCapReady, subCapValid, subCapTag_out, data_out);

//Assign output signals
assign ready_out = sortReady;
assign valid_out = subCapValid;
assign tag_out = subCapTag_out;
//wire signed [DATA_WIDTH-1:0] out [0:BLOCKLENGTH-1];
//generate
//	for(i=0; i<BLOCKLENGTH; i=i+1) begin : FDGADFGSD
//		assign out[i] = maxData_out[DATA_WIDTH-1:0];
//	end
//endgenerate
//`PACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,out,data_out,agfdagdf,fjhdfgh)

//or together all the submodule busy signals to 
//indicate if the simplex projection pipeline is busy
assign busy = sortBusy | addBusy | normBusy | maxBusy | subCapBusy;

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



`endif //_my_centered_project_simplex_