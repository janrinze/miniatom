/*
 * verilog model of an Acorn ATOM.
 *
 * (C) Jan Rinze Peterzon, (janrinze@gmail.com)
 *
 * Feel free to use this code in any non-commercial project, as long as you
 * keep this message, and the copyright notice. This code is provided "as is", 
 * without any warranties of any kind.
 *
 * 
 * For commercial purposes please contact the author regarding licensing.
 * 
 */


//`include "hx8k_defs.v"
`include "vga/vga.v"

/*
   Include the sources from Arlet's 6502 verilog implementation.
   
*/
`include "../verilog-6502/ALU.v"
`include "../verilog-6502/cpu.v"
//`include "bc6502.v"
`include "65Mhz.v"

/*  TODO:

    - implement new 6502

          Memory map of my old ATOM

          FFFF   Top of memory


          F000   ROM     MM52164    IC20        - onboard MOS

          E000   Reserved -Disk Operating System


          D000   ROM     MM52132    IC21		- onboard FPROM


          C000   ROM     MM52164    IC20        - onboard BASIC

          BC00   Empty
          B800   VIA     6522	    IC1         - timer ?
          B400   Extension	        PL8
          B000   PPI     INS8255    IC25	    - keyboard


          A000   ROM     MN52132    IC24		- onboard P-Charme

          9800   Empty
          9400   RAM     2114       ICs 32&33   - onboard
          9000   RAM     2114       ICs 34&35   - onboard
          8C0O   RAM     2114       ICs 36&37   - onboard
          8800   RAM     2114       ICs 38&39   - onboard
          8400   RAM     2114       ICs 40&41   - onboard
          8000   RAM     2114       ICs 42&43   - onboard

          3C00   For RAM expansion off board
          3800   RAM     2114       ICs 18&19   X
          3400   RAM     2114       ICs 16&17   X
          3000   RAM     2114       ICs 14&15   X
          2C00   RAM     2114       ICs 12&13   X
          2800   RAM     2114       ICs 10&11   X

          0400   Reserved for Eurocards
          0000   RAM     2114       ICs 51&52   - onboard

  General Idea:

    1024x768 screen to have ATOM screen with 4x4 pixel size.

    General timing

		Screen refresh rate	60 Hz
		Vertical refresh	48.363095238095 kHz
		Pixel freq.	65.0 MHz
		Horizontal timing (line)

		Polarity of horizontal sync pulse is negative.
		Scanline part	Pixels	Time [µs]
		Visible area	1024	15.753846153846
		Front porch		24		0.36923076923077
		Sync pulse		136		2.0923076923077
		Back porch		160		2.4615384615385
		Whole line		1344	20.676923076923

		Vertical timing (frame)

		Polarity of vertical sync pulse is negative.
		Frame part		Lines	Time [ms]
		Visible area	768		15.879876923077
		Front porch		3		0.062030769230769
		Sync pulse		6		0.12406153846154
		Back porch		29		0.59963076923077
		Whole frame		806		16.6656



    Calculate 32.5 MHz:
     
    icepll -i 100 -o 32.5

    */
`ifdef verilator
`define pull_up( source , type, dest) 	wire dest; assign dest=source;
`define pull_N_up( source , type,num, dest) 	wire [num:0] dest=source;
`else
`define pull_up( source , type, dest) 	wire dest;  SB_IO #(	.PIN_TYPE(6'b0000_01),.PULLUP(1'b1)	) type (.PACKAGE_PIN(source),.D_IN_0(dest));
`define pull_N_up( source , type,num, dest) 	wire [num:0] dest;  SB_IO #(	.PIN_TYPE(6'b0000_01),.PULLUP(1'b1)	) type[num:0] (.PACKAGE_PIN(source),.D_IN_0(dest));
`endif

