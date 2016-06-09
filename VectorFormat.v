`ifndef _my_vector_format_
`define _my_vector_format_


/*
Mitch Wasson (mitch.wasson@gmail.com)


*/

`include "2dArrayMacros.v"



/*Here we trim the vector checking for saturation.
We assume that OUT_INTEGER_WIDTH < IN_INTEGER_WIDTH
 */
module VectorTrim # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 1, 
	parameter IN_DATA_WIDTH = 8,
	parameter IN_FRACTION_WIDTH = 6,
	parameter OUT_DATA_WIDTH = 8,
	parameter OUT_FRACTION_WIDTH = 6
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

localparam IN_INTEGER_WIDTH = IN_DATA_WIDTH - IN_FRACTION_WIDTH - 1;
localparam OUT_INTEGER_WIDTH = OUT_DATA_WIDTH - OUT_FRACTION_WIDTH - 1;

localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
															valid_out, ready_out, busy, enable, tag_out);
															
//create reference vectors
wire signed [OUT_DATA_WIDTH-1:0] OUT_MAX;
wire signed [OUT_DATA_WIDTH-1:0] OUT_MIN;
assign OUT_MAX = {1'b0,{(OUT_DATA_WIDTH-1){1'b1}}};
assign OUT_MIN = -OUT_MAX;//{1'b1,{(OUT_DATA_WIDTH-1){1'b0}}};
wire signed [IN_DATA_WIDTH-1:0] IN_MAX;
wire signed [IN_DATA_WIDTH-1:0] IN_MIN;

generate 
	if(OUT_FRACTION_WIDTH >= IN_FRACTION_WIDTH) begin
		assign IN_MAX = {{(IN_INTEGER_WIDTH-OUT_INTEGER_WIDTH){OUT_MAX[OUT_DATA_WIDTH-1]}}, OUT_MAX[OUT_DATA_WIDTH-1:OUT_FRACTION_WIDTH], OUT_MAX[OUT_FRACTION_WIDTH-1:OUT_FRACTION_WIDTH-IN_FRACTION_WIDTH]};
		assign IN_MIN = -IN_MAX;//{{(IN_INTEGER_WIDTH-OUT_INTEGER_WIDTH){OUT_MIN[OUT_DATA_WIDTH-1]}}, OUT_MIN[OUT_DATA_WIDTH-1:OUT_FRACTION_WIDTH], OUT_MIN[OUT_FRACTION_WIDTH-1:OUT_FRACTION_WIDTH-IN_FRACTION_WIDTH]};
	end else begin
		assign IN_MAX = {{(IN_INTEGER_WIDTH-OUT_INTEGER_WIDTH){OUT_MAX[OUT_DATA_WIDTH-1]}}, OUT_MAX[OUT_DATA_WIDTH-1:0], {(IN_FRACTION_WIDTH-OUT_FRACTION_WIDTH){1'b0}}};
		assign IN_MIN = -IN_MAX;//{{(IN_INTEGER_WIDTH-OUT_INTEGER_WIDTH){OUT_MIN[OUT_DATA_WIDTH-1]}}, OUT_MIN[OUT_DATA_WIDTH-1:0], {(IN_FRACTION_WIDTH-OUT_FRACTION_WIDTH){1'b0}}};
	end
endgenerate

//take in inputs
wire signed [IN_DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY2(IN_DATA_WIDTH,BLOCKLENGTH,in,data_in,unpackIndex1,unpackLoop1)

reg signed [IN_DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg1[i] <= 0;
		end else if (1'b1 == enable) begin
			reg1[i] <= in[i];
		end
	end
end

//check for saturation and capture output
wire [0:BLOCKLENGTH-1] tooLow;
wire [0:BLOCKLENGTH-1] tooHigh;
wire signed [OUT_DATA_WIDTH-1:0] selection [0:BLOCKLENGTH-1];
genvar j;
generate
	for(j=0; j<BLOCKLENGTH; j=j+1) begin : satLoop
		//using <= and >= here guards against overflow in the rounding below
		assign tooLow[j] = (reg1[j] <= IN_MIN);
		assign tooHigh[j] = (reg1[j] >= IN_MAX);
		
		if(OUT_FRACTION_WIDTH > IN_FRACTION_WIDTH) begin
			assign selection[j] = {reg1[j][IN_FRACTION_WIDTH+OUT_INTEGER_WIDTH:0],{(OUT_FRACTION_WIDTH-IN_FRACTION_WIDTH){1'b0}}};
		end else if(OUT_FRACTION_WIDTH < IN_FRACTION_WIDTH) begin
			assign selection[j] = reg1[j][IN_FRACTION_WIDTH+OUT_INTEGER_WIDTH:IN_FRACTION_WIDTH-OUT_FRACTION_WIDTH] + {{(OUT_DATA_WIDTH-1){1'b0}}, reg1[j][IN_FRACTION_WIDTH-OUT_FRACTION_WIDTH-1]};
		end else begin
			assign selection[j] = reg1[j][IN_FRACTION_WIDTH+OUT_INTEGER_WIDTH:0];
		end
	end
endgenerate

reg signed [OUT_DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg2[i] <= 0;
		end else if (1'b1 == enable) begin
			reg2[i] <= tooLow[i] ? OUT_MIN :
						tooHigh[i] ? OUT_MAX :
						selection[i];
		end
	end
end

`PACK_ARRAY(OUT_DATA_WIDTH,BLOCKLENGTH,reg2,data_out)

endmodule


`endif //_my_vector_format_