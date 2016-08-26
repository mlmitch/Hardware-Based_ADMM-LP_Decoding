`ifndef _my_block_ram_
`define _my_block_ram_

`include "2dArrayMacros.v"
`include "PipelineTrain.v"

/*
Mitch Wasson (mitch.wasson@gmail.com)

These modules implement the storages for messages used in ADMM decoding -- Variable message
and Check message should be suitable for min-sum as well.
The top modules aggregate the simple block rams, allowing all relevant messages
to be accessed in parallel.

Each ram is configured with a read port and a write port. The difference between this modules 
is how the inputs/outputs are packed. When using any of theses module, create the buses of
numbers and pack these numbers into a flat array with the normal pack and unpack macros.

The ram access is piplelined in an effort to bring up clock frequency. Therefore it takes
more than one cycle before a requested read comes out of the read port.
Shouldn't be an issue though. Make use of tags.
*/


//really looks like xst doesnt want to infer rams. this will force it to.
//for SimpleRam2 there is a onle clock cycle latency on the read pipeline.
//This means that the read output is registered.
//XST was having a real hard time inferring block rams. This module does it explicitly.
/*module SimpleRam2 #
(
	parameter RAM_SIZE = 31,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input write_enable,
	input [ADDRESS_WIDTH-1:0] write_address, //assumed to be <RAM_SIZE
	input [DATA_WIDTH-1:0] write_data_in,
	
	input read_enable, 
	input [ADDRESS_WIDTH-1:0] read_address, //assumed to be <RAM_SIZE
	output [DATA_WIDTH-1:0] read_data_out
);


wire [15:0] intoRamData;
wire [15:0] outRamData;
generate
	if(16 == DATA_WIDTH) begin
		assign intoRamData = write_data_in;
	end else begin
		assign intoRamData = {{(16-DATA_WIDTH){1'b0}},write_data_in};
	end
endgenerate

//instantiate altera IP core. 26

generate
	if(RAM_SIZE <= 256) begin
		basicBlockRam mem(clk, write_enable, write_address[7:0], intoRamData, 
								clk, read_enable, read_address[7:0], outRamData);
	
	end
endgenerate

assign read_data_out = outRamData[DATA_WIDTH-1:0];

endmodule
*/

//basic ram. uses reg declarations currently. should infer block rams
module SimpleRam2 # 
(
	parameter RAM_SIZE = 31,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input write_enable,
	input [ADDRESS_WIDTH-1:0] write_address, //assumed to be <RAM_SIZE
	input [DATA_WIDTH-1:0] write_data_in,
	
	input read_enable, 
	input [ADDRESS_WIDTH-1:0] read_address, //assumed to be <RAM_SIZE
	output [DATA_WIDTH-1:0] read_data_out
);

reg [DATA_WIDTH-1:0] memory [0:RAM_SIZE-1];
reg [DATA_WIDTH-1:0] rData;

always @(posedge clk) begin
	if (write_enable) begin
		memory[write_address] <= write_data_in;
	end
end

always @(posedge clk) begin
	if (read_enable) begin
		rData <=  memory[read_address];
	end
end

assign read_data_out = rData;

endmodule