module top (
	// global clock
	input  pclk,
	
	// vga RGB 2:2:2 output
	output hsync,
	output vsync,
	output [5:0] rgb,
	
	// interface to ATOM keyboard
	input shift_key,
	input ctrl_key,
	input [5:0] key_col,
	input rept_key,
	input key_reset,
	output [9:0] key_row,
	
	// interface to 1MB SRAM icoboard
	output [18:0] SRAM_A,
	inout [15:0] SRAM_D,
	output SRAM_nCE,
	output SRAM_nWE,
	output SRAM_nOE,
	output SRAM_nLB,
	output SRAM_nUB
);

    // ------------------------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------------------------

    wire fclk;			// 65 MHz
    reg clk;			// 32.5 MHz derived system clock
    reg phi2;			// 
    wire pll_locked;	// signal when pll has reached lock
	reg reset=1;		// global reset register
	reg boot;


	pll _65Mhz(
		.clock_in(pclk),
		.clock_out(fclk),
		.locked(pll_locked));

	// fclk is 65 MHz
	// clk is 32.5 MHz

	always@(posedge fclk) begin
		clk <= ~clk;
		
	end

    // ------------------------------------------------------------------------------------
    // Main 6502 CPU
    // ------------------------------------------------------------------------------------
    wire [15:0] cpu_address;
    reg [7:0] D_in;
    wire [7:0] D_out;
    reg IRQ,NMI,RDY;
    wire W_en;
    reg kbd_reset;
    wire cpu_reset = ~kbd_reset | ~pll_locked | boot ;

	cpu main_cpu(
	     .clk(clk),
	     .reset(cpu_reset),
	     .AB(cpu_address),
	     .DI(D_in),
	     .DO(D_out),
	     .WE(W_en),
	     .IRQ(IRQ),
	     .NMI(NMI),
	     .RDY(RDY) );
	     

    // ------------------------------------------------------------------------------------


    // ------------------------------------------------------------------------------------
    // reset 
	// ------------------------------------------------------------------------------------
	always@(posedge clk) begin
	    if (cpu_reset) begin
	       RDY<= 1;
	       NMI<=0;
	       IRQ<=0;
	    end 
	end
	// ------------------------------------------------------------------------------------
	    


	// ------------------------------------------------------------------------------------
	// IO_space
	// ------------------------------------------------------------------------------------

    wire IO_select;
	wire PIO_select;
	wire Extension_select;
	wire VIA_select;
	wire VGAIO_select;
	wire IO_wr;

	assign IO_select        = (cpu_address[15:12]==4'hB) ? 1 : 0         ; // #BXXX address
	assign PIO_select       = (cpu_address[11:10]==2'h0) ? IO_select : 0 ; // #B000 - #B3FF is PIO
	assign Extension_select = (cpu_address[11:10]==2'h1) ? IO_select : 0 ; // #B400 - #B7FF is Extension port
	assign VIA_select       = (cpu_address[11:10]==2'h2) ? IO_select : 0 ; // #B800 - #BBFF is VIA
	assign VGAIO_select     = (cpu_address[11:10]==2'h3) ? IO_select : 0 ; // #BC00 - #BFFF is VGAIO

	assign IO_wr = IO_select & W_en;
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
    reg [7:0] keyboard_input;
    reg [7:0] PIO_out;

    `pull_up(rept_key,  rept_key_t,		rept_keyp)
    `pull_up(shift_key, shift_keyt,		shift_keyp)
    `pull_up(ctrl_key,  ctrl_keyt,		ctrl_keyp)
    `pull_N_up(key_col,  key_colt,5,		key_colp)
    `pull_up(key_reset, key_reset_t, key_reset_p)

	always@(posedge clk)
		begin
		kbd_reset <= key_reset_p;
	end
    
	always@(posedge clk) begin
	    if (cpu_reset) begin
	       graphics_mode <= 4'h0;
	       keyboard_row <=  4'hf;
	       Port_C_low <= 4'h0;

	    end else begin
	        // grab keyboard_input
	        // latch writes to PIO
	        if (IO_wr & PIO_select) begin
	            if (cpu_address[1:0]==2'b00) begin
	                keyboard_row  <= D_out[3:0];
	                graphics_mode <= D_out[7:4];
	                end
	            if (cpu_address[1:0]==2'b10) begin
	                Port_C_low <= D_out[3:0];
	                end
	        end
	        IO_out <= PIO_out;
        end
    end

	// demux key row select
	reg[9:0] key_demux;
	
	always@(keyboard_row)
	begin
		case (keyboard_row)
		4'h0: key_demux=10'b1111111110;
		4'h1: key_demux=10'b1111111101;
		4'h2: key_demux=10'b1111111011;
		4'h3: key_demux=10'b1111110111;
		4'h4: key_demux=10'b1111101111;
		4'h5: key_demux=10'b1111011111;
		4'h6: key_demux=10'b1110111111;
		4'h7: key_demux=10'b1101111111;
		4'h8: key_demux=10'b1011111111;
		4'h9: key_demux=10'b0111111111;
		default: key_demux=10'b1111111111;
		endcase
	end
	assign key_row = key_demux;

    always@(*) begin
	    PIO_out = (PIO_select==0) ? 0 :
                    (cpu_address[1:0]==2'b00) ? { graphics_mode, keyboard_row } :
                    (cpu_address[1:0]==2'b01) ? { shift_keyp, ctrl_keyp, key_colp } :
                    (cpu_address[1:0]==2'b10) ? { vga_vsync_out, rept_keyp, 2'b11, Port_C_low} : 8'hFF;
	end
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
	    if (cpu_reset) begin
	       color0 <= 6'b000011;
	       color1 <= 6'b111111;
	       color2 <= 6'b111111;
	       color3 <= 6'b111111;
	    end else begin

	        // latch writes to color regs
	        if (IO_wr & VGAIO_select) begin
	            case (cpu_address[1:0])
					2'b00: color0 <= D_out[5:0];
					2'b01: color1 <= D_out[5:0];
					2'b10: color2 <= D_out[5:0];
					2'b11: color3 <= D_out[5:0];
	            endcase
	        end
        end
    end


    // ------------------------------------------------------------------------------------
    // MOS ROM, BASIC ROM and minimal RAM
	// ------------------------------------------------------------------------------------
    reg [7:0] vid_data;

    reg [7:0] kernel_rom[0:4095];
    reg [7:0] basic_rom[0:4095];
    reg [7:0] pcharme_rom[0:4095];
    reg [7:0] fp_rom[0:4095];

    initial $readmemh("roms/kernel.hex"		,kernel_rom);
    initial $readmemh("roms/basic.hex"		,basic_rom);
    initial $readmemh("roms/pcharme.hex"	,pcharme_rom);
    initial $readmemh("roms/floatingpoint.hex",fp_rom);
    
    wire [18:0] romaddr;
    wire [7:0] kernel_dat;
    wire [7:0] basic_dat;
    wire [7:0] pcharme_dat;
    wire [7:0] fp_dat;
    
    
    assign kernel_dat  = (romaddr[15:12]==4'hF) ? kernel_rom[romaddr[11:0]]  : 8'h00;
    assign basic_dat   = (romaddr[15:12]==4'hC) ? basic_rom[romaddr[11:0]]   : 8'h00;
    assign pcharme_dat = (romaddr[15:12]==4'hA) ? pcharme_rom[romaddr[11:0]] : 8'h00;
    assign fp_dat      = (romaddr[15:12]==4'hD) ? fp_rom[romaddr[11:0]]      : 8'h00;
    
    wire [7:0] boot_data;
        
    assign boot_data = kernel_dat | basic_dat | pcharme_dat | fp_dat;   
    
    // ------------------------------------------------------------------------------------
    // Bootloader
	// ------------------------------------------------------------------------------------
    reg [18:0] dma_addr;
    wire [18:0] next_dma_addr = dma_addr + 1;
    
    assign romaddr = dma_addr;
    

    always@(negedge clk)
    begin
		if (reboot)
		begin
			dma_addr <= 19'h07fff;
			boot <= 1;
		end
		else
			if (dma_addr[16]==1)
				boot <= 0;
			else
				dma_addr <= next_dma_addr;
	end
    
    // ------------------------------------------------------------------------------------
    // VGA signal generation
	// ------------------------------------------------------------------------------------
    wire [18:0] vdu_address;
    wire [2:0] vid_page = 0;
    wire [5:0] vga_rgb;
	wire vga_hsync_out,vga_vsync_out;
	
	reg [8:0] mx = 0;
	reg [8:0] my = 0;
	reg [5:0] mcolor = 6'b101011; // light blue
	
    reg reboot;

    always @(*)
    begin
		reboot = 0;
		if (pll_locked==0 || (key_reset_p==0 && rept_keyp==0))
			reboot = 1;
	end
	
	vga display(
		.clk( clk ),
		.reset(reboot),
		.address(vdu_address),
		//.page(vid_page),
		.data(vid_data),
		.settings(graphics_mode),
		//.mx(mx),
		//.my(my),
		//.mcolor(mcolor),
        //.dreq(dreq),
		.rgb(vga_rgb),
		.hsync(vga_hsync_out),
		.vsync(vga_vsync_out),
		.color0(color0),
		.color1(color1),
		.color2(color2),
		.color3(color3)
		);
		
    
	always@(posedge clk) begin
		rgb   <= vga_rgb;
		vsync <= vga_vsync_out;
		hsync <= vga_hsync_out;
		end

	// ------------------------------------------------------------------------------------
	// interlace video and cpu on memory bus (should be okay up to 50 MHz with 100MHz SRAM)
	// vdu_address and cpu_addres are both latched on clk so this should be fine.
	// ------------------------------------------------------------------------------------

    reg [15:0] sram_dout;
    wire [15:0] sram_din;
    reg [18:0] bus_address;
    reg nWE,nOE,OE;

`ifdef verilator
	assign sram_din = OE? 0 : SRAM_D;
	assign SRAM_D = OE? sram_dout:16'hZZZZ;
`else
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) sram_io [15:0] (
        .PACKAGE_PIN(SRAM_D),
        .OUTPUT_ENABLE(OE),
        .D_OUT_0(sram_dout),
        .D_IN_0(sram_din)
    );
`endif
	// Bus arbitrator for video, BootDMA and CPU
	reg [18:0] bus_selected;

	always@(*)
	begin
		nOE = 1;
		OE = 0;
		nWE = 1;
		bus_selected = 19'h00000;
		sram_dout = 16'h0000;	
		if (clk)
			begin
				nWE = 1;
				nOE = 0;
				OE = 0;
				bus_selected = vdu_address ;// ////{ 6'b000100, vdu_address[12:0] };
				sram_dout = 16'h0000;
			end
		else
			begin
				if (boot)
					begin
						nWE = 0;
						nOE = 1;
						OE  = 1;
						bus_selected = dma_addr;
						sram_dout = {8'h00,boot_data};
					end 
				else
					begin
						nWE = fclk ? 1 :~W_en;
						nOE = W_en;
						OE = W_en;
						bus_selected = { 3'b000,cpu_address};
						sram_dout = {8'h00,D_out};
					end
			end
	end

	// Hook up our bus signals to the SRAM
	assign SRAM_A = bus_selected;
    assign SRAM_nCE = 0;
    assign SRAM_nWE = nWE;
    assign SRAM_nOE = nOE;
    assign SRAM_nLB = 0;
    assign SRAM_nUB = 1;
	
	// Latches so we can keep the data available for the bus clients.
    reg [7:0] latch_SRAM_out;
    reg [7:0] t_vid_data;

    // --------- data bus latch ---------
    always@(posedge clk) begin
		
		if (IO_select)
			D_in <= PIO_out;
		else
			D_in <= sram_din[7:0];
    end
	

    // --------- phi2  video data -----------    
    always@(negedge clk) begin
		vid_data <= sram_din[7:0];
		end

endmodule
