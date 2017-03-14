
module IOsys (
	input reset,
	input clk,
	input [15:0] address,
	input [7:0] Din,
	output [7:0] Dout,
	input WE,
	output IO_sel,
	output [3:0] gmod,
	output [3:0] key_row,
	input [9:0] PIOinput,
	output [23:0] colors
);

    wire IO_select;
	wire PIO_select;
	wire Extension_select;
	wire VIA_select;
	wire VGAIO_select;
	wire IO_wr;

	assign IO_select        = (address[15:12]==4'hB) ? 1 : 0         ; // #BXXX address
	assign PIO_select       = (address[11:10]==2'h0) ? IO_select : 0 ; // #B000 - #B3FF is PIO
	assign Extension_select = (address[11:10]==2'h1) ? IO_select : 0 ; // #B400 - #B7FF is Extension port
	assign VIA_select       = (address[11:10]==2'h2) ? IO_select : 0 ; // #B800 - #BBFF is VIA
	assign VGAIO_select     = (address[11:10]==2'h3) ? IO_select : 0 ; // #BC00 - #BFFF is VGAIO


	assign IO_wr = IO_select & WE;
	reg [7:0] IO_out;

	// ------------------------------------------------------------------------------------
	// 	25.5 Input/Output Port Allocations
	// 
	// The  8255  Programmable  Peripheral  Interface  Adapter  contains  three
	// 8-bit ports, and all but one of these lines is used by the ATOM.
	// 
	// Port A - #B000
	//        Output bits:      Function:
	//             O -- 3     Keyboard row
	//             4 -- 7     Graphics mode
	// 
	// Port B - #B001
	//        Input bits:       Function:
	//             O -- 5     Keyboard column
	//               6        CTRL key (low when pressed)
	//               7        SHIFT keys {low when pressed)
	// 
	// Port C - #B002
	//        Output bits:      Function:
	//             O          Tape output
	//             1          Enable 2.4 kHz to cassette output
	//             2          Loudspeaker
	//             3          Not used
	// 
	//        Input bits:       Function:
	//             4          2.4 kHz input
	//             5          Cassette input
	//             6          REPT key (low when pressed)
	//             7          60 Hz sync signal (low during flyback)
	// 
	// The port C output lines, bits O to 3, may be used for user
	// applications when the cassette interface is not being used.
	// ------------------------------------------------------------------------------------

    reg [3:0] keyboard_row,graphics_mode,Port_C_low,Port_C_high;
    reg [7:0] PIO_out;

    
	always@(posedge clk) begin
	    if (reset) begin
	       graphics_mode <= 4'h0;
	       keyboard_row <=  4'hf;
	       Port_C_low <= 4'h0;

	    end else begin
	        // grab keyboard_input
	        // latch writes to PIO
	        if (IO_wr & PIO_select) begin
	            if (address[1:0]==2'b00) begin
	                keyboard_row  <= Din[3:0];
	                graphics_mode <= Din[7:4];
	                end
	            if (address[1:0]==2'b10) begin
	                Port_C_low <= Din[3:0];
	                end
	        end
        end
    end
    
    always@(*) begin
    PIO_out = (PIO_select==0) ? 0 :
              (address[1:0]==2'b00) ? { graphics_mode, keyboard_row } :
              (address[1:0]==2'b01) ? PIOinput[7:0] : //{ shift_keyp, ctrl_keyp, key_colp } :
              (address[1:0]==2'b10) ? { PIOinput[9:8] /*vga_vsync_out, rept_keyp */, 2'b11, Port_C_low} : 8'hFF;
	end
	
	assign Dout = PIO_out;
	assign key_row = keyboard_row;
	assign gmod = graphics_mode;
	assign IO_sel = IO_select;

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

    always@(posedge clk) begin
	    if (reset) begin
	       color0 <= 6'b000011;
	       color1 <= 6'b111111;
	       color2 <= 6'b111111;
	       color3 <= 6'b111111;
	    end else begin

	        // latch writes to color regs
	        if (IO_wr & VGAIO_select) begin
	            case (address[1:0])
					2'b00: color0 <= Din[5:0];
					2'b01: color1 <= Din[5:0];
					2'b10: color2 <= Din[5:0];
					2'b11: color3 <= Din[5:0];
	            endcase
	        end
        end
    end
    
    assign colors = { color0,color1,color2,color3 };

endmodule
