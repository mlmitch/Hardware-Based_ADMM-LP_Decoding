`ifndef _my_prefix_adder_
`define _my_prefix_adder_

`include "2dArrayMacros.v"
`include "PipelineTrain.v"

/*
Mitch Wasson (mitch.wasson@gmail.com)

Prefix addition (all ith partial sums) implementation for up to length 8.
Based off of old Ladner and Fischer prefix operation paper

We assume enough bits have been given to the inputs to prevent overflow.

One add operation per pipeline layer.
*/

module PrefixAdder # //wrapper for the various circuits
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 1, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out 	
);

generate
	if (1 == BLOCKLENGTH) begin
		a1 #(	.TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	
	end else if(2 == BLOCKLENGTH) begin
		a2 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	end else if(3 == BLOCKLENGTH) begin
		a3 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);

	end else if(4 == BLOCKLENGTH) begin
		a4 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
															
	end else if(5 == BLOCKLENGTH) begin
		a5 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);

	end else if(6 == BLOCKLENGTH) begin
		a6 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	
	end else if(7 == BLOCKLENGTH) begin
		a7 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	
	end else if(8 == BLOCKLENGTH) begin
		a8 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);

	end else if(9 == BLOCKLENGTH) begin
		a9 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	end else if(15 == BLOCKLENGTH) begin
		a15 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);													
	end else if(16 == BLOCKLENGTH) begin
		a16 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	end else if(17 == BLOCKLENGTH) begin
		a17 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) adder(	clk, reset, ready_in, valid_in, tag_in, data_in,
															busy, ready_out, valid_out, tag_out, data_out);
	end
endgenerate

endmodule

module a1 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 1, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out	
);

//Pretty much a filler module.
assign data_out = data_in;
assign valid_out = valid_in;
assign ready_out = ready_in;
assign busy = 1'b0;
assign tag_out = tag_in;

endmodule

module a2 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 2, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		reg1[0] <= 0;
		reg1[1] <= 0;
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
	end
end

//output reg1
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg1,data_out)

endmodule

module a3 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 3, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 3;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
	end
end

//output reg2
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg2,data_out)

endmodule


module a4 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 4, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 3;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[2] + reg0[3];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[1] + reg1[3];
	end
end

//output reg2
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg2,data_out)

endmodule

module a5 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 5, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[3];
		reg1[4] <= reg0[3] + reg0[4];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[3];
		reg2[4] <= reg1[4];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[2] + reg2[3];
		reg3[4] <= reg2[2] + reg2[4];
	end
end

//output reg3
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg3,data_out)

endmodule

module a6 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 6, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[3];
		reg1[4] <= reg0[3] + reg0[4];
		reg1[5] <= reg0[5];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[4] + reg1[5];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[2] + reg2[3];
		reg3[4] <= reg2[2] + reg2[4];
		reg3[5] <= reg2[2] + reg2[5];
	end
end

//output reg3
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg3,data_out)

endmodule

module a7 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 7, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[2] + reg0[3];
		reg1[4] <= reg0[4];
		reg1[5] <= reg0[4] + reg0[5];
		reg1[6] <= reg0[6];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[1] + reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[5];
		reg2[6] <= reg1[5] + reg1[6];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[3];
		reg3[4] <= reg2[3] + reg2[4];
		reg3[5] <= reg2[3] + reg2[5];
		reg3[6] <= reg2[3] + reg2[6];
	end
end

//output reg3
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg3,data_out)

endmodule

module a8 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 8, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[2] + reg0[3];
		reg1[4] <= reg0[4];
		reg1[5] <= reg0[4] + reg0[5];
		reg1[6] <= reg0[6];
		reg1[7] <= reg0[6] + reg0[7];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[1] + reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[5];
		reg2[6] <= reg1[5] + reg1[6];
		reg2[7] <= reg1[5] + reg1[7];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[3];
		reg3[4] <= reg2[3] + reg2[4];
		reg3[5] <= reg2[3] + reg2[5];
		reg3[6] <= reg2[3] + reg2[6];
		reg3[7] <= reg2[3] + reg2[7];
	end
end

//output reg3
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg3,data_out)

endmodule

module a9 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 9, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 5;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
			reg4[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[3];
		reg1[4] <= reg0[3] + reg0[4];
		reg1[5] <= reg0[5];
		reg1[6] <= reg0[5] + reg0[6];
		reg1[7] <= reg0[7];
		reg1[8] <= reg0[7] + reg0[8];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[5];
		reg2[6] <= reg1[6];
		reg2[7] <= reg1[6] + reg1[7];
		reg2[8] <= reg1[6] + reg1[8];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[2] + reg2[3];
		reg3[4] <= reg2[2] + reg2[4];
		reg3[5] <= reg2[5];
		reg3[6] <= reg2[6];
		reg3[7] <= reg2[7];
		reg3[8] <= reg2[8];
		
		reg4[0] <= reg3[0];
		reg4[1] <= reg3[1];
		reg4[2] <= reg3[2];
		reg4[3] <= reg3[3];
		reg4[4] <= reg3[4];
		reg4[5] <= reg3[4] + reg3[5];
		reg4[6] <= reg3[4] + reg3[6];
		reg4[7] <= reg3[4] + reg3[7];
		reg4[8] <= reg3[4] + reg3[8];		
		
	end
end

//output reg4
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg4,data_out)

