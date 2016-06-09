`ifndef _my_max_index_
`define _my_max_index_

`include "2dArrayMacros.v"

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module takes in two vectors of signed numbers.
With these numbers it finds the largest component (component of largest index)
where the component of the first vector is greater than the 
corresponding componenet of the second vector.

Given the location of where this occurs, we select the correponding
value from the second input vector. This value is then used
subsequently in the simplex projection module.
*/

`include "2dArrayMacros.v"

module MaxIndex # 
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
	output signed [DATA_WIDTH-1:0] selection_out	
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

//BRING IN INPUTS																				
wire signed [DATA_WIDTH-1:0] in1 [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,in1,data_in1,unpackIndex1,unpackLoop1)
wire signed [DATA_WIDTH-1:0] in2 [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(DATA_WIDTH,BLOCKLENGTH,in2,data_in2,unpackIndex2,unpackLoop2)
reg signed [DATA_WIDTH-1:0] inReg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] inReg2 [0:BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			inReg1[i] <= 0;
			inReg2[i] <= 0;
		end else if (1'b1 == enable) begin
			inReg1[i] <= in1[i];
			inReg2[i] <= in2[i];			
		end
	end
end

//COMPARE THE INPUTS
reg [0:BLOCKLENGTH-1] gtIndicator; 
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		gtIndicator <= 0;
	end else if (1'b1 == enable) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			gtIndicator[i] <= inReg1[i] > inReg2[i];			
		end
	end
end

//keep the second input vector so we can select from it later
reg signed [DATA_WIDTH-1:0] in2_keeper1 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			in2_keeper1[i] <= 0;
		end else if (1'b1 == enable) begin
			in2_keeper1[i] <= inReg2[i];		
		end
	end
end

//CREATE ONE HOT VECTOR
//first do this variable bit slect thing since xst is ancient
//and wont let me do it in the always block. Or them together
//while we're at it since we need to anyway.
genvar j;
wire [0:BLOCKLENGTH-2] tempSignals ;
generate
	for(j = 0; j < BLOCKLENGTH-1; j = j+1) begin : VAR_LOOP
		assign tempSignals[j] = |gtIndicator[j+1:BLOCKLENGTH-1];
	end
endgenerate


reg [0:BLOCKLENGTH-1] oneHotSelector;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		oneHotSelector <= 0;
	end else if (1'b1 == enable) begin
		oneHotSelector[BLOCKLENGTH-1] <= gtIndicator[BLOCKLENGTH-1];
		//the ith out bit is high if the ith in bit is high and
		//all input bits above are low
		for(i = 0; i<BLOCKLENGTH-1; i=i+1 ) begin
			oneHotSelector[i] <= gtIndicator[i] & (~tempSignals[i]);	
		end
	end
end

//keep the second input vector
reg signed [DATA_WIDTH-1:0] in2_keeper2 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			in2_keeper2[i] <= 0;
		end else if (1'b1 == enable) begin
			in2_keeper2[i] <= in2_keeper1[i];		
		end
	end
end


//SELECT THE VALUE WE WANT FROM THE SECOND VECTOR
wire signed [DATA_WIDTH-1:0] selection;
genvar i2;
generate
	for(i2 = 0; i2 < BLOCKLENGTH; i2 = i2+1) begin : SELECT_LOOP
		assign selection = oneHotSelector[i2] ? in2_keeper2[i2] : {(DATA_WIDTH){1'bZ}};
	end
endgenerate

reg signed [DATA_WIDTH-1:0] selectionReg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		selectionReg <= 0;
	end else if (1'b1 == enable) begin
		selectionReg <= selection;		
	end
end

//OUTPUT OUR SELECTION
assign selection_out = selectionReg;

endmodule



`endif //_my_project_simplex_