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

module duplic(
  input in,
  output [1:0] out
  );
  assign out={in,in};
endmodule


module 	vga (
		input clk,
		input reset,
		input [7:0] data,
		input [3:0] settings,
		output [12:0] address,
		output [5:0] rgb,
		output hsync,
		output vsync,
    output req,
    // register access
    input cs,
    input we,
    input [3:0] cpu_address,
    input [7:0] Din
);

	// ------------------------------------------------------------------------------------
	// VGA registers:
	// #BC00 - #BFFF
	//
	//   T.B.D.
	// 4 bit RGB output.
	// 
	// ------------------------------------------------------------------------------------

	// ATOM can do up to 4 colors so we map them to writeable RGB 2:2:2 registers.
	reg [5:0] color0;
	reg [5:0] color1;
	reg [5:0] color2;
	reg [5:0] color3;
  
 always@(posedge we or posedge reset) begin
  if (reset) begin
    color0 <= 6'b000011; 
    color1 <= 6'b001001;
    color2 <= 6'b110000;
    color3 <= 6'b111111;
    end 
  else
    begin  // latch writes to color regs
      if (cs) begin
        case (cpu_address[1:0])
          2'b00: color0 <= Din[5:0];
          2'b01: color1 <= Din[5:0];
          2'b10: color2 <= Din[5:0];
          2'b11: color3 <= Din[5:0];
        endcase
       end
    end
  end


reg [9:0] hor_counter;
reg [9:0] vert_counter;
reg [15:0] curpixeldat;
reg [3:0] char_line;
reg [4:0] hor_pos;
reg [7:0] vert_pos;
reg [3:0] tvert_pos;

wire hor_valid    = ~hor_counter[9];
wire vert_valid   = (vert_counter[9:8]==3) ? 0 : 1;
// 60 Hz 
wire hor_restart  = hor_counter == 511+12+68+80;
wire hs_start     = hor_counter == 511+12;
wire hs_stop	    = hor_counter == 511+12+68;

wire vert_restart = vert_counter == 767+3+6+29;
wire vs_start     = vert_counter == 767+3;
wire vs_stop	    = vert_counter == 767+3+6;

/* 75 Hz
wire hor_restart  = hor_counter == 511+8+48+88;
wire hs_start     = hor_counter == 511+8;
wire hs_stop      = hor_counter == 511+8+48;

wire vert_restart = vert_counter == 767+1+3+28;
wire vs_start     = vert_counter == 767+1;
wire vs_stop      = vert_counter == 767+1+3;
*/
wire textmode	  = settings[3]==1'b0;
reg invert;	      
wire c_restart    = char_line==4'b1011;
wire next_byte    = hor_counter[3:0] == 4'b0000;
wire next_line    = vert_counter[1:0] == 2'b11;
wire next_data    = (hor_counter[3:0]==4'b1111);
reg h_sync,v_sync,bg,invs;
reg [5:0] pixel;

wire [7:0] textchar  ;// = charmap[{data[5:0],char_line }];
wire [15:0] Dtextchar;
reg [15:0] Dgraph;
wire [15:0] Ddata;
wire highres;

duplic txt [7:0] (textchar,Dtextchar);
duplic dta [7:0] (data,Ddata);
//duplic dta [7:0] (data,Ddata);
assign highres = (settings==4'hf)|(settings==4'h0);

charGen charmap (
	.address({data[5:0],char_line}),
	.dout(textchar)
);

// special mode using blocks
wire [1:0] p1,p2,p3,p4,p5,p6;

assign p1 = {data[5]&~data[7],data[5]};
assign p2 = {data[4]&~data[7],data[4]};
assign p3 = {data[3]&~data[7],data[3]};
assign p4 = {data[2]&~data[7],data[2]};
assign p5 = {data[1]&~data[7],data[1]};
assign p6 = {data[0]&~data[7],data[0]};


always @* begin
  case (char_line[3:2])
  0 : Dgraph = {{4{p1}},{4{p2}}};
  1 : Dgraph = {{4{p3}},{4{p4}}};
  default : Dgraph = {{4{p5}},{4{p6}}};
  endcase
end
  
wire req = (hor_counter[3:0]==4'b1100);

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
    invert <=0;
	end else begin
		if (hor_restart) begin
		    hor_counter <= 0;
        // multi pix here
		    if (vert_restart) begin
		        vert_counter <= 0;
            // multiline here
          end
		    else 
          begin
            vert_counter <= vert_counter + 1;
            // multiline here
          end
		end else begin
		    hor_counter <= hor_counter + 1;
        // multi pix here
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

	    if (next_data)
        case ({data[7:6],settings})
          6'b00_0000 : curpixeldat <= Dtextchar; // text mode
	        6'b10_0000 : curpixeldat <= ~Dtextchar; // text mode
          6'b01_0000 : curpixeldat <= Dgraph; // text mode blocks
          6'b11_0000 : curpixeldat <= Dgraph; // text mode blocks
	        default:  curpixeldat <= highres ?Ddata:{data,8'h00};
	      endcase
	    else 
        if (highres) begin
          if (hor_counter[0]==1'b1) 
            curpixeldat <= {curpixeldat[13:0],2'b00}; //shift_left	
        end
        else
          if (hor_counter[1:0]==2'b11)
            curpixeldat <= {curpixeldat[13:0],2'b00}; //shift_left

    case(curpixeldat[15:14])
      0:  pixel <= color0;
      1:  pixel <= color1;
      2:  pixel <= color2;
      3:  pixel <= color3;
    endcase

		bg <= hor_valid & vert_valid; 
		
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


assign address = (textmode) ? {4'b000,tvert_pos,hor_pos}:{ vert_pos,hor_pos};
assign hsync = h_sync;
assign vsync = v_sync;

assign rgb  =  bg ? pixel : 6'b000000;

endmodule