endmodule


//15 input prefix sum module
module a15 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 15, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 5;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
			reg4[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[2] + reg0[3];
		reg1[4] <= reg0[4];
		reg1[5] <= reg0[4] + reg0[5];
		reg1[6] <= reg0[6];
		reg1[7] <= reg0[6] + reg0[7];
		reg1[8] <= reg0[8];
		reg1[9] <= reg0[8] + reg0[9];
		reg1[10] <= reg0[10];
		reg1[11] <= reg0[10] + reg0[11];
		reg1[12] <= reg0[12];
		reg1[13] <= reg0[12] + reg0[13];
		reg1[14] <= reg0[14];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[1] + reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[5];
		reg2[6] <= reg1[6];
		reg2[7] <= reg1[5] + reg1[7];
		reg2[8] <= reg1[8];
		reg2[9] <= reg1[9];
		reg2[10] <= reg1[9] + reg1[10];
		reg2[11] <= reg1[9] + reg1[11];
		reg2[12] <= reg1[12];
		reg2[13] <= reg1[13];
		reg2[14] <= reg1[13] + reg1[14];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[3];
		reg3[4] <= reg2[3] + reg2[4];
		reg3[5] <= reg2[3] + reg2[5];
		reg3[6] <= reg2[6];
		reg3[7] <= reg2[3] + reg2[7];
		reg3[8] <= reg2[8];
		reg3[9] <= reg2[9];
		reg3[10] <= reg2[10];
		reg3[11] <= reg2[11];
		reg3[12] <= reg2[11] + reg2[12];
		reg3[13] <= reg2[11] + reg2[13];
		reg3[14] <= reg2[11] + reg2[14];
		
		reg4[0] <= reg3[0];
		reg4[1] <= reg3[1];
		reg4[2] <= reg3[2];
		reg4[3] <= reg3[3];
		reg4[4] <= reg3[4];
		reg4[5] <= reg3[5];
		reg4[6] <= reg3[5] + reg3[6];
		reg4[7] <= reg3[7];
		reg4[8] <= reg3[7] + reg3[8];
		reg4[9] <= reg3[7] + reg3[9];
		reg4[10] <= reg3[7] + reg3[10];
		reg4[11] <= reg3[7] + reg3[11];
		reg4[12] <= reg3[7] + reg3[12];
		reg4[13] <= reg3[7] + reg3[13];
		reg4[14] <= reg3[7] + reg3[14];
		
	end
end

//output reg4
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg4,data_out)

endmodule


module a16 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 16, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 5;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
			reg4[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[2] + reg0[3];
		reg1[4] <= reg0[4];
		reg1[5] <= reg0[4] + reg0[5];
		reg1[6] <= reg0[6];
		reg1[7] <= reg0[6] + reg0[7];
		reg1[8] <= reg0[8];
		reg1[9] <= reg0[8] + reg0[9];
		reg1[10] <= reg0[10];
		reg1[11] <= reg0[10] + reg0[11];
		reg1[12] <= reg0[12];
		reg1[13] <= reg0[12] + reg0[13];
		reg1[14] <= reg0[14];
		reg1[15] <= reg0[14] + reg0[15];
		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[1] + reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[5];
		reg2[6] <= reg1[6];
		reg2[7] <= reg1[5] + reg1[7];
		reg2[8] <= reg1[8];
		reg2[9] <= reg1[9];
		reg2[10] <= reg1[9] + reg1[10];
		reg2[11] <= reg1[9] + reg1[11];
		reg2[12] <= reg1[12];
		reg2[13] <= reg1[13];
		reg2[14] <= reg1[13] + reg1[14];
		reg2[15] <= reg1[13] + reg1[15];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[3];
		reg3[4] <= reg2[3] + reg2[4];
		reg3[5] <= reg2[3] + reg2[5];
		reg3[6] <= reg2[6];
		reg3[7] <= reg2[3] + reg2[7];
		reg3[8] <= reg2[8];
		reg3[9] <= reg2[9];
		reg3[10] <= reg2[10];
		reg3[11] <= reg2[11];
		reg3[12] <= reg2[11] + reg2[12];
		reg3[13] <= reg2[11] + reg2[13];
		reg3[14] <= reg2[11] + reg2[14];
		reg3[15] <= reg2[11] + reg2[15];
		
		reg4[0] <= reg3[0];
		reg4[1] <= reg3[1];
		reg4[2] <= reg3[2];
		reg4[3] <= reg3[3];
		reg4[4] <= reg3[4];
		reg4[5] <= reg3[5];
		reg4[6] <= reg3[5] + reg3[6];
		reg4[7] <= reg3[7];
		reg4[8] <= reg3[7] + reg3[8];
		reg4[9] <= reg3[7] + reg3[9];
		reg4[10] <= reg3[7] + reg3[10];
		reg4[11] <= reg3[7] + reg3[11];
		reg4[12] <= reg3[7] + reg3[12];
		reg4[13] <= reg3[7] + reg3[13];
		reg4[14] <= reg3[7] + reg3[14];
		reg4[15] <= reg3[7] + reg3[15];
		
	end
end

//output reg4
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg4,data_out)

