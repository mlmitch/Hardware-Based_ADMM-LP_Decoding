`ifndef _my_normalize_
`define _my_normalize_

`include "2dArrayMacros.v"

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the post prefix sum normalization in the simplex projection routine.

Have to specify fixed point representation for this module.

This module also trims the multiplication output to the appropriate length
specified by OUT_DATA_WIDTH.

Caller of this module has to worry about the multiplication fitting in the
specifies output fixed point representation

The actual normalization is performed by multiplying by the reciprocal of the index.
This reciprocal is calculated at synthesis time using a constant function.
We don't round this reciprocal as truncating will guarantee no overflow in
subsequent steps.

note: temporarily trying rounding to see if it helps
*/

module Normalize # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter IN_DATA_WIDTH = 8,
	parameter IN_FRACTION_WIDTH = 4,
	parameter OUT_DATA_WIDTH = 8,
	parameter OUT_FRACTION_WIDTH = 4
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [IN_DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [OUT_DATA_WIDTH*BLOCKLENGTH-1:0] data_out	
);
localparam RECIP_DATA_WIDTH = 25; //making this huge. excess bitswill get trimmed. 25 is the single dsp number for xilinx virtex 5
localparam RECIP_INTEGER_WIDTH = 0;
localparam RECIP_FRACTION_WIDTH = RECIP_DATA_WIDTH - RECIP_INTEGER_WIDTH - 1;

localparam OUT_INTEGER_WIDTH = OUT_DATA_WIDTH - OUT_FRACTION_WIDTH - 1;
localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

//BRING IN INPUT																			
wire signed [IN_DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(IN_DATA_WIDTH,BLOCKLENGTH,in,data_in,unpackIndex1,unpackLoop1)
reg signed [IN_DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
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

//PERFORM THE MULTIPLICATION
//multiplication of a Qi.j and Qm.n gives a Q(i+m+1).(j+n)
localparam MULT_DATA_WIDTH = IN_DATA_WIDTH + RECIP_DATA_WIDTH;
localparam MULT_FRACTION_WIDTH = IN_FRACTION_WIDTH + RECIP_FRACTION_WIDTH; //input fraction width plus the reciprocal fraction width
localparam MULT_HALF_POSITION = MULT_FRACTION_WIDTH - 1;
wire signed [MULT_DATA_WIDTH-1:0] mult [0:BLOCKLENGTH-1];
genvar i2;
generate
	for(i2 = 1; i2 < BLOCKLENGTH; i2 = i2 + 1) begin : MULT_LOOP
		assign mult[i2] = reg0[i2] * reciprocal(i2+1);
	end
endgenerate
assign mult[0] = {reg0[0][IN_DATA_WIDTH-1],reg0[0],{(RECIP_FRACTION_WIDTH){1'b0}}}; //this is the multiplication by 1

//TRIM THE MULTIPLICATION TO THE CORRECT SIZE AND REGISTER IT
reg signed [OUT_DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg1[i] <= 0;
		end else if (1'b1 == enable) begin
			//This selects the desired fraction bits and if I have calculated correctly, just enough integer bits
			//to guarantee no overflow.
			reg1[i] <= mult[i][MULT_HALF_POSITION + OUT_INTEGER_WIDTH + 1:MULT_HALF_POSITION - OUT_FRACTION_WIDTH + 1] + {{(OUT_DATA_WIDTH-1){1'b0}}, mult[i][MULT_HALF_POSITION - OUT_FRACTION_WIDTH]};
		end
	end
end

//output
`PACK_ARRAY(OUT_DATA_WIDTH,BLOCKLENGTH,reg1,data_out)

