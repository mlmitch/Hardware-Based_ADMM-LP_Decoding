`ifndef _my_out_select_
`define _my_out_select_

/*
Mitch Wasson (mitch.wasson@gmail.com)

*/

module OutSelect # 
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
	input selector,
	
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

reg [DATA_WIDTH*BLOCKLENGTH-1:0] in1;
reg [DATA_WIDTH*BLOCKLENGTH-1:0] in2;
reg selreg;

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		in1 <= 0;
		in2 <= 0;
		selreg <= 0;
	end else if (1'b1 == enable) begin
		in1 <= data_in1;
		in2 <= data_in2;
		selreg <= selector;
	end
end

reg [DATA_WIDTH*BLOCKLENGTH-1:0] out;

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		out <= 0;
	end else if (1'b1 == enable) begin
		out <= selreg ? in1 : in2;
	end
end

assign data_out = out;

endmodule

`endif //_my_out_select_