endmodule


module a17 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 17, 
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
	output [DATA_WIDTH*BLOCKLENGTH-1:0] data_out
);
localparam NUM_REGISTERS = 6;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] in [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,in,data_in)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];

//BRING IN INPUT
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

//addition operations.
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
			reg4[i] <= 0;
			reg5[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		reg1[0] <= reg0[0];
		reg1[1] <= reg0[0] + reg0[1];
		reg1[2] <= reg0[2];
		reg1[3] <= reg0[2] + reg0[3];
		reg1[4] <= reg0[4];
		reg1[5] <= reg0[4] + reg0[5];
		reg1[6] <= reg0[6];
		reg1[7] <= reg0[6] + reg0[7];
		reg1[8] <= reg0[8];
		reg1[9] <= reg0[9];
		reg1[10] <= reg0[9] + reg0[10];
		reg1[11] <= reg0[11];
		reg1[12] <= reg0[11] + reg0[12];
		reg1[13] <= reg0[13];
		reg1[14] <= reg0[13] + reg0[14];
		reg1[15] <= reg0[15];
		reg1[16] <= reg0[15] + reg0[16];

		
		reg2[0] <= reg1[0];
		reg2[1] <= reg1[1];
		reg2[2] <= reg1[1] + reg1[2];
		reg2[3] <= reg1[1] + reg1[3];
		reg2[4] <= reg1[4];
		reg2[5] <= reg1[5];
		reg2[6] <= reg1[6];
		reg2[7] <= reg1[7];
		reg2[8] <= reg1[7] + reg1[8];
		reg2[9] <= reg1[9];
		reg2[10] <= reg1[10];
		reg2[11] <= reg1[10] + reg1[11];
		reg2[12] <= reg1[10] + reg1[12];
		reg2[13] <= reg1[13];
		reg2[14] <= reg1[14];
		reg2[15] <= reg1[14] + reg1[15];
		reg2[16] <= reg1[14] + reg1[16];
		
		reg3[0] <= reg2[0];
		reg3[1] <= reg2[1];
		reg3[2] <= reg2[2];
		reg3[3] <= reg2[3];
		reg3[4] <= reg2[3] + reg2[4];
		reg3[5] <= reg2[3] + reg2[5];
		reg3[6] <= reg2[6];
		reg3[7] <= reg2[7];
		reg3[8] <= reg2[8];
		reg3[9] <= reg2[9];
		reg3[10] <= reg2[10];
		reg3[11] <= reg2[11];
		reg3[12] <= reg2[12];
		reg3[13] <= reg2[12] + reg2[13];
		reg3[14] <= reg2[12] + reg2[14];
		reg3[15] <= reg2[12] + reg2[15];
		reg3[16] <= reg2[12] + reg2[16];
		
		reg4[0] <= reg3[0];
		reg4[1] <= reg3[1];
		reg4[2] <= reg3[2];
		reg4[3] <= reg3[3];
		reg4[4] <= reg3[4];
		reg4[5] <= reg3[5];
		reg4[6] <= reg3[5] + reg3[6];
		reg4[7] <= reg3[5] + reg3[7];
		reg4[8] <= reg3[5] + reg3[8];
		reg4[9] <= reg3[9];
		reg4[10] <= reg3[10];
		reg4[11] <= reg3[11];
		reg4[12] <= reg3[12];
		reg4[13] <= reg3[13];
		reg4[14] <= reg3[14];
		reg4[15] <= reg3[15];
		reg4[16] <= reg3[16];
		
		reg5[0] <= reg4[0];
		reg5[1] <= reg4[1];
		reg5[2] <= reg4[2];
		reg5[3] <= reg4[3];
		reg5[4] <= reg4[4];
		reg5[5] <= reg4[5];
		reg5[6] <= reg4[6];
		reg5[7] <= reg4[7];
		reg5[8] <= reg4[8];
		reg5[9] <= reg4[8] + reg4[9];
		reg5[10] <= reg4[8] + reg4[10];
		reg5[11] <= reg4[8] + reg4[11];
		reg5[12] <= reg4[8] + reg4[12];
		reg5[13] <= reg4[8] + reg4[13];
		reg5[14] <= reg4[8] + reg4[14];
		reg5[15] <= reg4[8] + reg4[15];
		reg5[16] <= reg4[8] + reg4[16];
	end
end

//output reg4
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg5,data_out)

endmodule

`endif //_my_prefix_adder_