/*
 * verilog model of vga output generator for miniatom.
 *
 * (C) Jan Rinze Peterzon, (janrinze@gmail.com)
 *
 * Feel free to use this code in any non-commercial project, as long as you
 * keep this message, and the copyright notice. This code is provided "as is", 
 * without any warranties of any kind.
 *
 * 
 */

/*

    Simple VGA output (XGA 1024x768 1 bpp)

    General timing

		Screen refresh rate	60 Hz
		Vertical refresh	48.363095238095 kHz
		Pixel freq.	65.0 MHz
		Horizontal timing (line)

		Polarity of horizontal sync pulse is negative.
		Scanline part	Pixels	Time [µs]
		Visible area	1024	15.753846153846				b10000000000
		Front porch		24		0.36923076923077
		Sync pulse		136		2.0923076923077
		Back porch		160		2.4615384615385
		Whole line		1344	20.676923076923

		0 .. 1023 display data
		
		Vertical timing (frame)

		Polarity of vertical sync pulse is negative.
		Frame part		Lines	Time [ms]
		Visible area	768		15.879876923077				b1100000000
		Front porch		3		0.062030769230769
		Sync pulse		6		0.12406153846154
		Back porch		29		0.59963076923077
		Whole frame		806		16.6656

*/

`include "vga/charGen.v"

module 	vga (
		input clk,
		input reset,
		input [7:0] data,
		input [3:0] settings,
		output [18:0] address,
		output [5:0] rgb,
		output hsync,
		output vsync,
		input [5:0] color0,
		input [5:0] color1,
		input [5:0] color2,
		input [5:0] color3		
);

reg [9:0] hor_counter;
wire [9:0] next_hor_counter = hor_counter + 1;
reg [9:0] vert_counter;
wire [9:0] next_vert_counter = vert_counter +1;

reg [3:0] char_line;
reg [5:0] hor_pos;
reg [7:0] vert_pos;
reg [3:0] tvert_pos;
reg bottom;


wire hor_valid    = ~hor_counter[9];
wire vert_valid   = (vert_counter[9:8]==3) ? 0 : 1;

/* 60 Hz */
wire hor_restart  = hor_counter == 511+12+68+80;
wire hs_start     = hor_counter == 511+12;
wire hs_stop	  = hor_counter == 511+12+68;

wire vert_restart = (vert_counter == 767+3+6+29) && hor_restart;
wire vs_start     = vert_counter == 767+3;
wire vs_stop	  = vert_counter == 767+3+6;

/* 75 Hz
wire hor_restart  = hor_counter == 511+12+68+72;
wire hs_start     = hor_counter == 511+12;
wire hs_stop      = hor_counter == 511+12+68;

wire vert_restart = vert_counter == 767+3+6+29;
wire vs_start     = vert_counter == 767+3;
wire vs_stop      = vert_counter == 767+3+6;
*/
wire textmode	  = settings[3]==1'b0;
wire invert	      = textmode & data[7];
wire c_restart    = char_line==4'b1011;
wire next_byte    = hor_counter[2:0] == 3'b111;
wire next_line    = vert_counter[0] == 1'b1;
wire second_half  = vert_pos == 191;
reg h_sync,v_sync,pixel,bg,invs;

reg [7:0] pixels_input;
reg input_pixel;
wire [7:0] textchar  ;// = charmap[{data[5:0],char_line }];

charGen charmap (
	.address({data[5:0],char_line}),
	.dout(textchar)
);

// Text or graphics
always@(*) begin
	if (textmode)
		pixels_input = (invert)?~textchar:textchar;
	else
		pixels_input = data;
	end

// serialize pixels
reg highres_pixel;
always@(*)
begin
	begin
		case(hor_counter[2:0])
		0: highres_pixel = pixels_input[7];
		1: highres_pixel = pixels_input[6];
		2: highres_pixel = pixels_input[5];
		3: highres_pixel = pixels_input[4];
		4: highres_pixel = pixels_input[3];
		5: highres_pixel = pixels_input[2];
		6: highres_pixel = pixels_input[1];
		7: highres_pixel = pixels_input[0];
		endcase
	end
end

// serialize pixels
reg [1:0] medium_pixel;
always@(*)
begin
	begin
		case(hor_counter[2:1])
		0: medium_pixel = pixels_input[7:6];
		1: medium_pixel = pixels_input[5:4];
		2: medium_pixel = pixels_input[3:2];
		3: medium_pixel = pixels_input[1:0];
		endcase
	end
end

// map colors to output
always@(*)
begin
	rgb = 6'd0;
	if (hor_valid && vert_valid)
	begin
		if (settings[3:0]==4'b1001)
			case (medium_pixel)
			0: rgb = color0;
			1: rgb = color1;
			2: rgb = color2;
			3: rgb = color3;
			endcase
		else
			if (highres_pixel)
				rgb = color1;
			else
				rgb = color0;
	end
end

always@(posedge clk ) begin
	if (reset) begin
		hor_counter <= 0;
		vert_counter <= 0;
		h_sync <= 1;
		v_sync <= 1;
		char_line <=0;
		hor_pos<=0;
		vert_pos<=0;
		tvert_pos<=0;
		bottom <=0;
	end else begin
		if (hor_restart) begin
		    hor_counter <= 0;
			if (vert_restart) 
				vert_counter <= 0;
			else
				vert_counter <= next_vert_counter;
			end
		else
			hor_counter <= next_hor_counter;
		

		if (hs_start)
			hor_pos <=0;
		else if (next_byte & hor_valid)
			hor_pos <= hor_pos+1;

		
		if (vs_start || second_half) begin
			vert_pos <= 0;
			char_line<=0;
			tvert_pos <= 0;
			if (second_half)
				bottom <= 1;
			else
				bottom <= 0;
				
		end 
		else if ( next_line & vert_valid & hs_start) begin
			vert_pos <= vert_pos +1;	
		    if (c_restart) begin
				char_line <=0;
				tvert_pos<=tvert_pos+1;
			end	else
				char_line <= char_line +1;
		end

		// generate sync pulses  
		if (hs_start)
		   h_sync <=0;
		else if (hs_stop)
		   h_sync <=1;
		if (vs_start)
		   v_sync <=0;
		else if (vs_stop)
		   v_sync <=1;
	end	
end

wire [5:0] topbits;
assign topbits = {1'b0,bottom,hor_pos[5],3'b100 };
assign address = (textmode) ? { topbits , 4'b000,tvert_pos,hor_pos[4:0]}:{ topbits, vert_pos,hor_pos[4:0]};
assign hsync = h_sync;
assign vsync = v_sync;

endmodule
