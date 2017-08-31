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
	     input [4:0] clks,
	     input reset,
	     output [18:0] AB,
	     input  [7:0] DI,
	     output [7:0] DO,
	     output WE,
	     input [2:0] offset,
       input [2:0] nextoff,
	     input out_en,
	     input IRQ,
	     input NMI,
	     input RDY
	     );
/*
  reg [18:0] AB;
  reg [7:0] DO;
  reg WE;
  
	reg [7:0] D_inA;
  reg [7:0] D_inB;
  reg [7:0] D_inC;
  reg [7:0] D_inD;
  
  reg RST;

	wire [7:0] D_outA;
  wire [7:0] D_outB;
  wire [7:0] D_outC;
  wire [7:0] D_outD;
  
	wire [15:0] cpu_addressA;
	wire [15:0] cpu_addressB;
  wire [15:0] cpu_addressC;
  wire [15:0] cpu_addressD;
  
  wire W_enA;
	wire W_enB;
  wire W_enC;
  wire W_enD;
  
	cpu main_cpuA(
	     .clk(clks[0]),
	     .reset(reset),
	     .AB(cpu_addressA),
	     .DI(D_inA),
	     .DO(D_outA),
	     .WE(W_enA),
	     .IRQ(0),
	     .NMI(0),
	     .RDY(1'b1) );

	cpu main_cpuB(
	     .clk(clks[1]),
	     .reset(reset),
	     .AB(cpu_addressB),
	     .DI(D_inB),
	     .DO(D_outB),
	     .WE(W_enB),
	     .IRQ(0),
	     .NMI(0),
	     .RDY(1'b1) );

	cpu main_cpuC(
	     .clk(clks[2]),
	     .reset(reset),
	     .AB(cpu_addressC),
	     .DI(D_inC),
	     .DO(D_outC),
	     .WE(W_enC),
	     .IRQ(0),
	     .NMI(0),
	     .RDY(1'b1) );

	cpu main_cpuD(
	     .clk(clks[3]),
	     .reset(reset),
	     .AB(cpu_addressD),
	     .DI(D_inD),
	     .DO(D_outD),
	     .WE(W_enD),
	     .IRQ(0),
	     .NMI(0),
	     .RDY(1'b1) );
 
  // latch data input.
	
  always@(posedge clks[0]) D_inA <= DI;
  always@(posedge clks[1]) D_inB <= DI;
  always@(posedge clks[2]) D_inC <= DI;
  always@(posedge clks[3]) D_inD <= DI;

  // multiplex outgoing signals
  always@*
  begin
    case (offset[2:1])
    2'h0: DO = D_outA;
    2'h1: DO = D_outB;
    2'h2: DO = D_outC;
    2'h3: DO = D_outD;
    endcase
    
    case (offset[2:1])
    2'h0: WE = W_enA;
    2'h1: WE = W_enB;
    2'h2: WE = W_enC;
    2'h3: WE = W_enD;
    endcase
    
    case (offset[2:1])
    2'h0: AB = {3'b000,cpu_addressA};
    2'h1: AB = {3'b001,cpu_addressB};
    2'h2: AB = {3'b010,cpu_addressC};
    2'h3: AB = {3'b011,cpu_addressD};
    endcase

  end
  */

  reg [7:0] D_in;
  wire [15:0] cpu_address;
  wire [18:0] AB;
  
  cpu main_cpu(
	     .clk(clks[4]),
	     .reset(reset),
	     .AB(cpu_address),
	     .DI(D_in),
	     .DO(DO),
	     .WE(WE),
	     .IRQ(IRQ),
	     .NMI(NMI),
	     .RDY(RDY) );
  
  always@(posedge clks[4]) begin
    D_in <= DI;
  end
  
  assign AB = {3'b000,cpu_address};

endmodule	
