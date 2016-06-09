`ifndef _my_centered_out_subtract_
`define _my_centered_out_subtract_

/*
Mitch Wasson (mitch.wasson@gmail.com)

We assume that IN_INTEGER_WIDTH > 0 - this is always the case in simplex projection
Also assume that FRACTION_WIDTH > 0
*/

`include "2dArrayMacros.v"

module CenteredOutSubtract # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter IN_DATA_WIDTH = 8,
	parameter OUT_DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [IN_DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	input signed [IN_DATA_WIDTH-1:0] subtract_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [OUT_DATA_WIDTH*BLOCKLENGTH-1:0] data_out	
);
parameter FRACTION_WIDTH = OUT_DATA_WIDTH - 1;
localparam IN_INTEGER_WIDTH = IN_DATA_WIDTH - FRACTION_WIDTH - 1;
localparam OUT_INTEGER_WIDTH = OUT_DATA_WIDTH - FRACTION_WIDTH - 1;

localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

//BRING IN INPUT
wire signed [IN_DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(IN_DATA_WIDTH,BLOCKLENGTH,in,data_in,unpackIndex1,unpackLoop1)
reg signed [IN_DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [IN_DATA_WIDTH-1:0] subReg; 
integer i;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		subReg <= 0;
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg0[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		subReg <= subtract_in;
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg0[i] <= in[i];
		end
	end
end
 
//PERFORM SUBTRACTION AND CAPTURE OVERFLOW SIGNALS
localparam SUM_INTEGER_WIDTH = IN_INTEGER_WIDTH + 2;
localparam SUM_FRACTION_WIDTH = FRACTION_WIDTH;
localparam SUM_DATA_WIDTH = SUM_INTEGER_WIDTH + SUM_FRACTION_WIDTH + 1;

wire signed [SUM_DATA_WIDTH-1:0] IN_HALF = {{(SUM_INTEGER_WIDTH+1){1'b0}},1'b1,{(SUM_FRACTION_WIDTH-1){1'b0}}};
wire signed [SUM_DATA_WIDTH-1:0] reg0_ext [0:BLOCKLENGTH-1];
wire signed [SUM_DATA_WIDTH-1:0] subReg_ext;
assign subReg_ext = {subReg[IN_DATA_WIDTH-1],subReg[IN_DATA_WIDTH-1],subReg};
genvar j;
generate
	for(j = 0; j<BLOCKLENGTH; j=j+1 ) begin :ext
		assign reg0_ext[j] = {reg0[j][IN_DATA_WIDTH-1],reg0[j][IN_DATA_WIDTH-1],reg0[j]};
	end
endgenerate

reg signed [SUM_DATA_WIDTH-1:0] intermediateResultReg [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			intermediateResultReg[i] <= 0;		
		end else if (1'b1 == enable) begin
			intermediateResultReg[i] <= reg0_ext[i] - subReg_ext; //maybe add a fourth register...
		end
	end
end
 
reg clipIndicator [0:BLOCKLENGTH-1];
reg signed [SUM_DATA_WIDTH-1:0] resultReg [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			clipIndicator[i] <= 0;
			resultReg[i] <= 0;		
		end else if (1'b1 == enable) begin
			clipIndicator[i] <= intermediateResultReg[i][SUM_DATA_WIDTH-1]; //if this number is negative before subtracting 1/2, we'll need to clip.
			resultReg[i] <= intermediateResultReg[i] - IN_HALF;
		end
	end
end

//ASSIGN THE OUTPUT BASED ON THE SUBTRACTION AND OVERFLOW SIGNALS
wire signed [OUT_DATA_WIDTH-1:0] OUT_HALF;
assign OUT_HALF = {1'b0,1'b1,{(FRACTION_WIDTH-1){1'b0}}};

wire signed [OUT_DATA_WIDTH-1:0] outFractions [0:BLOCKLENGTH-1];
generate
	for(j = 0; j < BLOCKLENGTH; j=j+1) begin : CAP_LOOP
		//select fraction bits from subtraction and add appropiate number of zeros so this could be the chosen output
		assign outFractions[j] = {resultReg[j][SUM_DATA_WIDTH-1], resultReg[j][FRACTION_WIDTH-1:0]};		
	end
endgenerate

reg signed [OUT_DATA_WIDTH-1:0] out [0:BLOCKLENGTH-1];

always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			out[i] <= 0;
		end else if (1'b1 == enable) begin
			out[i] <= 	clipIndicator[i] ? -OUT_HALF : outFractions[i];
		end
	end
end

//output
`PACK_ARRAY(OUT_DATA_WIDTH,BLOCKLENGTH,out,data_out)

endmodule

`endif //_my_centered_out_subtract_