/*
VariableMessageRam is used to store messages from variable nodes to check nodes.

This is why there are Variable degree buses on the read port with each bus having check degree numbers
*/
module VariableMessageRam # 
(
	parameter TAG_WIDTH = 32,
	parameter RAM_SIZE = 31,
	parameter VARIABLE_DEGREE = 3,
	parameter CHECK_DEGREE = 5,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input reset,
	input [CHECK_DEGREE*VARIABLE_DEGREE*ADDRESS_WIDTH-1:0] ramOffsets_in, //address offset for each of the CHECK_DEGREE*VARIABLE_DEGREE rams. assumed <RAM_SIZE
	
	//read port pipeline -- this marks the start of the ckeck pipeline
	input read_ready_in,
	input read_valid_in,
	input [TAG_WIDTH-1:0] read_tag_in,
	input [ADDRESS_WIDTH-1:0] read_address, //assumed to be <RAM_SIZE
	
	output read_busy,
	output read_ready_out,
	output read_valid_out,
	output [TAG_WIDTH-1:0] read_tag_out,
	output [VARIABLE_DEGREE*CHECK_DEGREE*DATA_WIDTH-1:0] read_data_out, //VARIABLE_DEGREE buses. Each bus has CHECK_DEGREE numbers. 
	
	//write port pipeline -- this marks the end of the variable pipeline
	input write_valid_in,
	input [ADDRESS_WIDTH-1:0] write_address, //assumed to be <RAM_SIZE
	input [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_in, //CHECK_DEGREE buses. Each bus has VARIABLE_DEGREE numbers. 
	
	output write_busy,
	output write_ready_out
);

//MAKE RAM SHIFTS AVAILABLE
//picture this as the offsets starting in top left and going across the first row
//then second row and so on
wire [ADDRESS_WIDTH-1:0] ramOffsets [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
`UNPACK_ARRAY2(ADDRESS_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,ramOffsets,ramOffsets_in,unpackIndex1,unpackLoop1)

//READ PORT PIPELINE
localparam READ_NUM_REGISTERS = 4; //must be the same as the read port pipeline in check state ram

wire read_enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(READ_NUM_REGISTERS)) readChooChoo(clk, reset, read_valid_in, read_ready_in, read_tag_in,
																read_valid_out, read_ready_out, read_busy, read_enable, read_tag_out);

reg [ADDRESS_WIDTH-1:0] read_address_in_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		read_address_in_reg <= 0;
	end else if (1'b1 == read_enable) begin
		read_address_in_reg <= read_address;
	end
end

//calculate read addresses. checks are reading so need to add in offset.
reg [ADDRESS_WIDTH-1:0] calculatedReadAddresses_reg1 [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
reg [ADDRESS_WIDTH-1:0] calculatedReadAddresses_reg2 [0:CHECK_DEGREE*VARIABLE_DEGREE-1]; //these are the addresses we put into the simple rams.

integer i;
always @(posedge clk, posedge reset) begin
	for(i=0; i<CHECK_DEGREE*VARIABLE_DEGREE; i=i+1) begin
		if (1'b1 == reset) begin
			calculatedReadAddresses_reg1[i] <= 0;
			calculatedReadAddresses_reg2[i] <= 0;
		end else if (1'b1 == read_enable) begin
			calculatedReadAddresses_reg1[i] <= read_address_in_reg + ramOffsets[i];
			calculatedReadAddresses_reg2[i] <= (calculatedReadAddresses_reg1[i] < RAM_SIZE) ?  calculatedReadAddresses_reg1[i] : (calculatedReadAddresses_reg1[i] - RAM_SIZE);
		end
	end
end

//pack the values read from the ram.
//these are going to check nodes. Just use the normal array packing macros
wire [DATA_WIDTH-1:0] readValues [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
wire [VARIABLE_DEGREE*CHECK_DEGREE*DATA_WIDTH-1:0] readValues_flat;
`PACK_ARRAY2(DATA_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,readValues,readValues_flat,packIndex1,packLoop1)

assign read_data_out = readValues_flat;

//WRITE_PORT_PIPELINE
//the write port is viewed as the end of the variable node pipeline
//we should only write to the ram if the output of this pipeline is valid
//Therefore simple_ram_write_enable takes the place of the valid out

localparam WRITE_NUM_REGISTERS = 1; //this effects the busy signal. 

wire write_enable;
wire dummy_write_tag;
wire simple_ram_write_enable;

PipelineTrain #(.TAG_WIDTH(1),
				.NUM_REGISTERS(WRITE_NUM_REGISTERS)) writeChooChoo(clk, reset, write_valid_in, 1'b1, 1'b0, //always ready. tag set 0
																simple_ram_write_enable, write_ready_out, write_busy, write_enable, dummy_write_tag);

//register input
reg [ADDRESS_WIDTH-1:0] write_address_in_reg;
reg [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		write_address_in_reg <= 0;
		write_data_reg <= 0;
	end else if (1'b1 == write_enable) begin
		write_address_in_reg <= write_address;
		write_data_reg <= write_data_in;
	end
end

//Variables are writing here. we do not use the offsets in variable ram accesses.

//unpack the write values from the variable nodes. use different unpacking routine though.
wire [DATA_WIDTH-1:0] writeValues [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
`UNPACK_FROM_VARIABLE(DATA_WIDTH,CHECK_DEGREE,VARIABLE_DEGREE,writeValues,write_data_reg)

//INSTANTIATE THE SIMPLE RAMS
genvar j;
generate
	for(j=0; j<CHECK_DEGREE*VARIABLE_DEGREE; j=j+1) begin : ramInstantiateLoop
		SimpleRam2 #( .RAM_SIZE(RAM_SIZE),
					.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(ADDRESS_WIDTH)) sram(clk, simple_ram_write_enable, write_address_in_reg, writeValues[j],
					read_enable, calculatedReadAddresses_reg2[j], readValues[j]);
	end
endgenerate

endmodule

/*
This ram is for messages going from check node to variable node
*/
module CheckMessageRam # 
(
	parameter TAG_WIDTH = 32,
	parameter RAM_SIZE = 31,
	parameter VARIABLE_DEGREE = 3,
	parameter CHECK_DEGREE = 5,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input reset,
	input [CHECK_DEGREE*VARIABLE_DEGREE*ADDRESS_WIDTH-1:0] ramOffsets_in, //address offset for each of the CHECK_DEGREE*VARIABLE_DEGREE rams. assumed <RAM_SIZE
	
	//read port pipeline
	input read_ready_in,
	input read_valid_in,
	input [TAG_WIDTH-1:0] read_tag_in,
	input [ADDRESS_WIDTH-1:0] read_address, //assumed to be <RAM_SIZE
	
	output read_busy,
	output read_ready_out,
	output read_valid_out,
	output [TAG_WIDTH-1:0] read_tag_out,
	output [VARIABLE_DEGREE*CHECK_DEGREE*DATA_WIDTH-1:0] read_data_out, //VARIABLE_DEGREE buses. Each bus has CHECK_DEGREE numbers. 
	
	//write port pipeline
	input write_valid_in,
	input [ADDRESS_WIDTH-1:0] write_address, //assumed to be <RAM_SIZE
	input [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_in, //CHECK_DEGREE buses. Each bus has VARIABLE_DEGREE numbers. 
	
	output write_busy,
	output write_ready_out
);

//MAKE RAM SHIFTS AVAILABLE
//picture this as the offsets starting in top left and going across the first row
//then second row and so on
wire [ADDRESS_WIDTH-1:0] ramOffsets [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
`UNPACK_ARRAY2(ADDRESS_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,ramOffsets,ramOffsets_in,unpackIndex1,unpackLoop1)

//READ PORT PIPELINE
localparam READ_NUM_REGISTERS = 2; //must be the same as llr ram read

wire read_enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(READ_NUM_REGISTERS)) readChooChoo(clk, reset, read_valid_in, read_ready_in, read_tag_in,
																read_valid_out, read_ready_out, read_busy, read_enable, read_tag_out);

reg [ADDRESS_WIDTH-1:0] read_address_in_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		read_address_in_reg <= 0;
	end else if (1'b1 == read_enable) begin
		read_address_in_reg <= read_address;
	end
end

//variables reading here. don't need to deal with offsets.

//pack the values read from the ram.
//these are going to variable nodes. use the special packing macro
wire [DATA_WIDTH-1:0] readValues [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
wire [VARIABLE_DEGREE*CHECK_DEGREE*DATA_WIDTH-1:0] readValues_flat;
`PACK_TO_VARIABLE(DATA_WIDTH,CHECK_DEGREE,VARIABLE_DEGREE,readValues,readValues_flat)

assign read_data_out = readValues_flat;

//WRITE_PORT_PIPELINE
localparam WRITE_NUM_REGISTERS = 3; //this effects the busy signal. 

wire write_enable;
wire dummy_write_tag;
wire simple_ram_write_enable; //this takes the place of valid out of the pipeline. pipeline needs to be advancing for this to be high

PipelineTrain #(.TAG_WIDTH(1),
				.NUM_REGISTERS(WRITE_NUM_REGISTERS)) writeChooChoo(clk, reset, write_valid_in, 1'b1, 1'b0, //always ready. tag set 0
																simple_ram_write_enable, write_ready_out, write_busy, write_enable, dummy_write_tag);

//register input
reg [ADDRESS_WIDTH-1:0] write_address_in_reg;
reg [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_reg1;
reg [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_reg2;
reg [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_reg3;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		write_address_in_reg <= 0;
		write_data_reg1 <= 0;
		write_data_reg2 <= 0;
		write_data_reg3 <= 0;
	end else if (1'b1 == write_enable) begin
		write_address_in_reg <= write_address;
		write_data_reg1 <= write_data_in;
		write_data_reg2 <= write_data_reg1;
		write_data_reg3 <= write_data_reg2;
	end
end

//calculate write addresses
reg [ADDRESS_WIDTH-1:0] calculatedWriteAddresses_reg1 [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
reg [ADDRESS_WIDTH-1:0] calculatedWriteAddresses_reg2 [0:CHECK_DEGREE*VARIABLE_DEGREE-1];

integer i;
always @(posedge clk, posedge reset) begin
	for(i=0; i<CHECK_DEGREE*VARIABLE_DEGREE; i=i+1) begin
		if (1'b1 == reset) begin
			calculatedWriteAddresses_reg1[i] <= 0;
			calculatedWriteAddresses_reg2[i] <= 0;
		end else if (1'b1 == write_enable) begin
			calculatedWriteAddresses_reg1[i] <= write_address_in_reg + ramOffsets[i];
			calculatedWriteAddresses_reg2[i] <= (calculatedWriteAddresses_reg1[i] < RAM_SIZE) ?  calculatedWriteAddresses_reg1[i] : calculatedWriteAddresses_reg1[i] - RAM_SIZE;
		end
	end
end

//unpack the write values from the check nodes.
//use the regular unpacking routine
wire [DATA_WIDTH-1:0] writeValues [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
`UNPACK_ARRAY2(DATA_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,writeValues,write_data_reg3,unpackIndex2,unpackLoop2)


//INSTANTIATE THE SIMPLE RAMS
genvar j;
generate
	for(j=0; j<CHECK_DEGREE*VARIABLE_DEGREE; j=j+1) begin : ramInstantiateLoop
		SimpleRam2 #( .RAM_SIZE(RAM_SIZE),
					.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(ADDRESS_WIDTH)) sram(clk, simple_ram_write_enable, calculatedWriteAddresses_reg2[j], writeValues[j],
															read_enable, read_address_in_reg, readValues[j]);
	end
endgenerate

endmodule

/*
CheckStateRam is used to store the duals variables for check computations in ADMM decoding.
It has a read and a write port. We don't need the offsets for the ram though since both reads 
and writes interact with the checks. The reason we have to use the shifts on the 
other rams is so mesages get all mixed up to and from the variables.
*/
module CheckStateRam # 
(
	parameter TAG_WIDTH = 32,
	parameter RAM_SIZE = 31,
	parameter VARIABLE_DEGREE = 3,
	parameter CHECK_DEGREE = 5,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input reset,
	
	//read port pipeline
	input read_ready_in,
	input read_valid_in,
	input [TAG_WIDTH-1:0] read_tag_in,
	input [ADDRESS_WIDTH-1:0] read_address, //assumed to be <RAM_SIZE
	
	output read_busy,
	output read_ready_out,
	output read_valid_out,
	output [TAG_WIDTH-1:0] read_tag_out,
	output [VARIABLE_DEGREE*CHECK_DEGREE*DATA_WIDTH-1:0] read_data_out, //VARIABLE_DEGREE buses. Each bus has CHECK_DEGREE numbers. 
	
	//write port pipeline
	input write_valid_in,
	input [ADDRESS_WIDTH-1:0] write_address, //assumed to be <RAM_SIZE
	input [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_in, //CHECK_DEGREE buses. Each bus has VARIABLE_DEGREE numbers. 
	
	output write_busy,
	output write_ready_out
);

//READ PORT PIPELINE
//this should be the same number as the read port on the variable 
//message storage
localparam READ_NUM_REGISTERS = 4; //this has to be 4 because we have to add in offsets when reading variable messages

wire read_enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(READ_NUM_REGISTERS)) readChooChoo(clk, reset, read_valid_in, read_ready_in, read_tag_in,
																read_valid_out, read_ready_out, read_busy, read_enable, read_tag_out);

reg [ADDRESS_WIDTH-1:0] read_address_in_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		read_address_in_reg <= 0;
	end else if (1'b1 == read_enable) begin
		read_address_in_reg <= read_address;
	end
end

//calculate read addresses
reg [ADDRESS_WIDTH-1:0] calculatedReadAddresses_reg1;
reg [ADDRESS_WIDTH-1:0] calculatedReadAddresses_reg2; //these are the addresses we put into the simple rams.

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		calculatedReadAddresses_reg1 <= 0;
		calculatedReadAddresses_reg2 <= 0;
	end else if (1'b1 == read_enable) begin
		calculatedReadAddresses_reg1 <= read_address_in_reg;
		calculatedReadAddresses_reg2 <= calculatedReadAddresses_reg1;
	end
end

//pack the values read from the ram.
//these are going to variable nodes. use the special packing macro
wire [DATA_WIDTH-1:0] readValues [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
wire [VARIABLE_DEGREE*CHECK_DEGREE*DATA_WIDTH-1:0] readValues_flat;
`PACK_ARRAY2(DATA_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,readValues,readValues_flat,packIndex1,packLoop1)

assign read_data_out = readValues_flat;

//WRITE_PORT_PIPELINE
localparam WRITE_NUM_REGISTERS = 1; 

wire write_enable;
wire dummy_write_tag;
wire simple_ram_write_enable; //this takes the place of valid out of the pipeline. pipeline needs to be advancing for this to be high

PipelineTrain #(.TAG_WIDTH(1),
				.NUM_REGISTERS(WRITE_NUM_REGISTERS)) writeChooChoo(clk, reset, write_valid_in, 1'b1, 1'b0, //always ready. tag set 0
																simple_ram_write_enable, write_ready_out, write_busy, write_enable, dummy_write_tag);

//register input
reg [ADDRESS_WIDTH-1:0] write_address_in_reg;
reg [CHECK_DEGREE*VARIABLE_DEGREE*DATA_WIDTH-1:0] write_data_reg1;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		write_address_in_reg <= 0;
		write_data_reg1 <= 0;
	end else if (1'b1 == write_enable) begin
		write_address_in_reg <= write_address;
		write_data_reg1 <= write_data_in;
	end
end

//unpack the write values from the check nodes.
//use the regular unpacking routine
wire [DATA_WIDTH-1:0] writeValues [0:CHECK_DEGREE*VARIABLE_DEGREE-1];
`UNPACK_ARRAY2(DATA_WIDTH,CHECK_DEGREE*VARIABLE_DEGREE,writeValues,write_data_reg1,unpackIndex2,unpackLoop2)


//INSTANTIATE THE SIMPLE RAMS
genvar j;
generate
	for(j=0; j<CHECK_DEGREE*VARIABLE_DEGREE; j=j+1) begin : ramInstantiateLoop
		SimpleRam2 #( .RAM_SIZE(RAM_SIZE),
					.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(ADDRESS_WIDTH)) sram(clk, simple_ram_write_enable, write_address_in_reg, writeValues[j], 
														read_enable, calculatedReadAddresses_reg2, readValues[j]);
	end
endgenerate

endmodule


/*
NegLLRRam stores llr data for the decoding algorithm to use.
Called neg llr because ADMM subtracts llrs.

There is a read port and a write port.

The read port is used as inputs to the variable compute modules. There are
CHECK_DEGREE variable compute modules. So the read port is a bus of 
CHECK_DEGREE numbers.

The write port acts as the input to the decoder. It takes in llr data one
value at a time, capable of writing a valid value to the ram every clock cycle.
*/
module NegLLRRam # 
(
	parameter TAG_WIDTH = 32,
	parameter RAM_SIZE = 31,
	parameter VARIABLE_DEGREE = 3,
	parameter CHECK_DEGREE = 5,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input reset,
	output LLRsloaded, //indicates to the decoder that the llrs have been loaded.
	
	//read port pipeline
	input read_ready_in,
	input read_valid_in,
	input [TAG_WIDTH-1:0] read_tag_in,
	input [ADDRESS_WIDTH-1:0] read_address, //assumed to be <RAM_SIZE
	
	output read_busy,
	output read_ready_out,
	output read_valid_out,
	output [TAG_WIDTH-1:0] read_tag_out,
	output [CHECK_DEGREE*DATA_WIDTH-1:0] read_data_out, 
	
	//write port pipeline
	input write_valid_in,
	input [DATA_WIDTH-1:0] write_data_in, //just one write data at a time. this is how we get it from upp modules.
	
	output write_ready_out
);
//READ PIPELINE
//this should be the same as the read port on the check message ram
//one reg to take in the address. second reg to capture the read values
localparam READ_NUM_REGISTERS = 2; 

wire read_enable;

//pipeline train takes care of all pipeline logic.
PipelineTrain #(.TAG_WIDTH(TAG_WIDTH),
				.NUM_REGISTERS(READ_NUM_REGISTERS)) readChooChoo(clk, reset, read_valid_in, read_ready_in, read_tag_in,
																read_valid_out, read_ready_out, read_busy, read_enable, read_tag_out);

reg [ADDRESS_WIDTH-1:0] read_address_in_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		read_address_in_reg <= 0;
	end else if (1'b1 == read_enable) begin
		read_address_in_reg <= read_address;
	end
end

//variables reading here. don't need to deal with offsets.

//pack the values here
wire [DATA_WIDTH-1:0] readValues [0:CHECK_DEGREE-1];
wire [CHECK_DEGREE*DATA_WIDTH-1:0] readValues_flat;
`PACK_ARRAY(DATA_WIDTH,CHECK_DEGREE,readValues,readValues_flat)

assign read_data_out = readValues_flat;

//WRITE PIPELINE
//Look at the write pipeline 
localparam WRITE_NUM_REGISTERS = 1;  
wire loadedSig;
wire write_enable;
wire dummy_write_tag;
wire simple_ram_write_enable; //this takes the place of valid out of the pipeline. pipeline needs to be advancing for this to be high
wire dummy_write_busy;

PipelineTrain #(.TAG_WIDTH(1),
				.NUM_REGISTERS(WRITE_NUM_REGISTERS)) writeChooChoo(clk, reset, write_valid_in, ~loadedSig, 1'b0, //the rams are ready if they are still loading
																simple_ram_write_enable, write_ready_out, dummy_write_busy, write_enable, dummy_write_tag);

//register input
reg [DATA_WIDTH-1:0] write_data_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		write_data_reg <= 0;
	end else if (1'b1 == write_enable) begin
		write_data_reg <= write_data_in;
	end
end


//create little state machine that manages write activity
localparam LOADED = 1'b1;
localparam LOADING = 1'b0;
reg writeState;
reg [0:CHECK_DEGREE-1] activeRam; //one hot vector indicating which ram we are writing to
reg [ADDRESS_WIDTH-1:0] writeAddress;

always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		writeState <= LOADING;
		activeRam <= {1'b1, {(CHECK_DEGREE-1){1'b0}}}; //first ram is active
		writeAddress <= 0;
		
	end else if (1'b1 == simple_ram_write_enable) begin
	
		if(writeAddress < (RAM_SIZE-1)) begin //just increment the address for the next value
			writeAddress <= writeAddress + 1;
		end else begin
			writeAddress <= 0;
			activeRam <= activeRam >> 1; //the active ram is now one over.
			
			//if we are on the last ram we are done
			if(activeRam == {{(CHECK_DEGREE-1){1'b0}},1'b1} ) begin
				writeState <= LOADED;
			end
		end
	end
end

assign loadedSig = (writeState == LOADED);
assign LLRsloaded = loadedSig;

//INSTANTIATE THE SIMPLE RAMS
wire [DATA_WIDTH-1:0] dummyRead [0:CHECK_DEGREE-1];
genvar j;
generate
	for(j=0; j<CHECK_DEGREE; j=j+1) begin : ramInstantiateLoop
		//the ram is written to if the write value is valid and the ram is active
		SimpleRam2 #( .RAM_SIZE(RAM_SIZE),
					.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(ADDRESS_WIDTH)) sram(clk, (simple_ram_write_enable & activeRam[j]), writeAddress, write_data_reg,
																read_enable, read_address_in_reg, readValues[j]);
	end
endgenerate

endmodule


/*
EstimateRam stores the current variable estimates and
eventually is read from as the decoder output.

There is a read port and a write port.

The read port hands all the estimate values out in sequential order.
Every valid output will be a new variable reading.
The read port has some of the pipeline signals as the read port on this
module will be hooked up directly to the output of the decoder.

The write port interfaces directly with the variable node computation modules.
It takes in CHECK_DEGREE numbers which represent the variable estimates from 
the CHECK_DEGREE variable compute modules.
*/
module EstimateRam # 
(
	parameter TAG_WIDTH = 32,
	parameter RAM_SIZE = 31,
	parameter VARIABLE_DEGREE = 3,
	parameter CHECK_DEGREE = 5,
	parameter DATA_WIDTH = 8,
	parameter ADDRESS_WIDTH = 32
) 
(
	input clk,
	input reset,
	input estimatesReady, //decoder indicates the final estimates have been written to the ram. we expect this to stay high.
	
	//output read port pipeline -- these signals will be hooked up to decoder output
	input read_ready_in,
	
	output read_valid_out,
	output [DATA_WIDTH-1:0] read_data_out, //one value to each variable module
	
	//write port pipeline
	input write_valid_in,
	input [ADDRESS_WIDTH-1:0] write_address, //assumed to be <RAM_SIZE
	input [CHECK_DEGREE*DATA_WIDTH-1:0] write_data_in, //CHECK_DEGREE variables at a time
	
	output write_busy,
	output write_ready_out
);

//READ PIPELINE
localparam READ_NUM_REGISTERS = 2; //we register the RAM outputs then register the muxing of the ram outputs

/*
Until the decoder indicates that decoding is done with the estimatesReady signal, 
we do not want to output any valid marked variable estimates.

The pipeline control signals are layed out as follows. read_read_in is given directly. 
The values being read are valid if the estimatesReady ready signal is high
and we haven't finied reading.
*/

reg [ADDRESS_WIDTH-1:0] readAddress;
reg [ADDRESS_WIDTH-1:0] activeRam; //counter for the active ram from 0 to CHCK_DEGREE-1

reg done;

wire memoryValid;
assign memoryValid = estimatesReady & (~done);
wire dummy_read_ready_out;
wire dummy_read_busy;
wire dummy_read_tag;

wire read_enable;

PipelineTrain #(.TAG_WIDTH(1),
					.NUM_REGISTERS(READ_NUM_REGISTERS)) readChooChoo(clk, reset, memoryValid, read_ready_in, 1'b0, //tag is 0
																					read_valid_out, dummy_read_ready_out, dummy_read_busy, read_enable, dummy_read_tag);


always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		activeRam <= 0; //first ram is active
		readAddress <= 0;
		done <= 0;
		
	//we advance if a valid value is being read and it will be registered.
	end else if(1'b1 == read_enable && memoryValid) begin 
		if(readAddress < (RAM_SIZE-1)) begin //just increment the address for the next value
			readAddress <= readAddress + 1;
		end else begin
			readAddress <= 0;
			activeRam <= activeRam + 1; //the active ram is now one over.
			
			//if we are on the last ram we are done. no more reads will be marked valid
			if(activeRam == (CHECK_DEGREE-1)) begin
				done <= 1'b1;
			end
		end
	end
	
end

wire [DATA_WIDTH-1:0] read_requests [0:CHECK_DEGREE-1]; //these are the reads from the rams
reg [DATA_WIDTH-1:0] read_data_reg;
reg [ADDRESS_WIDTH-1:0] activeRamReg;

integer i;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		read_data_reg <= 0;
		activeRamReg <= 0;
	end else if (1'b1 == read_enable) begin
		read_data_reg <= read_requests[activeRamReg]; //select the value we want from the reads.
		activeRamReg <= activeRam; //capture the active ram associated with the read.
	end
	
end

assign read_data_out = read_data_reg;

//WRITE PIPELINE
//the write port is viewed as the end of the variable node pipeline
//we should only write to the ram if the output of this pipeline is valid
//Therefore simple_ram_write_enable takes the place of the valid out
localparam WRITE_NUM_REGISTERS = 1; 

wire write_enable;
wire dummy_write_tag;
wire simple_ram_write_enable;

PipelineTrain #(.TAG_WIDTH(1),
				.NUM_REGISTERS(WRITE_NUM_REGISTERS)) writeChooChoo(clk, reset, write_valid_in, 1'b1, 1'b0, //always ready. tag set 0
																simple_ram_write_enable, write_ready_out, write_busy, write_enable, dummy_write_tag);

//register input
reg [ADDRESS_WIDTH-1:0] write_address_in_reg;
reg [CHECK_DEGREE*DATA_WIDTH-1:0] write_data_reg;
always @(posedge clk, posedge reset) begin
	if (1'b1 == reset) begin
		write_address_in_reg <= 0;
		write_data_reg <= 0;
	end else if (1'b1 == write_enable) begin
		write_address_in_reg <= write_address;
		write_data_reg <= write_data_in;
	end
end

//Variables are writing here. we do not use the offsets in variable ram accesses.

//unpack the write values from the variable nodes.
//we don't need the special packing routine.
wire [DATA_WIDTH-1:0] writeValues [0:CHECK_DEGREE-1];
`UNPACK_ARRAY(DATA_WIDTH,CHECK_DEGREE,writeValues,write_data_reg)

//INSTANTIATE THE SIMPLE RAMS
genvar j;
generate
	for(j=0; j<CHECK_DEGREE; j=j+1) begin : ramInstantiateLoop
		//the ram is written to if the write value is valid and the ram is active
		SimpleRam2 #( .RAM_SIZE(RAM_SIZE),
					.DATA_WIDTH(DATA_WIDTH),
					.ADDRESS_WIDTH(ADDRESS_WIDTH)) sram(clk, simple_ram_write_enable, write_address_in_reg, writeValues[j],
															read_enable, readAddress, read_requests[j]);
	end
endgenerate

endmodule


`endif //_my_block_ram_