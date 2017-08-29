/* 
	Bus enabled cpu 
	
	creates a High Z shared bus with 8 addresses.
	
*/
/*
   Include the sources from Arlet's 6502 verilog implementation.
   
*/

`include "../verilog-6502/ALU.v"
`include "../verilog-6502/cpu.v"

//`include "bc6502.v"

module cpubus (
	     input clk,
	     input reset,
	     output [18:0] AB,
	     input  [7:0] DI,
	     output [7:0] DO,
	     output WE,
	     input [2:0] offset,
	     input out_en,
	     input IRQ,
	     input NMI,
	     input RDY
	     );


	reg [7:0] D_in;
  reg RST;
	wire [7:0] D_out;
	wire [15:0] cpu_address;
	wire W_en;
	
	cpu main_cpu(
	     .clk(clk),
	     .reset(RST),
	     .AB(cpu_address),
	     .DI(D_in),
	     .DO(D_out),
	     .WE(W_en),
	     .IRQ(IRQ),
	     .NMI(NMI),
	     .RDY(RDY) );
	
	// latch data input.
	always@(posedge clk) begin
		D_in <= DI;
    RST <= reset; 
		end
	
	// bus enabled Dout
	assign DO = (out_en) ? D_out : 8'hZZ;
	
	// bus enabled address bus
	assign AB = (out_en) ? {offset,cpu_address} : 19'hZZZZZ;
	
	// bus enabled Dout
	assign WE = (out_en) ? W_en : 1'bz;
	
endmodule	
