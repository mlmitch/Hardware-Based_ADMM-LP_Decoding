# Hardware-Based Linear Program Decoding with the Alternating Direction Method of Multipliers
This is the HDL source code for my master's thesis.
This document along with comments in the source code tries to bridge the gap between my written documents and the actual source code.
We chose the MIT license so people in industry wouldn't be dissuaded from looking at the source code.
Just cite the literature below if it you use it or it helps you out at all.
The CenteredDecoderADMM module within CenteredDecoderADMM.v is the top-level module in this repository.

##### Literature
Here is relevant literature produced during my degree.

This conference paper used an earlier non-pipelined version of parity polytope projection.

[1] M. Wasson and S. C. Draper, “Hardware based projection onto the parity polytope and probability simplex,” in Proc. 49th Asilomar Conf. Signals, Systems, Computers, Pacific Grove, CA, Nov. 2015, pp. 1015–1020.

My thesis document.

[2] M. Wasson, “Hardware-based linear program decoding with the alternating direction method of multipliers,” Master’s thesis, University of Toronto, Canada, Nov. 2016.

There is both a conference and journal version of this in different stages of submission process. Will update in the future.

[3] M. Wasson, M. Milicevic, S. C. Draper, and G. Gulak, “Hardware-based linear program decoding with the alternating direction method of multipliers,” Submitted for publication.

Here are a few prior works if you aren't familiar with LP decoding, ADMM, or ADMM's application to LP decoding.

[4] J. Feldman, M. J. Wainwright, and D. R. Karger, “Using linear programming to decode binary linear codes,” IEEE Trans. Inf. Theory, vol. 51, no. 3, pp. 954–972, Mar. 2005.

[5] S. Boyd, N. Parikh, E. Chu, B. Peleato, and J. Eckstein, “Distributed optimization and statistical learning via the alternating direction method of multipliers,” Foundations and Trends in Machine Learning, vol. 3, no. 1, pp. 1–122, 2011.

[6] S. Barman, X. Liu, S. C. Draper, and B. Recht, “Decomposition methods for large scale LP decoding,” IEEE Trans. Inf. Theory, vol. 59, no. 12, pp. 7870–7886, Dec. 2013.


##### Excuses
What follows are a few excuses.
I developed this Verilog implementation for a dated FPGA platform using a Xilinx Virtex 5.
As a result, I had to use their old XST synthesis tool.
For this reason, the implementation is in Verilog and not SystemVerilog (or another HDL with better features).
Additionally, XST is a little buggy so I do some of the implementation in a specific way that may seem inefficient, but was necessary to get the correct behaviour from XST.
Don't blame every mistake on that though.
I had very little experience with HDL before starting this project.

### Module Contract
Most of the modules here have the same sort of input and output contract.
I'll use SortNetwork in SortNetwork.v as an example.
It has the following declaration:
```
module SortNetwork # 
(
	parameter TAG_WIDTH = 32,
	parameter BLOCKLENGTH	= 16, 
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
```

clk is the clock signal.
reset is a ansynchronous reset.
ready_in is a signal from a downstream pipeline module indicating that it is ready to receive an output from this module.
valid_in is a signal from an upstream module indicating that the data on unsortedData is valid and should be used for computation.
tag_in is a bus of miscellaneous data that is captured with the data on unsortedData when valid_in is high.
The tag data stays with its corresponding computation and is available on the tag_out bus when the finished computation is displayed on sortedData.
Internally, modules keep a shift register of the valid_in signals.
busy is simply an OR of this shift register indicating whether or not a valid computation is taking place.
ready_out is a signal that goes to an upstream module indicating that this module is ready for a valid input.
valid_out indicates whether or not the data present on sortedData is computation result of a valid input.
valid_out should only be high for a single clock cycle for a given computation.
Therefore valid_out should only be high if ready_in is also high.
ready_out may also be affected by ready_in depending on how full the pipeline is.
Look at PipelineTrain in PipelineTrain.v for an implementation of this.

For the shown SortNetwork module, TAG_WIDTH is the width of the tag bus.
BLOCKLENGTH is the number of integer values contained in unsortedData.
DATA_WIDTH is how many bits the integer values use.
Verilog only allows one-dimensional arrays.
Therefore, inside SortNetwork, unsortedData is unpacked into a ```wire signed [DATA_WIDTH-1:0] unsorted [0:BLOCKLENGTH-1]``` bus.
Similary, at the output the bus must be repacked into sortedData.
Unpacking and packing are accomplished with macros inside 2dArrayMacros.v

The good part of the above module contract is that knowing pipeline depths isn't necessary.
For example in the decoder, variable nodes have this contract.
They are simply hooked up to the decoder control logic and the decoder doesn't have to know how many clock cycles VNs use.
This allows one to change variable and check degrees to try out a new code without changing the source code.





