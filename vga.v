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

`include "charGen.v"

module 	vga (
		input clk,
		input reset,
		input [7:0] data,
		input [3:0] settings,
		output [12:0] address,
		output red,
		output blue,
		output green1,
		output green2,
		output hsync,
		output vsync
);

reg [9:0] hor_counter;
reg [9:0] vert_counter;
reg [3:0] rgb;
reg [7:0] curpixeldat;
reg [3:0] char_line;
reg [4:0] hor_pos;
reg [7:0] vert_pos;
reg [3:0] tvert_pos;
//reg [7:0] charmap[0:1023];

//initial begin
//    $readmemb("charmap.list", charmap); // memory_list is memory file
//end


wire hor_valid    = ~hor_counter[9];
wire vert_valid   = (vert_counter[9:8]==3) ? 0 : 1;
wire hor_restart  = hor_counter == 671;
wire hs_start     = hor_counter == 524;
wire hs_stop	  = hor_counter == 592;

wire vert_restart = vert_counter == 805;
wire vs_start     = vert_counter == 771;
wire vs_stop	  = vert_counter == 777;

wire textmode	  = settings[3]==1'b0;
wire invert		  = textmode & data[7];
wire c_restart    = char_line==4'b1011;
wire next_byte    = hor_counter[3:0] == 4'b0000;
wire next_line    = vert_counter[1:0] == 2'b11;
reg h_sync,v_sync,pixel,bg,invs;


wire [7:0] textchar  ;// = charmap[{data[5:0],char_line }];

charGen charmap (
	.address({data[5:0],char_line}),
	.dout(textchar));

always@(posedge clk) begin
	if (reset) begin
		hor_counter <= 0;
		vert_counter <= 0;
		h_sync <= 1;
		v_sync <= 1;
		pixel <= 0;
		curpixeldat <=0;
		char_line <=0;
		hor_pos<=0;
		vert_pos<=0;
		tvert_pos<=0;
	end else begin
		if (hor_restart) begin
		    hor_counter <= 0;
		    if (vert_restart) 
		        vert_counter <= 0;
		    else
				vert_counter <= vert_counter + 1;
		end else begin
		    hor_counter <= hor_counter + 1;
		end	
		
		
		if (hs_start)
			hor_pos <=0;
		else if (next_byte & hor_valid)
			hor_pos <= hor_pos+1;
		
		if (vs_start) begin
			vert_pos <= 0;
			char_line<=0;
			tvert_pos <= 0;
		end 
		else if ( next_line & vert_valid & hs_start) begin
			vert_pos <= vert_pos +1;	
		    if (c_restart) begin
				char_line <=0;
				tvert_pos<=tvert_pos+1;
			end	else
				char_line <= char_line +1;
		end

		
	    if (hor_counter[3:0]==4'b1111)
	    begin
	        invs <= invert;
			if  (textmode)
	          curpixeldat <= textchar;
	        else
	          curpixeldat <= data;
	    end
	    else if (hor_counter[0]==1'b1) 
			curpixeldat <= {curpixeldat[6:0],1'b0}; //shift_left	

		pixel <= (invs ^ curpixeldat[7])  & hor_valid & vert_valid;
		bg <= hor_valid & vert_valid;   
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


assign address = (textmode) ? {4'b000,tvert_pos,hor_pos}:{ vert_pos,hor_pos};
assign hsync = h_sync & v_sync;
assign vsync = v_sync;

assign blue = bg;
assign red  = pixel;
assign green1 = pixel;
assign green2 = pixel;

endmodule
