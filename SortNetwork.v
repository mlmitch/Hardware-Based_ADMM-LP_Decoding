`ifndef _my_sort_network_
`define _my_sort_network_

/*
Mitch Wasson (mitch.wasson@gmail.com)

Sorting module that sorts an array of signed numbers into descending order (ie location [0] has largest value)

Delay and Area optimal sorting networks up to length 8 from knuth's sorting and searching volume.
Plans to add up to length 16 delay optimal networks.

One compare/swap operation per pipeline layer.
*/

`include "2dArrayMacros.v"
`include "PipelineTrain.v"

module SortNetwork # //wrapper for the various circuits
(
	parameter TAG_WIDTH = 32,
	//The number of numbers to be sorted
	parameter BLOCKLENGTH	= 16, 
	//The number of bits given for the signed integers
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData 	
);

generate
	if (1 == BLOCKLENGTH) begin
		s1 #(	.TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
	
	end else if(2 == BLOCKLENGTH) begin
		s2 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
			
	end else if(3 == BLOCKLENGTH) begin
		s3 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
	end else if(4 == BLOCKLENGTH) begin
		s4 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
															
	end else if(5 == BLOCKLENGTH) begin
		s5 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);

	end else if(6 == BLOCKLENGTH) begin
		s6 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);

	end else if(7 == BLOCKLENGTH) begin
		s7 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);

	end else if(8 == BLOCKLENGTH) begin
		s8 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
															
	end else if(14 == BLOCKLENGTH) begin
		s14 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
	end else if(15 == BLOCKLENGTH) begin
		s15 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
	end else if(16 == BLOCKLENGTH) begin
		s16 #( .TAG_WIDTH(TAG_WIDTH),
				.BLOCKLENGTH(BLOCKLENGTH),
				.DATA_WIDTH(DATA_WIDTH)) sorter(	clk, reset, ready_in, valid_in, tag_in, unsortedData,
															busy, ready_out, valid_out, tag_out, sortedData);
	end
endgenerate

endmodule

//length 1 sorting module
module s1 #
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
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData 
);
//Pretty much a filler module.

assign sortedData = unsortedData;
assign valid_out = valid_in;
assign ready_out = ready_in;
assign busy = 1'b0;
assign tag_out = tag_in;

endmodule


//length 2 sorting module
module s2 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 2,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 2;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPOGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//REGISTER 1 - sorting logic for first layer
wire swapIndicator;
assign swapIndicator = reg0[0] < reg0[1];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		reg1[0] <= 0;
		reg1[1] <= 0;
	end else if (1'b1 == enable) begin
		reg1[0] <= swapIndicator ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator ? reg0[0] : reg0[1];
	end
end

//output reg1
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg1,sortedData_flat)

endmodule


//length 3 sorting module
module s3 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 3,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPAGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//ACTIVE SORTING PROPAGATIONS
wire swapIndicator1;
assign swapIndicator1 = reg0[0] < reg0[1];
wire swapIndicator2;
assign swapIndicator2 = reg1[0] < reg1[2];
wire swapIndicator3;
assign swapIndicator3 = reg2[1] < reg2[2];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		//first sort layer
		reg1[0] <= swapIndicator1 ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator1 ? reg0[0] : reg0[1];
		reg1[2] <= reg0[2];
		
		//second sort layer
		reg2[0] <= swapIndicator2 ? reg1[2] : reg1[0];
		reg2[2] <= swapIndicator2 ? reg1[0] : reg1[2];
		reg2[1] <= reg1[1];
		
		//third sort layer
		reg3[1] <= swapIndicator3 ? reg2[2] : reg2[1];
		reg3[2] <= swapIndicator3 ? reg2[1] : reg2[2];
		reg3[0] <= reg2[0];
	end
end


//output reg3
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg3,sortedData_flat)

endmodule


//length 4 sorting module
module s4 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 4,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 4;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);
wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPAGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//ACTIVE SORTING PROPAGATIONS
wire [0:1] swapIndicator1;
assign swapIndicator1[0] = reg0[0] < reg0[1];
assign swapIndicator1[1] = reg0[2] < reg0[3];
wire [0:1] swapIndicator2;
assign swapIndicator2[0] = reg1[0] < reg1[2];
assign swapIndicator2[1] = reg1[1] < reg1[3];
wire swapIndicator3;
assign swapIndicator3 = reg2[1] < reg2[2];
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		//first sort layer
		reg1[0] <= swapIndicator1[0] ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator1[0] ? reg0[0] : reg0[1];
		reg1[2] <= swapIndicator1[1] ? reg0[3] : reg0[2];
		reg1[3] <= swapIndicator1[1] ? reg0[2] : reg0[3];
		
		//second sort layer
		reg2[0] <= swapIndicator2[0] ? reg1[2] : reg1[0];
		reg2[2] <= swapIndicator2[0] ? reg1[0] : reg1[2];
		reg2[1] <= swapIndicator2[1] ? reg1[3] : reg1[1];
		reg2[3] <= swapIndicator2[1] ? reg1[1] : reg1[3];
		
		//third sort layer
		reg3[1] <= swapIndicator3 ? reg2[2] : reg2[1];
		reg3[2] <= swapIndicator3 ? reg2[1] : reg2[2];
		reg3[0] <= reg2[0];
		reg3[3] <= reg2[3];
	end
end

//output reg3
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg3,sortedData_flat)

endmodule

//length 5 sorting module
module s5 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 5,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 6;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);
wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPAGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//ACTIVE SORTING PROPAGATIONS
wire swapIndicator1 [0:1];
assign swapIndicator1[0] = reg0[0] < reg0[1];
assign swapIndicator1[1] = reg0[2] < reg0[3];

wire swapIndicator2 [0:1];
assign swapIndicator2[0] = reg1[0] < reg1[2];
assign swapIndicator2[1] = reg1[1] < reg1[4];

wire swapIndicator3 [0:1];
assign swapIndicator3[0] = reg2[0] < reg2[1];
assign swapIndicator3[1] = reg2[2] < reg2[3];

wire swapIndicator4 [0:1];
assign swapIndicator4[0] = reg3[1] < reg3[2];
assign swapIndicator4[1] = reg3[3] < reg3[4];

wire swapIndicator5;
assign swapIndicator5 = reg4[2] < reg4[3];

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
		//first sort layer
		reg1[0] <= swapIndicator1[0] ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator1[0] ? reg0[0] : reg0[1];
		reg1[2] <= swapIndicator1[1] ? reg0[3] : reg0[2];
		reg1[3] <= swapIndicator1[1] ? reg0[2] : reg0[3];
		reg1[4] <= reg0[4];
		
		//second sort layer
		reg2[0] <= swapIndicator2[0] ? reg1[2] : reg1[0];
		reg2[2] <= swapIndicator2[0] ? reg1[0] : reg1[2];
		reg2[1] <= swapIndicator2[1] ? reg1[4] : reg1[1];
		reg2[4] <= swapIndicator2[1] ? reg1[1] : reg1[4];
		reg2[3] <= reg1[3];
		
		//third sort layer
		reg3[0] <= swapIndicator3[0] ? reg2[1] : reg2[0];
		reg3[1] <= swapIndicator3[0] ? reg2[0] : reg2[1];
		reg3[2] <= swapIndicator3[1] ? reg2[3] : reg2[2];
		reg3[3] <= swapIndicator3[1] ? reg2[2] : reg2[3];
		reg3[4] <= reg2[4];
		
		//fourth sort layer
		reg4[1] <= swapIndicator4[0] ? reg3[2] : reg3[1];
		reg4[2] <= swapIndicator4[0] ? reg3[1] : reg3[2];
		reg4[3] <= swapIndicator4[1] ? reg3[4] : reg3[3];
		reg4[4] <= swapIndicator4[1] ? reg3[3] : reg3[4];
		reg4[0] <= reg3[0];
		
		//fifth sort layer
		reg5[2] <= swapIndicator5 ? reg4[3] : reg4[2];
		reg5[3] <= swapIndicator5 ? reg4[2] : reg4[3];
		reg5[0] <= reg4[0];
		reg5[1] <= reg4[1];
		reg5[4] <= reg4[4];

	end
