/*


	video.v
	
	
	
*/

`include "vga_signals.v"

 module video_chip(
		input clk,
		input reset,
		input [3:0] graphics_mode,
		input reg_cs,
		input mem_cs,
		input we,
		input [15:0] address,
		input [7:0] data,
		output reg [8:0] rgb,
		output reg hsync,
		output reg vsync
	);

	//------------------------------------------------------------
	// video memory shadow
	//------------------------------------------------------------

	wire [12:0] vid_address;
	reg [7:0] vid_ram[0:8191];
	reg [7:0] pixels;
	
	always@(posedge clk)
		begin
			pixels <= vid_ram[vid_address];
			if (we & mem_cs)
				vid_ram[address[12:0]] <= data;
		end

	wire hs1,vs1,ac1;
	
	wire [9:0] x1,y1;

	vga_signals VGAsignals(
		.i_clk(clk),           // base clock
		.i_rst(reset),           // reset: restarts frame
		.o_hs(hs1),           // horizontal sync
		.o_vs(vs1),           // vertical sync
		.o_active(ac1),       // high during active pixel drawing
		.o_x(x1),      // current pixel x position
		.o_y(y1)       // current pixel y position
		);
	
	reg hs2,vs2,ac2;
	reg [9:0] x2,y2;
	
	assign vid_address={y1[9:2],x1[7:3]};
	
	always@(posedge clk) begin
		x2 <= x1;
		y2 <= y1;
		hs2 <= hs1;
		vs2 <= vs1;
		hsync <= hs1;
		vsync <= vs1;
		if (ac1) rgb <= { 3 { 1'b0,pixels[x1[2:0]],1'b0}};
		else rgb <= 9'b000000000;
	end
	
endmodule