//constant function that returns the recipricol of a positive integer x ~= 0
//returns DATA_WIDTH wide fixed point with a sign bit and no integer bits
//not sure what happens for negative integers..haven't needed this behavior yet
function signed [RECIP_DATA_WIDTH-1:0] reciprocal;
	input integer x;
	reg signed [2*RECIP_DATA_WIDTH-1:0] preRound;
	begin
		//one is special since we aren't allowing for exact representation of 1
		if(1 == x) begin
			reciprocal[RECIP_DATA_WIDTH-1] = 1'b0;
			reciprocal[RECIP_DATA_WIDTH-2:0] = {(RECIP_DATA_WIDTH-1){1'b1}};
		end else begin
			//multiply 1/x by 2**RECIPROCAL_WIDTH to get RECIPROCAL_WIDTH bits. This gives one more 
			//bit than we can store (since we need a sign bit) that allows for rounding
			//use rounding here since everything is done during compilation
			preRound = (2**RECIP_DATA_WIDTH)/x; 
			reciprocal = preRound[RECIP_DATA_WIDTH:1] + {{(RECIP_DATA_WIDTH-1){1'b0}}, preRound[0]};
		end
		
	end
endfunction

endmodule


/*
Much simpler normalize module
takes in a single number and multiplies by the reciprocal of the 
blocklength parameter. used in variable node.
*/
module SingleNormalize # 
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
	input signed [DATA_WIDTH-1:0] data_in,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output signed [2*DATA_WIDTH-1:0] data_out	
);
localparam RECIP_DATA_WIDTH = 25; //making this huge. excess bits will get trimmed. 25 is the single dsp number for xilinx virtex 5
localparam RECIP_INTEGER_WIDTH = 0;
localparam RECIP_FRACTION_WIDTH = RECIP_DATA_WIDTH - RECIP_INTEGER_WIDTH - 1;

parameter OUT_DATA_WIDTH = DATA_WIDTH*2;

localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
															valid_out, ready_out, busy, enable, tag_out);

//BRING IN INPUT																			
reg signed [DATA_WIDTH-1:0] reg0;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		reg0 <= 0;
	end else if (1'b1 == enable) begin
		reg0 <= data_in;
	end
end


//account for blocklength 1
localparam MULT_DATA_WIDTH = DATA_WIDTH + RECIP_DATA_WIDTH;
wire signed [MULT_DATA_WIDTH-1:0] carefulMult;
generate
	if(1 == BLOCKLENGTH) begin
		assign carefulMult = {reg0[DATA_WIDTH-1],reg0,{(RECIP_FRACTION_WIDTH){1'b0}}};
	end else begin
		assign carefulMult = reg0 * reciprocal(BLOCKLENGTH);
	end
endgenerate

//PERFORM THE MULTIPLICATION
//multiplication of a Qi.j and Qm.n gives a Q(i+m+1).(j+n)
reg signed [2*DATA_WIDTH-1:0] reg1;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		reg1 <= 0;
	end else if (1'b1 == enable) begin
		reg1 <= carefulMult[MULT_DATA_WIDTH-1:MULT_DATA_WIDTH-OUT_DATA_WIDTH] + {{(OUT_DATA_WIDTH-1){1'b0}}, carefulMult[MULT_DATA_WIDTH-OUT_DATA_WIDTH-1]};
	end
end

//output
assign data_out = reg1;

//constant function that returns the recipricol of a positive integer x ~= 0
//returns DATA_WIDTH wide fixed point with a sign bit and no integer bits
//not sure what happens for negative integers..haven't needed this behavior yet
function signed [RECIP_DATA_WIDTH-1:0] reciprocal;
	input integer x;
	reg signed [2*RECIP_DATA_WIDTH-1:0] preRound;
	begin
		//one is special since we aren't allowing for exact representation of 1
		if(1 == x) begin
			reciprocal[RECIP_DATA_WIDTH-1] = 1'b0;
			reciprocal[RECIP_DATA_WIDTH-2:0] = {(RECIP_DATA_WIDTH-1){1'b1}};
		end else begin
			//multiply 1/x by 2**RECIPROCAL_WIDTH to get RECIPROCAL_WIDTH bits. This gives one more 
			//bit than we can store (since we need a sign bit) that allows for rounding
			//use rounding here since everything is done during compilation
			preRound = (2**RECIP_DATA_WIDTH)/x; 
			reciprocal = preRound[RECIP_DATA_WIDTH:1] + {{(RECIP_DATA_WIDTH-1){1'b0}}, preRound[0]};
		end
		
	end
endfunction

endmodule

`endif //_my_normalize_