end

//output reg5
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg5,sortedData_flat)

endmodule

//length 6 sorting module
module s6 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 6,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 6;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPAGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//ACTIVE SORTING PROPAGATIONS
wire swapIndicator1 [0:2];
assign swapIndicator1[0] = reg0[0] < reg0[1];
assign swapIndicator1[1] = reg0[2] < reg0[3];
assign swapIndicator1[2] = reg0[4] < reg0[5];

wire swapIndicator2 [0:2];
assign swapIndicator2[0] = reg1[0] < reg1[2];
assign swapIndicator2[1] = reg1[3] < reg1[5];
assign swapIndicator2[2] = reg1[1] < reg1[4];

wire swapIndicator3 [0:2];
assign swapIndicator3[0] = reg2[0] < reg2[1];
assign swapIndicator3[1] = reg2[2] < reg2[3];
assign swapIndicator3[2] = reg2[4] < reg2[5];

wire swapIndicator4 [0:1];
assign swapIndicator4[0] = reg3[1] < reg3[2];
assign swapIndicator4[1] = reg3[3] < reg3[4];

wire swapIndicator5;
assign swapIndicator5 = reg4[2] < reg4[3];

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
		//first sort layer
		reg1[0] <= swapIndicator1[0] ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator1[0] ? reg0[0] : reg0[1];
		reg1[2] <= swapIndicator1[1] ? reg0[3] : reg0[2];
		reg1[3] <= swapIndicator1[1] ? reg0[2] : reg0[3];
		reg1[4] <= swapIndicator1[2] ? reg0[5] : reg0[4];
		reg1[5] <= swapIndicator1[2] ? reg0[4] : reg0[5];
		
		//second sort layer
		reg2[0] <= swapIndicator2[0] ? reg1[2] : reg1[0];
		reg2[2] <= swapIndicator2[0] ? reg1[0] : reg1[2];
		reg2[3] <= swapIndicator2[1] ? reg1[5] : reg1[3];
		reg2[5] <= swapIndicator2[1] ? reg1[3] : reg1[5];
		reg2[1] <= swapIndicator2[2] ? reg1[4] : reg1[1];
		reg2[4] <= swapIndicator2[2] ? reg1[1] : reg1[4];
		
		//third sort layer
		reg3[0] <= swapIndicator3[0] ? reg2[1] : reg2[0];
		reg3[1] <= swapIndicator3[0] ? reg2[0] : reg2[1];
		reg3[2] <= swapIndicator3[1] ? reg2[3] : reg2[2];
		reg3[3] <= swapIndicator3[1] ? reg2[2] : reg2[3];
		reg3[4] <= swapIndicator3[2] ? reg2[5] : reg2[4];
		reg3[5] <= swapIndicator3[2] ? reg2[4] : reg2[5];

		//fourth sort layer
		reg4[1] <= swapIndicator4[0] ? reg3[2] : reg3[1];
		reg4[2] <= swapIndicator4[0] ? reg3[1] : reg3[2];
		reg4[3] <= swapIndicator4[1] ? reg3[4] : reg3[3];
		reg4[4] <= swapIndicator4[1] ? reg3[3] : reg3[4];
		reg4[0] <= reg3[0];
		reg4[5] <= reg3[5];
		
		//fifth sort layer
		reg5[2] <= swapIndicator5 ? reg4[3] : reg4[2];
		reg5[3] <= swapIndicator5 ? reg4[2] : reg4[3];
		reg5[0] <= reg4[0];
		reg5[1] <= reg4[1];
		reg5[4] <= reg4[4];
		reg5[5] <= reg4[5];

	end
end

//output reg5
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg5,sortedData_flat)

endmodule

//length 7 sorting module
module s7 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 7,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 7;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg6 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPAGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//ACTIVE SORTING PROPAGATIONS
wire swapIndicator1 [0:2];
assign swapIndicator1[0] = reg0[0] < reg0[1];
assign swapIndicator1[1] = reg0[2] < reg0[3];
assign swapIndicator1[2] = reg0[4] < reg0[5];

wire swapIndicator2 [0:2];
assign swapIndicator2[0] = reg1[0] < reg1[2];
assign swapIndicator2[1] = reg1[4] < reg1[6];
assign swapIndicator2[2] = reg1[1] < reg1[3];

wire swapIndicator3 [0:2];
assign swapIndicator3[0] = reg2[0] < reg2[4];
assign swapIndicator3[1] = reg2[1] < reg2[5];
assign swapIndicator3[2] = reg2[2] < reg2[6];

wire swapIndicator4 [0:1];
assign swapIndicator4[0] = reg3[1] < reg3[2];
assign swapIndicator4[1] = reg3[5] < reg3[6];

wire swapIndicator5 [0:1];
assign swapIndicator5[0] = reg4[2] < reg4[4];
assign swapIndicator5[1] = reg4[3] < reg4[5];

