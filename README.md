# Hardware-Based Linear Program Decoding with the Alternating Direction Method of Multipliers
This is the HDL source code for my master's thesis.
This document along with comments in the source code tries to bridge the gap between my written documents and the actual source code.

###### Literature
Here is relevant literature produced during my degree.

This conference paper used an earlier non-pipelined version of parity polytope projection.

[1] M. Wasson and S. C. Draper, “Hardware based projection onto the parity polytope and probability simplex,” in Proc. 49th Asilomar Conf. Signals, Systems, Computers, Pacific Grove, CA, Nov. 2015, pp. 1015–1020.

My thesis document.

[2] M. Wasson, “Hardware-based linear program decoding with the alternating direction method of multipliers,” Master’s thesis, University of Toronto, Canada, Nov. 2016.

There is both a conference paper and journal version of this in different stages of submission process. Will update in the future.

[3] M. Wasson, M. Milicevic, S. C. Draper, and G. Gulak, “Hardware-based linear program decoding with the alternating direction method of multipliers,” Submitted for publication.

Here are a few prior works if you aren't familiar with LP decoding, ADMM, or ADMM's application to LP decoding.

[4] J. Feldman, M. J. Wainwright, and D. R. Karger, “Using linear programming to decode binary linear codes,” IEEE Trans. Inf. Theory, vol. 51, no. 3, pp. 954–972, Mar. 2005.

[5] S. Boyd, N. Parikh, E. Chu, B. Peleato, and J. Eckstein, “Distributed optimization and statistical learning via the alternating direction method of multipliers,” Foundations and Trends in Machine Learning, vol. 3, no. 1, pp. 1–122, 2011.

[6] S. Barman, X. Liu, S. C. Draper, and B. Recht, “Decomposition methods for large scale LP decoding,” IEEE Trans. Inf. Theory, vol. 59, no. 12, pp. 7870–7886, Dec. 2013.


###### Excuses
What follows are a few excuses.
I developed this Verilog implementation for a dated FPGA platform using a Xilinx Virtex 5.
As a result, I had to use their old XST synthesis tool.
For this reason, the implementation is in Verilog and not SystemVerilog (or another HDL with better features).
Additionally, XST is a little buggy so I do some of the implementation in a specific way that may seem inefficient, but was necessary to get the correct behaviour from XST.
Don't blame every mistake on that though.
I had very little experience with HDL before starting this project.

### Top Level Contract

The CenteredDecoderADMM module within CenteredDecoderADMM.v is the top-level module in this repository.
Here I describe a little how to interact with it.



