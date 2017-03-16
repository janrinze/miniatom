/**
 * PLL configuration
 *
 * This Verilog module was generated automatically
 * using the icepll tool from the IceStorm project.
 * Use at your own risk.
 *
 * Given input frequency:       100.000 MHz
 * Requested output frequency:   65.000 MHz
 * Achieved output frequency:    65.000 MHz
 */

module pll(
	input  clock_in,
	output clock_out,
	output locked
	);

`ifdef verilator
	assign clock_out = clock_in;
	reg tlocked=0;
	reg cnt=1;
	always@(posedge clock_in)
	if(cnt==0)
		tlocked <= 0;
	else
		cnt <=0;
	assign locked = tlocked;
	
`else
SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0100),		// DIVR =  4
		.DIVF(7'b0110011),	// DIVF = 51
		.DIVQ(3'b100),		// DIVQ =  4
		.FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
	) uut (
		.LOCK(locked),
		.RESETB(1'b1),
		.BYPASS(1'b0),
		.REFERENCECLK(clock_in),
		.PLLOUTCORE(clock_out),
		);
`endif
endmodule