wire swapIndicator6 [0:2];
assign swapIndicator6[0] = reg5[1] < reg5[2];
assign swapIndicator6[1] = reg5[3] < reg5[4];
assign swapIndicator6[2] = reg5[5] < reg5[6];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
			reg4[i] <= 0;
			reg5[i] <= 0;
			reg6[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		//first sort layer
		reg1[0] <= swapIndicator1[0] ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator1[0] ? reg0[0] : reg0[1];
		reg1[2] <= swapIndicator1[1] ? reg0[3] : reg0[2];
		reg1[3] <= swapIndicator1[1] ? reg0[2] : reg0[3];
		reg1[4] <= swapIndicator1[2] ? reg0[5] : reg0[4];
		reg1[5] <= swapIndicator1[2] ? reg0[4] : reg0[5];
		reg1[6] <= reg0[6];
		
		//second sort layer
		reg2[0] <= swapIndicator2[0] ? reg1[2] : reg1[0];
		reg2[2] <= swapIndicator2[0] ? reg1[0] : reg1[2];
		reg2[4] <= swapIndicator2[1] ? reg1[6] : reg1[4];
		reg2[6] <= swapIndicator2[1] ? reg1[4] : reg1[6];
		reg2[1] <= swapIndicator2[2] ? reg1[3] : reg1[1];
		reg2[3] <= swapIndicator2[2] ? reg1[1] : reg1[3];
		reg2[5] <= reg1[5];
		
		//third sort layer
		reg3[0] <= swapIndicator3[0] ? reg2[4] : reg2[0];
		reg3[4] <= swapIndicator3[0] ? reg2[0] : reg2[4];
		reg3[1] <= swapIndicator3[1] ? reg2[5] : reg2[1];
		reg3[5] <= swapIndicator3[1] ? reg2[1] : reg2[5];
		reg3[2] <= swapIndicator3[2] ? reg2[6] : reg2[2];
		reg3[6] <= swapIndicator3[2] ? reg2[2] : reg2[6];
		reg3[3] <= reg2[3];

		//fourth sort layer
		reg4[1] <= swapIndicator4[0] ? reg3[2] : reg3[1];
		reg4[2] <= swapIndicator4[0] ? reg3[1] : reg3[2];
		reg4[5] <= swapIndicator4[1] ? reg3[6] : reg3[5];
		reg4[6] <= swapIndicator4[1] ? reg3[5] : reg3[6];
		reg4[0] <= reg3[0];
		reg4[3] <= reg3[3];
		reg4[4] <= reg3[4];
		
		//fifth sort layer
		reg5[2] <= swapIndicator5[0] ? reg4[4] : reg4[2];
		reg5[4] <= swapIndicator5[0] ? reg4[2] : reg4[4];
		reg5[3] <= swapIndicator5[1] ? reg4[5] : reg4[3];
		reg5[5] <= swapIndicator5[1] ? reg4[3] : reg4[5];
		reg5[0] <= reg4[0];
		reg5[1] <= reg4[1];
		reg5[6] <= reg4[6];
		
		//sixth sorting layer
		reg6[1] <= swapIndicator6[0] ? reg5[2] : reg5[1];
		reg6[2] <= swapIndicator6[0] ? reg5[1] : reg5[2];
		reg6[3] <= swapIndicator6[1] ? reg5[4] : reg5[3];
		reg6[4] <= swapIndicator6[1] ? reg5[3] : reg5[4];
		reg6[5] <= swapIndicator6[2] ? reg5[6] : reg5[5];
		reg6[6] <= swapIndicator6[2] ? reg5[5] : reg5[6];
		reg6[0] <= reg5[0];
	end
end

//output reg6
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg6,sortedData_flat)

endmodule

//length 8 sorting module
module s8 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 8,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 7;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//I don't think I can 3D array in verilog
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];
reg signed [DATA_WIDTH-1:0] reg6 [0:BLOCKLENGTH-1];

//NON-ACTIVE SORTING PROPAGATIONS
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//ACTIVE SORTING PROPAGATIONS
wire swapIndicator1 [0:3];
assign swapIndicator1[0] = reg0[0] < reg0[1];
assign swapIndicator1[1] = reg0[2] < reg0[3];
assign swapIndicator1[2] = reg0[4] < reg0[5];
assign swapIndicator1[3] = reg0[6] < reg0[7];

wire swapIndicator2 [0:3];
assign swapIndicator2[0] = reg1[0] < reg1[2];
assign swapIndicator2[1] = reg1[4] < reg1[6];
assign swapIndicator2[2] = reg1[1] < reg1[3];
assign swapIndicator2[3] = reg1[5] < reg1[7];

wire swapIndicator3 [0:3];
assign swapIndicator3[0] = reg2[0] < reg2[4];
assign swapIndicator3[1] = reg2[1] < reg2[5];
assign swapIndicator3[2] = reg2[2] < reg2[6];
assign swapIndicator3[3] = reg2[3] < reg2[7];

wire swapIndicator4 [0:1];
assign swapIndicator4[0] = reg3[1] < reg3[2];
assign swapIndicator4[1] = reg3[5] < reg3[6];

wire swapIndicator5 [0:1];
assign swapIndicator5[0] = reg4[2] < reg4[4];
assign swapIndicator5[1] = reg4[3] < reg4[5];

