`ifndef _my_pipeline_train_
`define _my_pipeline_train_

/*
Mitch Wasson (mitch.wasson@gmail.com)

The purpose of the pipeline train is to eliminate redundant code that propagates 
pipeline book keeping information like tags and valid signals.

This module also takes care of pipeline advancement control since it will be the 
same in all modules that require pipeline book keeping advancement.

This way all complicated logic comes in here and the calculation pipeline
can use the enable signal internally.
*/

module PipelineTrain # //wrapper for the various circuits
(
	parameter TAG_WIDTH = 32,
	parameter NUM_REGISTERS	= 10 //number of registers on the pipeline train
) 
(
	input clk,
	input reset,
	input valid_in,
	input ready_in,
	input [TAG_WIDTH-1:0] tag_in,
	
	output valid_out,
	output ready_out,
	output busy,
	output enable,
	output [TAG_WIDTH-1:0] tag_out
);

reg [0:NUM_REGISTERS-1] validReg;

//we are capable of advancing the pipeline if the next module is taking an input
//or our current output is invalid
assign ready_out = ready_in | ~validReg[NUM_REGISTERS-1];

//advance the pipeline if we are ready to
//however, there is no reason to advance if we aren't busy and the input is invalid
assign enable = ready_out & (busy | valid_in); 

//Each valid output is only marked as so for one output.
//Therefore mark as valid if it is valid and it will disappear 
//on the next positive edge. ie pipeline advancement
assign valid_out = validReg[NUM_REGISTERS-1] & enable;

//Shift register to manage valids; //0 gets input, NUM_REGISTERS-1 is output
wire [0:NUM_REGISTERS-1] nextValidReg;
generate
	if(NUM_REGISTERS > 1) begin
		assign nextValidReg = {valid_in,validReg[0:NUM_REGISTERS-2]};
	end else begin
		assign nextValidReg = valid_in; //special case if only 1 pipeline stage
	end
endgenerate

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		validReg <= 0;
	end else if (1'b1 == enable) begin
		validReg <= nextValidReg;
	end
end

//Busy output tells if any valid computations are taking place
assign busy = | validReg; //ors all bits together

//Tag shift register. Similar to valid. Propogate tag along
reg [TAG_WIDTH-1:0] tagReg [0:NUM_REGISTERS-1];
integer i;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		//need this reset value for the tag register...
		//we do some cheating with the tag register when we really
		//should have some sort of valid caluation peak port on the 
		//pipeline train.
		for(i = 0; i<NUM_REGISTERS; i=i+1 ) begin
			tagReg[i] <= 0;
		end
	end else if(1'b1 == enable) begin
		for(i = 1; i<NUM_REGISTERS; i=i+1 ) begin
			tagReg[i] <= tagReg[i-1];
		end
		tagReg[0] <= tag_in;
	end
end
assign tag_out = tagReg[NUM_REGISTERS-1];

endmodule

`endif //_my_pipeline_train_