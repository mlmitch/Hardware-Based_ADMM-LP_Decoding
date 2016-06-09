`ifndef _my_centered_cut_search_
`define _my_centered_cut_search_

/*
Mitch Wasson (mitch.wasson@gmail.com)

This module performs the projection onto the unit box.

Have to specify fixed point representation for this module.
This is dont by the FRACTION_WIDTH_IN and FRACTION_WIDTH_OUT parameters.

FRACTION_WIDTH_IN > 0.--taking in box projection so this is fine

*/

`include "2dArrayMacros.v"
`include "ArgMin.v"

module CenteredCutSearch # 
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
	output [0:BLOCKLENGTH-1] data_out	
);
localparam NUM_MIN_REGISTERS = log2(BLOCKLENGTH);
localparam NUM_REGISTERS = 3 + NUM_MIN_REGISTERS;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

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

//ADD EXTRA BIT SO TAKING NEGATIVE DOESNT MESS IT UP
localparam IN_INTEGER_WIDTH = DATA_WIDTH - IN_FRACTION_WIDTH - 1;
localparam SUB_FRACTION_WIDTH = IN_FRACTION_WIDTH;
localparam SUB_INTEGER_WIDTH = IN_INTEGER_WIDTH+1; //> 0
localparam SUB_DATA_WIDTH = SUB_INTEGER_WIDTH + SUB_FRACTION_WIDTH + 1;

//extend the input
wire signed [SUB_DATA_WIDTH-1:0] in_ext [0:BLOCKLENGTH-1];
genvar j;
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : extend_loop
		assign in_ext[j] = { reg0[j][DATA_WIDTH-1], reg0[j] };
	end
endgenerate


//GET THE INTITIAL f VECTOR AND ABSOLUTE VALUES OF SUBTRACTIONS
wire signed [SUB_DATA_WIDTH-1:0] neg [0:BLOCKLENGTH-1];
generate
	for(j=0;j<BLOCKLENGTH;j=j+1) begin : neg_loop
		assign neg[j] = in_ext[j][SUB_DATA_WIDTH-1] ? -in_ext[j] : in_ext[j]; //no overflow. imossible for in_ext to be most negative number.
	end
endgenerate

reg [SUB_DATA_WIDTH-2:0] reg2 [0:BLOCKLENGTH-1];
reg [0:BLOCKLENGTH-1] f0;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			f0[i] <= 0;
			reg2[i] <= 0;
		end else if (1'b1 == enable) begin
			f0[i] <= in_ext[i]>0; //f 
			reg2[i] <=  neg[i][SUB_DATA_WIDTH-2:0]; //take off sign bit
		end
	end
end

//FLIP A BIT IN THE f VECTOR IF NECESSARY
//send along f vector and calculate if we are going to flip a bit
//find the location of the min -- flipper is registered inside argmin
//note: need to store f1 and flipbit while min is found
reg [0:NUM_MIN_REGISTERS-1] fbits;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		fbits <= 0;
	end else if (1'b1 == enable) begin
		fbits <= {~(^f0),fbits[0:NUM_MIN_REGISTERS-2]};
	end
end

reg [0:BLOCKLENGTH-1] effs [0:NUM_MIN_REGISTERS-1];
always @(posedge clk, posedge reset) begin
	for(i=1;i<NUM_MIN_REGISTERS;i=i+1) begin
		if (1'b1 == reset) begin
			effs[i] <= 0;
		end else if (1'b1 == enable) begin
			effs[i] <= effs[i-1];
		end
	end
	if (1'b1 == reset) begin
		effs[0] <= 0;
	end else if (1'b1 == enable) begin
		effs[0] <= f0;
	end	
end


wire [(SUB_DATA_WIDTH-1)*BLOCKLENGTH-1:0] minIn;
`PACK_ARRAY(SUB_DATA_WIDTH-1,BLOCKLENGTH,reg2,minIn)
wire [0:BLOCKLENGTH-1] flipper;
ArgMin #(.BLOCKLENGTH(BLOCKLENGTH),
			.DATA_WIDTH(SUB_DATA_WIDTH-1)) amin(clk, reset, enable, minIn, flipper);


/* --old way of doing argmin

integer minLoc;
reg [SUB_DATA_WIDTH-2:0] min;

always @(posedge clk, posedge reset) begin
		
	if (1'b1 == reset) begin
		flipper <= 0;
		minLoc = 0;
		min=0;
	end else if (1'b1 == enable) begin
		min = reg2[0];
		minLoc = 0;
		for(i = 1; i<BLOCKLENGTH; i=i+1 ) begin
			if (reg2[i] < min) begin
				min = reg2[i];
				minLoc = i;
			end
		end
		flipper <= {1'b1,{(BLOCKLENGTH-1){1'b0}}} >> minLoc;
	end

end*/

//DO THE ACTUAL FLIPPING
reg [0:BLOCKLENGTH-1] fOut;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		fOut <= 0;
	end else if (1'b1 == enable) begin
		fOut <= effs[NUM_MIN_REGISTERS-1] ^ ({(BLOCKLENGTH){fbits[NUM_MIN_REGISTERS-1]}} & flipper); //only flip if flipBit indicates we should
	end
end

assign data_out = fOut;


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



`endif //_my_centered_cut_search_