wire swapIndicator6 [0:2];
assign swapIndicator6[0] = reg5[1] < reg5[2];
assign swapIndicator6[1] = reg5[3] < reg5[4];
assign swapIndicator6[2] = reg5[5] < reg5[6];

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
			reg1[i] <= 0;
			reg2[i] <= 0;
			reg3[i] <= 0;
			reg4[i] <= 0;
			reg5[i] <= 0;
			reg6[i] <= 0;
		end
	end else if (1'b1 == enable) begin
		//first sort layer
		reg1[0] <= swapIndicator1[0] ? reg0[1] : reg0[0];
		reg1[1] <= swapIndicator1[0] ? reg0[0] : reg0[1];
		reg1[2] <= swapIndicator1[1] ? reg0[3] : reg0[2];
		reg1[3] <= swapIndicator1[1] ? reg0[2] : reg0[3];
		reg1[4] <= swapIndicator1[2] ? reg0[5] : reg0[4];
		reg1[5] <= swapIndicator1[2] ? reg0[4] : reg0[5];
		reg1[6] <= swapIndicator1[3] ? reg0[7] : reg0[6];
		reg1[7] <= swapIndicator1[3] ? reg0[6] : reg0[7];
		
		//second sort layer
		reg2[0] <= swapIndicator2[0] ? reg1[2] : reg1[0];
		reg2[2] <= swapIndicator2[0] ? reg1[0] : reg1[2];
		reg2[4] <= swapIndicator2[1] ? reg1[6] : reg1[4];
		reg2[6] <= swapIndicator2[1] ? reg1[4] : reg1[6];
		reg2[1] <= swapIndicator2[2] ? reg1[3] : reg1[1];
		reg2[3] <= swapIndicator2[2] ? reg1[1] : reg1[3];
		reg2[5] <= swapIndicator2[3] ? reg1[7] : reg1[5];
		reg2[7] <= swapIndicator2[3] ? reg1[5] : reg1[7];
		
		//third sort layer
		reg3[0] <= swapIndicator3[0] ? reg2[4] : reg2[0];
		reg3[4] <= swapIndicator3[0] ? reg2[0] : reg2[4];
		reg3[1] <= swapIndicator3[1] ? reg2[5] : reg2[1];
		reg3[5] <= swapIndicator3[1] ? reg2[1] : reg2[5];
		reg3[2] <= swapIndicator3[2] ? reg2[6] : reg2[2];
		reg3[6] <= swapIndicator3[2] ? reg2[2] : reg2[6];
		reg3[3] <= swapIndicator3[3] ? reg2[7] : reg2[3];
		reg3[7] <= swapIndicator3[3] ? reg2[3] : reg2[7];		

		//fourth sort layer
		reg4[1] <= swapIndicator4[0] ? reg3[2] : reg3[1];
		reg4[2] <= swapIndicator4[0] ? reg3[1] : reg3[2];
		reg4[5] <= swapIndicator4[1] ? reg3[6] : reg3[5];
		reg4[6] <= swapIndicator4[1] ? reg3[5] : reg3[6];
		reg4[0] <= reg3[0];
		reg4[3] <= reg3[3];
		reg4[4] <= reg3[4];
		reg4[7] <= reg3[7];
		
		//fifth sort layer
		reg5[2] <= swapIndicator5[0] ? reg4[4] : reg4[2];
		reg5[4] <= swapIndicator5[0] ? reg4[2] : reg4[4];
		reg5[3] <= swapIndicator5[1] ? reg4[5] : reg4[3];
		reg5[5] <= swapIndicator5[1] ? reg4[3] : reg4[5];
		reg5[0] <= reg4[0];
		reg5[1] <= reg4[1];
		reg5[6] <= reg4[6];
		reg5[7] <= reg4[7];
		
		//sixth sorting layer
		reg6[1] <= swapIndicator6[0] ? reg5[2] : reg5[1];
		reg6[2] <= swapIndicator6[0] ? reg5[1] : reg5[2];
		reg6[3] <= swapIndicator6[1] ? reg5[4] : reg5[3];
		reg6[4] <= swapIndicator6[1] ? reg5[3] : reg5[4];
		reg6[5] <= swapIndicator6[2] ? reg5[6] : reg5[5];
		reg6[6] <= swapIndicator6[2] ? reg5[5] : reg5[6];
		reg6[0] <= reg5[0];
		reg6[7] <= reg5[7];
	end
end

//output reg6
`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg6,sortedData_flat)

endmodule

//length 14 sorting module
module s14 #
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH = 14,
	parameter DATA_WIDTH = 8
) 
(
	input clk,
	input reset,
	input ready_in,
	input valid_in,
	input [TAG_WIDTH-1:0] tag_in,
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 10;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//NON-ACTIVE SORTING PROPAGATIONS
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end

//Layer 1
wire swapIndicator1 [0:7];
wire signed [DATA_WIDTH-1:0] postLayer1 [0:BLOCKLENGTH-1];

genvar i1;
generate
	for (i1=0; i1<7; i1=i1+1) begin : layer1 //8 swaps
		assign swapIndicator1[i1] = reg0[2*i1] < reg0[2*i1+1];
		assign postLayer1[2*i1] = swapIndicator1[i1] ? reg0[2*i1+1] : reg0[2*i1];
		assign postLayer1[2*i1+1] = swapIndicator1[i1] ? reg0[2*i1] : reg0[2*i1+1];	
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg1[i] <= 0;
		end else if (1'b1 == enable) begin
				reg1[i] <= postLayer1[i];
		end
	end
end

//Layer 2
wire swapIndicator2 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer2 [0:BLOCKLENGTH-1];

genvar i2;
generate
	for (i2=0; i2<3; i2=i2+1) begin : layer2 //8 swaps
		assign swapIndicator2[i2*2] = reg1[i2*4] < reg1[i2*4+2];
		assign postLayer2[i2*4] = swapIndicator2[i2*2] ? reg1[i2*4+2] : reg1[i2*4];
		assign postLayer2[i2*4+2] = swapIndicator2[i2*2] ? reg1[i2*4] : reg1[i2*4+2];
		
		assign swapIndicator2[i2*2+1] = reg1[i2*4+1] < reg1[i2*4+3];
		assign postLayer2[i2*4+1] = swapIndicator2[i2*2+1] ? reg1[i2*4+3] : reg1[i2*4+1];
		assign postLayer2[i2*4+3] = swapIndicator2[i2*2+1] ? reg1[i2*4+1] : reg1[i2*4+3];
	end
endgenerate

assign postLayer2[13] = reg1[13];
assign postLayer2[12] = reg1[12];

reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg2[i] <= 0;
		end else if (1'b1 == enable) begin
				reg2[i] <= postLayer2[i];
		end
	end
end


//Layer 3
wire swapIndicator3 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer3 [0:BLOCKLENGTH-1];

genvar i3;
generate
	for (i3=0; i3<4; i3=i3+1) begin : layer3 //4 swaps
		assign swapIndicator3[i3] = reg2[i3] < reg2[i3+4];
		assign postLayer3[i3] = swapIndicator3[i3] ? reg2[i3+4] : reg2[i3];
		assign postLayer3[i3+4] = swapIndicator3[i3] ? reg2[i3] : reg2[i3+4];
	end
endgenerate

assign postLayer3[10] = reg2[10];
assign postLayer3[11] = reg2[11];

assign swapIndicator3[4] = reg2[8] < reg2[12];
assign postLayer3[8] = swapIndicator3[4] ? reg2[12] : reg2[8];
assign postLayer3[12] = swapIndicator3[4] ? reg2[8] : reg2[12];

assign swapIndicator3[5] = reg2[9] < reg2[13];
assign postLayer3[9] = swapIndicator3[5] ? reg2[13] : reg2[9];
assign postLayer3[13] = swapIndicator3[5] ? reg2[9] : reg2[13];

reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg3[i] <= 0;
		end else if (1'b1 == enable) begin
				reg3[i] <= postLayer3[i];
		end
	end
end


//Layer 4
wire swapIndicator4 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer4 [0:BLOCKLENGTH-1];

assign postLayer4[7] = reg3[7];
assign postLayer4[6] = reg3[6];

genvar i4;
generate
	for (i4=0; i4<6; i4=i4+1) begin : layer4 //8 swaps
		assign swapIndicator4[i4] = reg3[i4] < reg3[i4+8];
		assign postLayer4[i4] = swapIndicator4[i4] ? reg3[i4+8] : reg3[i4];
		assign postLayer4[i4+8] = swapIndicator4[i4] ? reg3[i4] : reg3[i4+8];	
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg4[i] <= 0;
		end else if (1'b1 == enable) begin
				reg4[i] <= postLayer4[i];
		end
	end
end


//Layer 5
wire swapIndicator5 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer5 [0:BLOCKLENGTH-1];

assign postLayer5[0] = reg4[0];
assign postLayer5[13] = reg4[13];

assign swapIndicator5[0] = reg4[1] < reg4[2];
assign postLayer5[1] = swapIndicator5[0] ? reg4[2] : reg4[1];
assign postLayer5[2] = swapIndicator5[0] ? reg4[1] : reg4[2];

assign swapIndicator5[1] = reg4[3] < reg4[12];
assign postLayer5[3] = swapIndicator5[1] ? reg4[12] : reg4[3];
assign postLayer5[12] = swapIndicator5[1] ? reg4[3] : reg4[12];

assign swapIndicator5[2] = reg4[4] < reg4[8];
assign postLayer5[4] = swapIndicator5[2] ? reg4[8] : reg4[4];
assign postLayer5[8] = swapIndicator5[2] ? reg4[4] : reg4[8];

assign swapIndicator5[3] = reg4[5] < reg4[10];
assign postLayer5[5] = swapIndicator5[3] ? reg4[10] : reg4[5];
assign postLayer5[10] = swapIndicator5[3] ? reg4[5] : reg4[10];

assign swapIndicator5[4] = reg4[6] < reg4[9];
assign postLayer5[6] = swapIndicator5[4] ? reg4[9] : reg4[6];
assign postLayer5[9] = swapIndicator5[4] ? reg4[6] : reg4[9];

assign swapIndicator5[5] = reg4[7] < reg4[11];
assign postLayer5[7] = swapIndicator5[5] ? reg4[11] : reg4[7];
assign postLayer5[11] = swapIndicator5[5] ? reg4[7] : reg4[11];

reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg5[i] <= 0;
		end else if (1'b1 == enable) begin
				reg5[i] <= postLayer5[i];
		end
	end
end

//Layer 6
wire swapIndicator6 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer6 [0:BLOCKLENGTH-1];

assign postLayer6[0] = reg5[0];
assign postLayer6[11] = reg5[11];

assign swapIndicator6[0] = reg5[1] < reg5[4];
assign postLayer6[1] = swapIndicator6[0] ? reg5[4] : reg5[1];
assign postLayer6[4] = swapIndicator6[0] ? reg5[1] : reg5[4];

assign swapIndicator6[1] = reg5[2] < reg5[8];
assign postLayer6[2] = swapIndicator6[1] ? reg5[8] : reg5[2];
assign postLayer6[8] = swapIndicator6[1] ? reg5[2] : reg5[8];

assign swapIndicator6[2] = reg5[3] < reg5[10];
assign postLayer6[3] = swapIndicator6[2] ? reg5[10] : reg5[3];
assign postLayer6[10] = swapIndicator6[2] ? reg5[3] : reg5[10];

assign swapIndicator6[3] = reg5[5] < reg5[9];
assign postLayer6[5] = swapIndicator6[3] ? reg5[9] : reg5[5];
assign postLayer6[9] = swapIndicator6[3] ? reg5[5] : reg5[9];

assign swapIndicator6[4] = reg5[6] < reg5[12];
assign postLayer6[6] = swapIndicator6[4] ? reg5[12] : reg5[6];
assign postLayer6[12] = swapIndicator6[4] ? reg5[6] : reg5[12];

assign swapIndicator6[5] = reg5[7] < reg5[13];
assign postLayer6[7] = swapIndicator6[5] ? reg5[13] : reg5[7];
assign postLayer6[13] = swapIndicator6[5] ? reg5[7] : reg5[13];

reg signed [DATA_WIDTH-1:0] reg6 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg6[i] <= 0;
		end else if (1'b1 == enable) begin
				reg6[i] <= postLayer6[i];
		end
	end
end

//Layer 7
wire swapIndicator7 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer7 [0:BLOCKLENGTH-1];

assign postLayer7[0] = reg6[0];
assign postLayer7[1] = reg6[1];

genvar i7;
generate
	for (i7=0; i7<3; i7=i7+1) begin : layer7 //6 swaps
		assign swapIndicator7[i7] = reg6[4*i7+2] < reg6[4*i7+4];
		assign postLayer7[4*i7+2] = swapIndicator7[i7] ? reg6[4*i7+4] : reg6[4*i7+2];
		assign postLayer7[4*i7+4] = swapIndicator7[i7] ? reg6[4*i7+2] : reg6[4*i7+4];

		assign swapIndicator7[i7+3] = reg6[4*i7+3] < reg6[4*i7+5];
		assign postLayer7[4*i7+3] = swapIndicator7[i7+3] ? reg6[4*i7+5] : reg6[4*i7+3];
		assign postLayer7[4*i7+5] = swapIndicator7[i7+3] ? reg6[4*i7+3] : reg6[4*i7+5];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg7 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg7[i] <= 0;
		end else if (1'b1 == enable) begin
				reg7[i] <= postLayer7[i];
		end
	end
end


//Layer 8
wire swapIndicator8 [0:3];
wire signed [DATA_WIDTH-1:0] postLayer8 [0:BLOCKLENGTH-1];

assign postLayer8[0] = reg7[0];
assign postLayer8[1] = reg7[1];
assign postLayer8[2] = reg7[2];
assign postLayer8[4] = reg7[4];
assign postLayer8[11] = reg7[11];
assign postLayer8[13] = reg7[13];

genvar i8;
generate
	for (i8=0; i8<4; i8=i8+1) begin : layer8 //4 swaps
		assign swapIndicator8[i8] = reg7[2*i8+3] < reg7[2*i8+6];
		assign postLayer8[2*i8+3] = swapIndicator8[i8] ? reg7[2*i8+6] : reg7[2*i8+3];
		assign postLayer8[2*i8+6] = swapIndicator8[i8] ? reg7[2*i8+3] : reg7[2*i8+6];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg8 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg8[i] <= 0;
		end else if (1'b1 == enable) begin
				reg8[i] <= postLayer8[i];
		end
	end
end

//Layer 9
wire swapIndicator9 [0:4];
wire signed [DATA_WIDTH-1:0] postLayer9 [0:BLOCKLENGTH-1];

assign postLayer9[0] = reg8[0];
assign postLayer9[1] = reg8[1];
assign postLayer9[2] = reg8[2];
assign postLayer9[13] = reg8[13];

genvar i9;
generate
	for (i9=0; i9<5; i9=i9+1) begin : layer9 //4 swaps
		assign swapIndicator9[i9] = reg8[2*i9+3] < reg8[2*i9+4];
		assign postLayer9[2*i9+3] = swapIndicator9[i9] ? reg8[2*i9+4] : reg8[2*i9+3];
		assign postLayer9[2*i9+4] = swapIndicator9[i9] ? reg8[2*i9+3] : reg8[2*i9+4];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg9 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg9[i] <= 0;
		end else if (1'b1 == enable) begin
				reg9[i] <= postLayer9[i];
		end
	end
end

`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg9,sortedData_flat)

