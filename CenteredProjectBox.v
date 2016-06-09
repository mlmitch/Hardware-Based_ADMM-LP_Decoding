`ifndef _my_centered_project_box_
`define _my_centered_project_box_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the projection onto the 0 centered unit box.

FRACTION_WIDTH_IN can be any positive number < DATA_WIDTH
assume FRACTION_WIDTH_OUT >= FRACTION_WIDTH_IN
FRACTION_WIDTH_OUT > 0
*/

`include "2dArrayMacros.v"

module CenteredProjectBox # 
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
localparam OUT_FRACTION_WIDTH = DATA_WIDTH-1;
localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

//create vectors for projection comparison
localparam IN_INTEGER_WIDTH = DATA_WIDTH - IN_FRACTION_WIDTH -1;
localparam OUT_INTEGER_WIDTH = DATA_WIDTH - OUT_FRACTION_WIDTH -1; //= 0
wire signed [DATA_WIDTH-1:0] IN_HALF;
wire signed [DATA_WIDTH-1:0] OUT_HALF;
assign OUT_HALF = {1'b0,1'b1,{(OUT_FRACTION_WIDTH-1){1'b0}}};
assign IN_HALF = {{(IN_INTEGER_WIDTH+1){1'b0}},1'b1,{(IN_FRACTION_WIDTH-1){1'b0}}};

//BRING IN INPUT
wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
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

//PROJECT ONTO THE BOX
wire signed [DATA_WIDTH-1:0] outFractions [0:BLOCKLENGTH-1];
wire [0:BLOCKLENGTH-1] belowNegHalf;
wire [0:BLOCKLENGTH-1] aboveHalf;
genvar j;
generate
	for(j = 0; j < BLOCKLENGTH; j=j+1) begin : CAP_LOOP
		assign belowNegHalf[j] = reg0[j] <= -IN_HALF; 
		assign aboveHalf[j] = reg0[j] >= IN_HALF; //output >= 1/2
	
		//select fraction bits from subtraction and add appropiate number of zeros so this could be the chosen output
		//note that we are selecting with the assumption of 0 integer bits
		
		if(OUT_FRACTION_WIDTH > IN_FRACTION_WIDTH) begin
			assign outFractions[j] = {reg0[j][DATA_WIDTH-1], reg0[j][IN_FRACTION_WIDTH-1:0],{(OUT_FRACTION_WIDTH-IN_FRACTION_WIDTH){1'b0}}};
		end else begin
			assign outFractions[j] = {reg0[j][DATA_WIDTH-1], reg0[j][IN_FRACTION_WIDTH-1:0]};
		end		
	end
endgenerate


reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg1[i] <= 0;
		end else if (1'b1 == enable) begin
			reg1[i] <= 	belowNegHalf[i] ? -OUT_HALF :
						aboveHalf[i] ?  OUT_HALF :
						outFractions[i];
		end
	end
end

`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg1,data_out)

endmodule

`endif //_my_centered_project_box_