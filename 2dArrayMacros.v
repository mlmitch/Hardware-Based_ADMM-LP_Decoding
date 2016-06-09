`ifndef _my_2D_array_macros_
`define _my_2D_array_macros_

//Conveinient macros that pack/unpack a 2d array into a 1d array
//PK_WIDTH is the packed dimension
//PK_LEN is the unpacked dimension
//example:
//module example (
//    input  [63:0] pack_4_16_in,
//    output [31:0] pack_16_2_out
//    );
//
//wire [3:0] in [0:15];
//`UNPACK_ARRAY(4,16,in,pack_4_16_in)
//
//wire [15:0] out [0:1];
//`PACK_ARRAY(16,2,out,pack_16_2_out)

//taken from mrflibble's comment in http://www.edaboard.com/thread80929.html

`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST) \
genvar pk_idx; \
generate \
	for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin : packLoop \
		assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; \
	end \
endgenerate \
//endgenerate \

`define PACK_ARRAY2(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST,PK_IDX,LOOP_LABEL) \
genvar PK_IDX; \
generate \
	for (PK_IDX=0; PK_IDX<(PK_LEN); PK_IDX=PK_IDX+1) begin : LOOP_LABEL \
		assign PK_DEST[((PK_WIDTH)*PK_IDX+((PK_WIDTH)-1)):((PK_WIDTH)*PK_IDX)] = PK_SRC[PK_IDX][((PK_WIDTH)-1):0]; \
	end \
endgenerate \
//endgenerate \

`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC) \
genvar unpk_idx; \
generate \
	for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin : unpackLoop \
		assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; \
	end \
endgenerate \
//endgenerate \

`define UNPACK_ARRAY2(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC,UNPK_IDX, LOOP_LABEL) \
genvar UNPK_IDX; \
generate \
	for (UNPK_IDX=0; UNPK_IDX<(PK_LEN); UNPK_IDX=UNPK_IDX+1) begin : LOOP_LABEL \
		assign PK_DEST[UNPK_IDX][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*UNPK_IDX+(PK_WIDTH-1)):((PK_WIDTH)*UNPK_IDX)]; \
	end \
endgenerate \
//endgenerate \


//FOLLOWING TWO MACROS SHOULD ONLY BE USED INSIDE THE BLOCKRAM.V FILE

//when dealing with check messages, we can use the regular pack/unpack macros.
//when interfacing with variables, things need to be reordered.
//this is due to wanting to use the regular pack/unpack macros outside this module
`define UNPACK_FROM_VARIABLE(DW,CHKD,VARD,DEST,SRC) \
genvar UPCHKNUM; \
genvar UPVARNUM; \
generate \
	for (UPCHKNUM=0; UPCHKNUM<(VARD); UPCHKNUM=UPCHKNUM+1) begin : UPCHKLOOP \
		for (UPVARNUM=0; UPVARNUM<(CHKD); UPVARNUM=UPVARNUM+1) begin : UPVARLOOP \
			assign DEST[(CHKD)*UPCHKNUM+UPVARNUM][((DW)-1):0] = SRC[((DW)*(VARD)*UPVARNUM) + ((DW)*UPCHKNUM) + DW - 1:((DW)*(VARD)*UPVARNUM) + ((DW)*UPCHKNUM)]; \
		end \
	end \
endgenerate \
//endgenerate \

`define PACK_TO_VARIABLE(DW,CHKD,VARD,SRC,DEST) \
genvar PCHKNUM; \
genvar PVARNUM; \
generate \
	for (PCHKNUM=0; PCHKNUM<(VARD); PCHKNUM=PCHKNUM+1) begin : PCHKLOOP \
		for (PVARNUM=0; PVARNUM<(CHKD); PVARNUM=PVARNUM+1) begin : PVARLOOP \
			assign DEST[((DW)*(VARD)*PVARNUM) + ((DW)*PCHKNUM) + DW - 1:((DW)*(VARD)*PVARNUM) + ((DW)*PCHKNUM)] = SRC[(CHKD)*PCHKNUM+PVARNUM][((DW)-1):0]; \
		end \
	end \
endgenerate \
//endgenerate \


`endif //_my_2D_array_macros_