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

   Input clock is 2x65 MHz allowing for proper state handling.
*/

module 	vga (
		input clk,
		input reset,
		input [7:0] data,
		input settings,
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
// 10000000000000

reg [12:0]char_addr; // will be used for retrieving video data as well as text char lookups
reg [7:0] curpixeldat;

reg [5:0] charmap[96*7];

wire hor_valid    = ~hor_counter[9];
wire vert_valid   = (vert_counter[9:8]==3) ? 0 : 1;
wire hor_restart  = hor_counter == 671;
wire hs_start     = hor_counter == 524;
wire hs_stop	  = hor_counter == 592;

wire vert_restart = vert_counter == 805;
wire vs_start     = vert_counter == 771;
wire vs_stop	  = vert_counter == 777;

reg h_sync,v_sync,pixel;

always@(posedge clk) begin
	if (reset) begin
		vdu_addr <= 0;
		hor_counter <= 0;
		vert_counter <= 0;
		h_sync <= 1;
		v_sync <= 1;
		pixel <= 0;
		curpixeldat <=0;
		rgb<=0;
	end else begin
		if (hor_restart ) begin
		    hor_counter <= 0;
		    curpixeldat <= data;
		    if (vert_restart)
		        vert_counter <= 0;
		    else
		        vert_counter <= vert_counter + 1;
		end
		else begin
		    hor_counter <= hor_counter + 1;
		    if (hor_counter[3:0]==4'b0000) curpixeldat <= data;
		    else if (hor_counter[0]==1'b0) 
				curpixeldat <= {0,curpixeldat[7:1]}; //shift_right
		
		end
		
		pixel <= (~curpixeldat[0])  & hor_valid & vert_valid;     
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


assign address = {vert_counter[9:2],hor_counter[8:4]};
assign hsync = h_sync & v_sync;
assign vsync = v_sync;

assign blue = pixel;
assign red  = pixel;
assign green1 = pixel;
assign green2 = pixel;

endmodule
