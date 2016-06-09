`ifndef _my_centered_selection_test_
`define _my_centered_selection_test_

/*
Mitch Wasson (mitch.wasson@gmail.com)

Given an array of inputs, this module sums them up and checks if the sum  is >= 1
*/

`include "Summer.v"

module CenteredSelectionTest # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter DATA_WIDTH = 8,
	parameter FRACTION_WIDTH = 6
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
	output indicator	
);
localparam INTEGER_WIDTH = DATA_WIDTH - FRACTION_WIDTH -1;
localparam NUM_REGISTERS = 2 + log2(BLOCKLENGTH);

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

//register input
reg signed [DATA_WIDTH*BLOCKLENGTH-1:0] reg0;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		reg0 <= 0;
	end else if (1'b1 == enable) begin
		reg0 <= data_in;
	end
end

//perform the sum
wire signed [DATA_WIDTH-1:0] sumOut;
Summer #(.BLOCKLENGTH(BLOCKLENGTH), 
			.DATA_WIDTH(DATA_WIDTH)) sum(clk, reset, enable, reg0, sumOut);
			
//threshold at 1
wire signed [DATA_WIDTH-1:0] ONE_MINUS_D_OVER_2;
wire signed [DATA_WIDTH-1:0] ONE;
wire signed [DATA_WIDTH-1:0] D;
wire signed [DATA_WIDTH-1:0] D_OVER_2;
assign ONE = {{(INTEGER_WIDTH){1'b0}},1'b1,{(FRACTION_WIDTH){1'b0}}};
assign D = BLOCKLENGTH;
assign D_OVER_2 = {D[DATA_WIDTH-(FRACTION_WIDTH-1)-1:0],{(FRACTION_WIDTH-1){1'b0}}};
assign ONE_MINUS_D_OVER_2 = ONE - D_OVER_2;

reg out;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		out <= 0;
	end else if (1'b1 == enable) begin
		out <= sumOut >= ONE_MINUS_D_OVER_2;
	end
end

assign indicator = out;


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

`endif //_my_centered_selection_test_
