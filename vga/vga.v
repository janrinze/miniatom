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

reg [9:0] vesa_hor_pos;
reg [9:0] vesa_vert_pos;

reg [3:0] char_line;
reg [5:0] hor_pos;
reg [7:0] vert_pos;
reg [3:0] text_vert_pos;
reg bottom;
reg h_sync,v_sync,pixel,bg,invs;

// rgb signal valid
wire hor_valid    = ~vesa_hor_pos[9];
wire vert_valid   = (vesa_vert_pos[9:8]==3) ? 0 : 1;

/* 60 Hz */
wire hor_restart  = (vesa_hor_pos == 511+12+68+80);
wire hs_start     = (vesa_hor_pos == 511+12);
wire hs_stop	  = (vesa_hor_pos == 511+12+68);

wire vert_restart = (vesa_vert_pos == 767+3+6+29);
wire vs_start     = (vesa_vert_pos == 767+3);
wire vs_stop	  = (vesa_vert_pos == 767+3+6);

wire textmode	  = (settings[3] == 1'b0);
wire invert	      = (textmode & data[7]);
wire c_restart    = (char_line == 4'b1100);
wire next_byte    = (next_vesa_hor_pos[2:0] == 3'b111);
wire next_line    = (vesa_vert_pos[0]);
wire second_half  = (vert_pos == 191) && hor_restart;
wire next_bottom  = second_half ? 1 : ( bottom & vert_valid );

wire [9:0] next_vesa_hor_pos	= hor_restart ? 0 : ( vesa_hor_pos + 1 );
wire [5:0] next_hor_pos 		= hor_valid ? ( next_byte ? hor_pos + 1 : hor_pos ) : 0;

wire [9:0] next_vesa_vert_pos	= vert_restart ? 0 :  ( vesa_vert_pos + 1 );
wire [7:0] next_vert_pos 		= ( ~vert_valid || second_half ) ? 0 : (next_line? vert_pos + 1: vert_pos ) ;
wire [3:0] next_text_vert_pos	= ( vert_restart ) ? 0 : ( c_restart ? text_vert_pos + 1: text_vert_pos ); 
wire [3:0] next_char_line		= ( c_restart || vert_restart )   ? 0 : ( next_line ? char_line + 1: char_line );

wire next_hsync = hs_start ? 0 : ( hs_stop ? 1 : h_sync);
wire next_vsync = vs_start ? 0 : ( vs_stop ? 1 : v_sync);

reg [7:0] pixels_input;
reg input_pixel;
wire [7:0] textchar;	// = charmap[{data[5:0],char_line }];

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
		case(vesa_hor_pos[2:0])
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
		case(vesa_hor_pos[2:1])
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

always@(negedge clk ) begin
	if (reset) begin
		vesa_hor_pos <= 0;
		vesa_vert_pos <= 0;
		h_sync <= 1;
		v_sync <= 1;
		char_line <=0;
		hor_pos<=0;
		vert_pos<=0;
		text_vert_pos<=0;
		bottom <=0;
	 end 
	else
	 begin
		
		vesa_hor_pos <= next_vesa_hor_pos;
		hor_pos <= next_hor_pos;
		
		if (hor_restart) begin
			vesa_vert_pos <= next_vesa_vert_pos;
			vert_pos <= next_vert_pos;
			char_line <= next_char_line;
			text_vert_pos <= next_text_vert_pos;
		end
		// generate sync pulses  
		h_sync <= next_hsync;
		v_sync <= next_vsync;
		
		bottom <= next_bottom;
	end	
end

//wire [5:0] topbits;
assign address[18:13] = {1'b0,bottom,hor_pos[5],3'b100 };
assign address[12:0] = (textmode) ? { 4'b000,text_vert_pos,hor_pos[4:0]}:{ vert_pos,hor_pos[4:0]};
assign hsync = h_sync;
assign vsync = v_sync;

endmodule