endmodule

//length 15 sorting module
module s15 #
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
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 10;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//NON-ACTIVE SORTING PROPAGATIONS
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end


//Layer 1
wire swapIndicator1 [0:7];
wire signed [DATA_WIDTH-1:0] postLayer1 [0:BLOCKLENGTH-1];

genvar i1;
generate
	for (i1=0; i1<7; i1=i1+1) begin : layer1 //8 swaps
		assign swapIndicator1[i1] = reg0[2*i1] < reg0[2*i1+1];
		assign postLayer1[2*i1] = swapIndicator1[i1] ? reg0[2*i1+1] : reg0[2*i1];
		assign postLayer1[2*i1+1] = swapIndicator1[i1] ? reg0[2*i1] : reg0[2*i1+1];	
	end
endgenerate

assign postLayer1[14] = reg0[14];

reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg1[i] <= 0;
		end else if (1'b1 == enable) begin
				reg1[i] <= postLayer1[i];
		end
	end
end

//Layer 2
wire swapIndicator2 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer2 [0:BLOCKLENGTH-1];

genvar i2;
generate
	for (i2=0; i2<3; i2=i2+1) begin : layer2 //8 swaps
		assign swapIndicator2[i2*2] = reg1[i2*4] < reg1[i2*4+2];
		assign postLayer2[i2*4] = swapIndicator2[i2*2] ? reg1[i2*4+2] : reg1[i2*4];
		assign postLayer2[i2*4+2] = swapIndicator2[i2*2] ? reg1[i2*4] : reg1[i2*4+2];
		
		assign swapIndicator2[i2*2+1] = reg1[i2*4+1] < reg1[i2*4+3];
		assign postLayer2[i2*4+1] = swapIndicator2[i2*2+1] ? reg1[i2*4+3] : reg1[i2*4+1];
		assign postLayer2[i2*4+3] = swapIndicator2[i2*2+1] ? reg1[i2*4+1] : reg1[i2*4+3];
	end
endgenerate

assign postLayer2[13] = reg1[13];

assign swapIndicator2[6] = reg1[12] < reg1[14];
assign postLayer2[12] = swapIndicator2[6] ? reg1[14] : reg1[12];
assign postLayer2[14] = swapIndicator2[6] ? reg1[12] : reg1[14];

reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg2[i] <= 0;
		end else if (1'b1 == enable) begin
				reg2[i] <= postLayer2[i];
		end
	end
end


//Layer 3
wire swapIndicator3 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer3 [0:BLOCKLENGTH-1];

genvar i3;
generate
	for (i3=0; i3<3; i3=i3+1) begin : layer3 //8 swaps
		assign swapIndicator3[i3] = reg2[i3] < reg2[i3+4];
		assign postLayer3[i3] = swapIndicator3[i3] ? reg2[i3+4] : reg2[i3];
		assign postLayer3[i3+4] = swapIndicator3[i3] ? reg2[i3] : reg2[i3+4];
		
		assign swapIndicator3[i3+4] = reg2[i3+8] < reg2[i3+12];
		assign postLayer3[i3+8] = swapIndicator3[i3+4] ? reg2[i3+12] : reg2[i3+8];
		assign postLayer3[i3+12] = swapIndicator3[i3+4] ? reg2[i3+8] : reg2[i3+12];
	end
endgenerate

assign postLayer3[11] = reg2[11];

assign swapIndicator3[3] = reg2[3] < reg2[7];
assign postLayer3[3] = swapIndicator3[3] ? reg2[7] : reg2[3];
assign postLayer3[7] = swapIndicator3[3] ? reg2[3] : reg2[7];

reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg3[i] <= 0;
		end else if (1'b1 == enable) begin
				reg3[i] <= postLayer3[i];
		end
	end
end


//Layer 4
wire swapIndicator4 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer4 [0:BLOCKLENGTH-1];

assign postLayer4[7] = reg3[7];

genvar i4;
generate
	for (i4=0; i4<7; i4=i4+1) begin : layer4 //8 swaps
		assign swapIndicator4[i4] = reg3[i4] < reg3[i4+8];
		assign postLayer4[i4] = swapIndicator4[i4] ? reg3[i4+8] : reg3[i4];
		assign postLayer4[i4+8] = swapIndicator4[i4] ? reg3[i4] : reg3[i4+8];	
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg4[i] <= 0;
		end else if (1'b1 == enable) begin
				reg4[i] <= postLayer4[i];
		end
	end
end


//Layer 5
wire swapIndicator5 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer5 [0:BLOCKLENGTH-1];

assign postLayer5[0] = reg4[0];

assign swapIndicator5[0] = reg4[1] < reg4[2];
assign postLayer5[1] = swapIndicator5[0] ? reg4[2] : reg4[1];
assign postLayer5[2] = swapIndicator5[0] ? reg4[1] : reg4[2];

assign swapIndicator5[1] = reg4[3] < reg4[12];
assign postLayer5[3] = swapIndicator5[1] ? reg4[12] : reg4[3];
assign postLayer5[12] = swapIndicator5[1] ? reg4[3] : reg4[12];

assign swapIndicator5[2] = reg4[4] < reg4[8];
assign postLayer5[4] = swapIndicator5[2] ? reg4[8] : reg4[4];
assign postLayer5[8] = swapIndicator5[2] ? reg4[4] : reg4[8];

assign swapIndicator5[3] = reg4[5] < reg4[10];
assign postLayer5[5] = swapIndicator5[3] ? reg4[10] : reg4[5];
assign postLayer5[10] = swapIndicator5[3] ? reg4[5] : reg4[10];

assign swapIndicator5[4] = reg4[6] < reg4[9];
assign postLayer5[6] = swapIndicator5[4] ? reg4[9] : reg4[6];
assign postLayer5[9] = swapIndicator5[4] ? reg4[6] : reg4[9];

assign swapIndicator5[5] = reg4[7] < reg4[11];
assign postLayer5[7] = swapIndicator5[5] ? reg4[11] : reg4[7];
assign postLayer5[11] = swapIndicator5[5] ? reg4[7] : reg4[11];

assign swapIndicator5[6] = reg4[13] < reg4[14];
assign postLayer5[13] = swapIndicator5[6] ? reg4[14] : reg4[13];
assign postLayer5[14] = swapIndicator5[6] ? reg4[13] : reg4[14];

reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg5[i] <= 0;
		end else if (1'b1 == enable) begin
				reg5[i] <= postLayer5[i];
		end
	end
end

//Layer 6
wire swapIndicator6 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer6 [0:BLOCKLENGTH-1];

assign postLayer6[0] = reg5[0];

assign swapIndicator6[0] = reg5[1] < reg5[4];
assign postLayer6[1] = swapIndicator6[0] ? reg5[4] : reg5[1];
assign postLayer6[4] = swapIndicator6[0] ? reg5[1] : reg5[4];

assign swapIndicator6[1] = reg5[2] < reg5[8];
assign postLayer6[2] = swapIndicator6[1] ? reg5[8] : reg5[2];
assign postLayer6[8] = swapIndicator6[1] ? reg5[2] : reg5[8];

assign swapIndicator6[2] = reg5[3] < reg5[10];
assign postLayer6[3] = swapIndicator6[2] ? reg5[10] : reg5[3];
assign postLayer6[10] = swapIndicator6[2] ? reg5[3] : reg5[10];

assign swapIndicator6[3] = reg5[5] < reg5[9];
assign postLayer6[5] = swapIndicator6[3] ? reg5[9] : reg5[5];
assign postLayer6[9] = swapIndicator6[3] ? reg5[5] : reg5[9];

assign swapIndicator6[4] = reg5[6] < reg5[12];
assign postLayer6[6] = swapIndicator6[4] ? reg5[12] : reg5[6];
assign postLayer6[12] = swapIndicator6[4] ? reg5[6] : reg5[12];

assign swapIndicator6[5] = reg5[7] < reg5[13];
assign postLayer6[7] = swapIndicator6[5] ? reg5[13] : reg5[7];
assign postLayer6[13] = swapIndicator6[5] ? reg5[7] : reg5[13];

assign swapIndicator6[6] = reg5[11] < reg5[14];
assign postLayer6[11] = swapIndicator6[6] ? reg5[14] : reg5[11];
assign postLayer6[14] = swapIndicator6[6] ? reg5[11] : reg5[14];

reg signed [DATA_WIDTH-1:0] reg6 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg6[i] <= 0;
		end else if (1'b1 == enable) begin
				reg6[i] <= postLayer6[i];
		end
	end
end

//Layer 7
wire swapIndicator7 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer7 [0:BLOCKLENGTH-1];

assign postLayer7[0] = reg6[0];
assign postLayer7[1] = reg6[1];
assign postLayer7[14] = reg6[14];

genvar i7;
generate
	for (i7=0; i7<3; i7=i7+1) begin : layer7 //6 swaps
		assign swapIndicator7[i7] = reg6[4*i7+2] < reg6[4*i7+4];
		assign postLayer7[4*i7+2] = swapIndicator7[i7] ? reg6[4*i7+4] : reg6[4*i7+2];
		assign postLayer7[4*i7+4] = swapIndicator7[i7] ? reg6[4*i7+2] : reg6[4*i7+4];

		assign swapIndicator7[i7+3] = reg6[4*i7+3] < reg6[4*i7+5];
		assign postLayer7[4*i7+3] = swapIndicator7[i7+3] ? reg6[4*i7+5] : reg6[4*i7+3];
		assign postLayer7[4*i7+5] = swapIndicator7[i7+3] ? reg6[4*i7+3] : reg6[4*i7+5];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg7 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg7[i] <= 0;
		end else if (1'b1 == enable) begin
				reg7[i] <= postLayer7[i];
		end
	end
end


//Layer 8
wire swapIndicator8 [0:3];
wire signed [DATA_WIDTH-1:0] postLayer8 [0:BLOCKLENGTH-1];

assign postLayer8[0] = reg7[0];
assign postLayer8[1] = reg7[1];
assign postLayer8[2] = reg7[2];
assign postLayer8[4] = reg7[4];
assign postLayer8[11] = reg7[11];
assign postLayer8[13] = reg7[13];
assign postLayer8[14] = reg7[14];

genvar i8;
generate
	for (i8=0; i8<4; i8=i8+1) begin : layer8 //4 swaps
		assign swapIndicator8[i8] = reg7[2*i8+3] < reg7[2*i8+6];
		assign postLayer8[2*i8+3] = swapIndicator8[i8] ? reg7[2*i8+6] : reg7[2*i8+3];
		assign postLayer8[2*i8+6] = swapIndicator8[i8] ? reg7[2*i8+3] : reg7[2*i8+6];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg8 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg8[i] <= 0;
		end else if (1'b1 == enable) begin
				reg8[i] <= postLayer8[i];
		end
	end
end

//Layer 9
wire swapIndicator9 [0:4];
wire signed [DATA_WIDTH-1:0] postLayer9 [0:BLOCKLENGTH-1];

assign postLayer9[0] = reg8[0];
assign postLayer9[1] = reg8[1];
assign postLayer9[2] = reg8[2];
assign postLayer9[13] = reg8[13];
assign postLayer9[14] = reg8[14];

genvar i9;
generate
	for (i9=0; i9<5; i9=i9+1) begin : layer9 //4 swaps
		assign swapIndicator9[i9] = reg8[2*i9+3] < reg8[2*i9+4];
		assign postLayer9[2*i9+3] = swapIndicator9[i9] ? reg8[2*i9+4] : reg8[2*i9+3];
		assign postLayer9[2*i9+4] = swapIndicator9[i9] ? reg8[2*i9+3] : reg8[2*i9+4];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg9 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg9[i] <= 0;
		end else if (1'b1 == enable) begin
				reg9[i] <= postLayer9[i];
		end
	end
end

`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg9,sortedData_flat)

endmodule

//length 16 sorting module
module s16 #
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
	input [DATA_WIDTH*BLOCKLENGTH-1:0] unsortedData_flat,
	
	output busy,
	output ready_out,
	output valid_out,
	output [TAG_WIDTH-1:0] tag_out,
	output [DATA_WIDTH*BLOCKLENGTH-1:0] sortedData_flat 
);
localparam NUM_REGISTERS = 10;

wire enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(	.TAG_WIDTH(TAG_WIDTH),
						.NUM_REGISTERS(NUM_REGISTERS)) chooChoo(	clk, reset, valid_in, ready_in, tag_in,
																				valid_out, ready_out, busy, enable, tag_out);

wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1];
`UNPACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,unsorted,unsortedData_flat)

//NON-ACTIVE SORTING PROPAGATIONS
reg signed [DATA_WIDTH-1:0] reg0 [0:BLOCKLENGTH-1];
integer i;
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
			reg0[i] <= 0;
		end else if (1'b1 == enable) begin
			reg0[i] <= unsorted[i];
		end
	end
end


//Layer 1
wire swapIndicator1 [0:7];
wire signed [DATA_WIDTH-1:0] postLayer1 [0:BLOCKLENGTH-1];

genvar i1;
generate
	for (i1=0; i1<8; i1=i1+1) begin : layer1 //8 swaps
		assign swapIndicator1[i1] = reg0[2*i1] < reg0[2*i1+1];
		assign postLayer1[2*i1] = swapIndicator1[i1] ? reg0[2*i1+1] : reg0[2*i1];
		assign postLayer1[2*i1+1] = swapIndicator1[i1] ? reg0[2*i1] : reg0[2*i1+1];	
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg1 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg1[i] <= 0;
		end else if (1'b1 == enable) begin
				reg1[i] <= postLayer1[i];
		end
	end
end

//Layer 2
wire swapIndicator2 [0:7];
wire signed [DATA_WIDTH-1:0] postLayer2 [0:BLOCKLENGTH-1];

genvar i2;
generate
	for (i2=0; i2<4; i2=i2+1) begin : layer2 //8 swaps
		assign swapIndicator2[i2*2] = reg1[i2*4] < reg1[i2*4+2];
		assign postLayer2[i2*4] = swapIndicator2[i2*2] ? reg1[i2*4+2] : reg1[i2*4];
		assign postLayer2[i2*4+2] = swapIndicator2[i2*2] ? reg1[i2*4] : reg1[i2*4+2];
		
		assign swapIndicator2[i2*2+1] = reg1[i2*4+1] < reg1[i2*4+3];
		assign postLayer2[i2*4+1] = swapIndicator2[i2*2+1] ? reg1[i2*4+3] : reg1[i2*4+1];
		assign postLayer2[i2*4+3] = swapIndicator2[i2*2+1] ? reg1[i2*4+1] : reg1[i2*4+3];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg2 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg2[i] <= 0;
		end else if (1'b1 == enable) begin
				reg2[i] <= postLayer2[i];
		end
	end
end


//Layer 3
wire swapIndicator3 [0:7];
wire signed [DATA_WIDTH-1:0] postLayer3 [0:BLOCKLENGTH-1];

genvar i3;
generate
	for (i3=0; i3<4; i3=i3+1) begin : layer3 //8 swaps
		assign swapIndicator3[i3] = reg2[i3] < reg2[i3+4];
		assign postLayer3[i3] = swapIndicator3[i3] ? reg2[i3+4] : reg2[i3];
		assign postLayer3[i3+4] = swapIndicator3[i3] ? reg2[i3] : reg2[i3+4];
		
		assign swapIndicator3[i3+4] = reg2[i3+8] < reg2[i3+12];
		assign postLayer3[i3+8] = swapIndicator3[i3+4] ? reg2[i3+12] : reg2[i3+8];
		assign postLayer3[i3+12] = swapIndicator3[i3+4] ? reg2[i3+8] : reg2[i3+12];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg3 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg3[i] <= 0;
		end else if (1'b1 == enable) begin
				reg3[i] <= postLayer3[i];
		end
	end
end


//Layer 4
wire swapIndicator4 [0:7];
wire signed [DATA_WIDTH-1:0] postLayer4 [0:BLOCKLENGTH-1];

genvar i4;
generate
	for (i4=0; i4<8; i4=i4+1) begin : layer4 //8 swaps
		assign swapIndicator4[i4] = reg3[i4] < reg3[i4+8];
		assign postLayer4[i4] = swapIndicator4[i4] ? reg3[i4+8] : reg3[i4];
		assign postLayer4[i4+8] = swapIndicator4[i4] ? reg3[i4] : reg3[i4+8];	
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg4 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg4[i] <= 0;
		end else if (1'b1 == enable) begin
				reg4[i] <= postLayer4[i];
		end
	end
end


//Layer 5
wire swapIndicator5 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer5 [0:BLOCKLENGTH-1];

assign postLayer5[0] = reg4[0];
assign postLayer5[15] = reg4[15];

assign swapIndicator5[0] = reg4[1] < reg4[2];
assign postLayer5[1] = swapIndicator5[0] ? reg4[2] : reg4[1];
assign postLayer5[2] = swapIndicator5[0] ? reg4[1] : reg4[2];

assign swapIndicator5[1] = reg4[3] < reg4[12];
assign postLayer5[3] = swapIndicator5[1] ? reg4[12] : reg4[3];
assign postLayer5[12] = swapIndicator5[1] ? reg4[3] : reg4[12];

assign swapIndicator5[2] = reg4[4] < reg4[8];
assign postLayer5[4] = swapIndicator5[2] ? reg4[8] : reg4[4];
assign postLayer5[8] = swapIndicator5[2] ? reg4[4] : reg4[8];

assign swapIndicator5[3] = reg4[5] < reg4[10];
assign postLayer5[5] = swapIndicator5[3] ? reg4[10] : reg4[5];
assign postLayer5[10] = swapIndicator5[3] ? reg4[5] : reg4[10];

assign swapIndicator5[4] = reg4[6] < reg4[9];
assign postLayer5[6] = swapIndicator5[4] ? reg4[9] : reg4[6];
assign postLayer5[9] = swapIndicator5[4] ? reg4[6] : reg4[9];

assign swapIndicator5[5] = reg4[7] < reg4[11];
assign postLayer5[7] = swapIndicator5[5] ? reg4[11] : reg4[7];
assign postLayer5[11] = swapIndicator5[5] ? reg4[7] : reg4[11];

assign swapIndicator5[6] = reg4[13] < reg4[14];
assign postLayer5[13] = swapIndicator5[6] ? reg4[14] : reg4[13];
assign postLayer5[14] = swapIndicator5[6] ? reg4[13] : reg4[14];

reg signed [DATA_WIDTH-1:0] reg5 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg5[i] <= 0;
		end else if (1'b1 == enable) begin
				reg5[i] <= postLayer5[i];
		end
	end
end

//Layer 6
wire swapIndicator6 [0:6];
wire signed [DATA_WIDTH-1:0] postLayer6 [0:BLOCKLENGTH-1];

assign postLayer6[0] = reg5[0];
assign postLayer6[15] = reg5[15];

assign swapIndicator6[0] = reg5[1] < reg5[4];
assign postLayer6[1] = swapIndicator6[0] ? reg5[4] : reg5[1];
assign postLayer6[4] = swapIndicator6[0] ? reg5[1] : reg5[4];

assign swapIndicator6[1] = reg5[2] < reg5[8];
assign postLayer6[2] = swapIndicator6[1] ? reg5[8] : reg5[2];
assign postLayer6[8] = swapIndicator6[1] ? reg5[2] : reg5[8];

assign swapIndicator6[2] = reg5[3] < reg5[10];
assign postLayer6[3] = swapIndicator6[2] ? reg5[10] : reg5[3];
assign postLayer6[10] = swapIndicator6[2] ? reg5[3] : reg5[10];

assign swapIndicator6[3] = reg5[5] < reg5[9];
assign postLayer6[5] = swapIndicator6[3] ? reg5[9] : reg5[5];
assign postLayer6[9] = swapIndicator6[3] ? reg5[5] : reg5[9];

assign swapIndicator6[4] = reg5[6] < reg5[12];
assign postLayer6[6] = swapIndicator6[4] ? reg5[12] : reg5[6];
assign postLayer6[12] = swapIndicator6[4] ? reg5[6] : reg5[12];

assign swapIndicator6[5] = reg5[7] < reg5[13];
assign postLayer6[7] = swapIndicator6[5] ? reg5[13] : reg5[7];
assign postLayer6[13] = swapIndicator6[5] ? reg5[7] : reg5[13];

assign swapIndicator6[6] = reg5[11] < reg5[14];
assign postLayer6[11] = swapIndicator6[6] ? reg5[14] : reg5[11];
assign postLayer6[14] = swapIndicator6[6] ? reg5[11] : reg5[14];

reg signed [DATA_WIDTH-1:0] reg6 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg6[i] <= 0;
		end else if (1'b1 == enable) begin
				reg6[i] <= postLayer6[i];
		end
	end
end

//Layer 7
wire swapIndicator7 [0:5];
wire signed [DATA_WIDTH-1:0] postLayer7 [0:BLOCKLENGTH-1];

assign postLayer7[0] = reg6[0];
assign postLayer7[1] = reg6[1];
assign postLayer7[14] = reg6[14];
assign postLayer7[15] = reg6[15];

genvar i7;
generate
	for (i7=0; i7<3; i7=i7+1) begin : layer7 //6 swaps
		assign swapIndicator7[i7] = reg6[4*i7+2] < reg6[4*i7+4];
		assign postLayer7[4*i7+2] = swapIndicator7[i7] ? reg6[4*i7+4] : reg6[4*i7+2];
		assign postLayer7[4*i7+4] = swapIndicator7[i7] ? reg6[4*i7+2] : reg6[4*i7+4];

		assign swapIndicator7[i7+3] = reg6[4*i7+3] < reg6[4*i7+5];
		assign postLayer7[4*i7+3] = swapIndicator7[i7+3] ? reg6[4*i7+5] : reg6[4*i7+3];
		assign postLayer7[4*i7+5] = swapIndicator7[i7+3] ? reg6[4*i7+3] : reg6[4*i7+5];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg7 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg7[i] <= 0;
		end else if (1'b1 == enable) begin
				reg7[i] <= postLayer7[i];
		end
	end
end


//Layer 8
wire swapIndicator8 [0:3];
wire signed [DATA_WIDTH-1:0] postLayer8 [0:BLOCKLENGTH-1];

assign postLayer8[0] = reg7[0];
assign postLayer8[1] = reg7[1];
assign postLayer8[2] = reg7[2];
assign postLayer8[4] = reg7[4];
assign postLayer8[11] = reg7[11];
assign postLayer8[13] = reg7[13];
assign postLayer8[14] = reg7[14];
assign postLayer8[15] = reg7[15];

genvar i8;
generate
	for (i8=0; i8<4; i8=i8+1) begin : layer8 //4 swaps
		assign swapIndicator8[i8] = reg7[2*i8+3] < reg7[2*i8+6];
		assign postLayer8[2*i8+3] = swapIndicator8[i8] ? reg7[2*i8+6] : reg7[2*i8+3];
		assign postLayer8[2*i8+6] = swapIndicator8[i8] ? reg7[2*i8+3] : reg7[2*i8+6];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg8 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg8[i] <= 0;
		end else if (1'b1 == enable) begin
				reg8[i] <= postLayer8[i];
		end
	end
end

//Layer 9
wire swapIndicator9 [0:4];
wire signed [DATA_WIDTH-1:0] postLayer9 [0:BLOCKLENGTH-1];

assign postLayer9[0] = reg8[0];
assign postLayer9[1] = reg8[1];
assign postLayer9[2] = reg8[2];
assign postLayer9[13] = reg8[13];
assign postLayer9[14] = reg8[14];
assign postLayer9[15] = reg8[15];

genvar i9;
generate
	for (i9=0; i9<5; i9=i9+1) begin : layer9 //4 swaps
		assign swapIndicator9[i9] = reg8[2*i9+3] < reg8[2*i9+4];
		assign postLayer9[2*i9+3] = swapIndicator9[i9] ? reg8[2*i9+4] : reg8[2*i9+3];
		assign postLayer9[2*i9+4] = swapIndicator9[i9] ? reg8[2*i9+3] : reg8[2*i9+4];
	end
endgenerate

reg signed [DATA_WIDTH-1:0] reg9 [0:BLOCKLENGTH-1];
always @(posedge clk, posedge reset) begin
	for(i = 0; i<BLOCKLENGTH; i=i+1 ) begin
		if (1'b1 == reset) begin
				reg9[i] <= 0;
		end else if (1'b1 == enable) begin
				reg9[i] <= postLayer9[i];
		end
	end
end

`PACK_ARRAY(DATA_WIDTH,BLOCKLENGTH,reg9,sortedData_flat)

endmodule




`endif //_my_sort_network_