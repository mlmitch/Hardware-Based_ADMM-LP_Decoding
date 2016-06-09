`ifndef _my_summer_
`define _my_summer_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module takes in an array of numbers and sums them. guaranteed ceil(log2(BLOCKLENGTH)) registers.
Executes the sum with recursive calls.

PipelineSummer is a wrapper of Summer with ready and valid logic.
*/

`include "2dArrayMacros.v"
`include "PipelineTrain.v"

/* recursive sum tree with pipeline logic*/
module PipelineSummer #
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
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output signed [DATA_WIDTH-1:0] sum	
);

localparam NUM_REGISTERS = log2(BLOCKLENGTH) + 1; //register input

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
															valid_out, ready_out, busy, enable, tag_out);
reg [DATA_WIDTH*BLOCKLENGTH-1:0] data_in_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		data_in_reg <= 0;
	end else if (1'b1 == enable) begin
		data_in_reg <= data_in;
	end
end	
														
															
Summer #(.BLOCKLENGTH(BLOCKLENGTH), 
		.DATA_WIDTH(DATA_WIDTH)) sumMod(clk, reset, enable, data_in_reg, sum);

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

/*recursive sum tree*/
module Summer # 
(
	parameter BLOCKLENGTH = 1, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output signed [DATA_WIDTH-1:0] sum	
);

generate
	if(1 == BLOCKLENGTH) begin
		assign sum = data_in;
	end else begin
		SummerRec #(.BLOCKLENGTH(BLOCKLENGTH), 
						.DATA_WIDTH(DATA_WIDTH)) sumMod(clk, reset, enable, data_in, sum);
	end
endgenerate

endmodule


/*recursive call for registered sum tree*/
module SummerRec # 
(
	parameter BLOCKLENGTH = 2, 
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input enable,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in,
	
	output signed [DATA_WIDTH-1:0] sum	
);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

localparam integer HALF_BLOCKLENGTH = BLOCKLENGTH/2;
localparam integer HALF_BLOCKLENGTH_LESS_ONE = (BLOCKLENGTH-1)/2;
localparam REG_BLOCKLENGTH = (HALF_BLOCKLENGTH == HALF_BLOCKLENGTH_LESS_ONE) ? (HALF_BLOCKLENGTH + 1) : HALF_BLOCKLENGTH; //if true, means that input blocjklength is odd
wire signed [DATA_WIDTH-1:0] weirdAdd;
generate
	if(HALF_BLOCKLENGTH == HALF_BLOCKLENGTH_LESS_ONE) begin //input blocklength odd
		assign weirdAdd = in[BLOCKLENGTH-1];
	end else begin
		assign weirdAdd = in[BLOCKLENGTH-2] + in[BLOCKLENGTH-1];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg0 [0:REG_BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	//fills all but last entry
	for(i = 0; i<REG_BLOCKLENGTH-1; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= in[2*i] + in[2*i+1];
		end
	end
	
	//fill last entry
	if (1'b1 == reset) begin
		reg0[REG_BLOCKLENGTH-1] <= 0;
	end else if (1'b1 == enable) begin
		reg0[REG_BLOCKLENGTH-1] <= weirdAdd;
	end
end

wire [DATA_WIDTH*REG_BLOCKLENGTH-1:0] sumvals;
`PACK_ARRAY(DATA_WIDTH,REG_BLOCKLENGTH,reg0,sumvals)

Summer #(.BLOCKLENGTH(REG_BLOCKLENGTH), 
			.DATA_WIDTH(DATA_WIDTH)) sumMod(clk, reset, enable, sumvals, sum);


endmodule


/*
This module takes in two vectors and adds the components together.
*/

module VectorSummer #
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
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in1,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] data_in2,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out	
);

localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
															valid_out, ready_out, busy, enable, tag_out);
															
wire signed [DATA_WIDTH-1:0] in1 [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,in1,data_in1,unpackIndex1,unpackLoop1)
wire signed [DATA_WIDTH-1:0] in2 [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,in2,data_in2,unpackIndex2,unpackLoop2)

//register inputs
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
		end else if (1'b1 == enable) begin
			reg1[i] <= in1[i];
			reg2[i] <= in2[i];
		end
	end
end

//perform addition
reg signed [DATA_WIDTH-1:0] outReg [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			outReg[i] <= 0;
		end else if (1'b1 == enable) begin
			outReg[i] <= reg1[i] + reg2[i];
		end
	end
end

`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,outReg,data_out)

endmodule


`endif //_my_summer_
