//################### Defs borrowed from swapforth ##################################
`define MOS_BRAM 1
`define FAST_VERSION 1
`include "hx8k_defs.v"

//`include "uart.v"

`include "vga.v"

`include "../verilog-6502/ALU.v"

`include "../verilog-6502/cpu.v"



/*  Stappen plan:

    1: test read/write RAM
    2: implement 6502
    3: test uart echo code
    4: more..

          FFFF   Top of memory


          F000   ROM     MM52164    IC20        - onboard MOS

          E000   Reserved -Disk Operating System


          D000   ROM     MM52132    IC21


          C000   ROM     MM52164    IC20        - onboard BASIC

          BC00   Empty
          B800   VIA     6522	    IC1         - timer ?
          B400   Extension	        PL8
          B000   PPI     INS8255    IC25	    - keyboard


          A000   ROM     MN52132    IC24

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



    Calculate 32.5 MHz 
    icepll -o 32.5

    F_PLLIN:    12.000 MHz (given)
    F_PLLOUT:   35.500 MHz (requested)
    F_PLLOUT:   35.250 MHz (achieved)

    FEEDBACK: SIMPLE
    F_PFD:   12.000 MHz
    F_VCO:  564.000 MHz

    DIVR:  0 (4'b0000)
    DIVF: 86 (7'b1010110)
    DIVQ:  3 (3'b100)

    FILTER_RANGE: 1 (3'b001)

    */
    
`define pull_up( source , type, dest) 	wire dest;  SB_IO #(	.PIN_TYPE(6'b0000_01),.PULLUP(1'b1)	) type (.PACKAGE_PIN(source),.D_IN_0(dest));

module top (
	input  pclk,
	input reset,
	output LED0,
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5,
	output LED6,
	output LED7,
	//input RXD,
	//output TXD,
	output hsync,
	output vsync,
	output blue,
	output red,
	output green1,
	output green2,
	
	input shift_key,
	input ctrl_key,
	input key_col5,
	input key_col4,
	input key_col3,
	input key_col2,
	input key_col1,
	input key_col0,
	input rept_key,
	input key_reset,

	output key_row0,
	output key_row1,
	output key_row2,
	output key_row3,
	output key_row4,
	output key_row5,
	output key_row6,
	output key_row7,
	output key_row8,
	output key_row9
);

    wire clk;
    wire resetq;
	wire [12:0] vdu_address;
	wire [12:0] vid_address;
	reg  [12:0] latched_vid_addr;
	wire 		vga_red_out,
				vga_blue_out,
				vga_green1_out,
				vga_green2_out,
				vga_hsync_out,
				vga_vsync_out;
	
`ifdef FAST_VERSION
    SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  .DIVR(4'b0000),
                  .DIVF(7'b1010110),
                  .DIVQ(3'b101),
                  .FILTER_RANGE(3'b001),
                 ) uut (
                         .REFERENCECLK(pclk),
                         .PLLOUTCORE(clk),
                         //.PLLOUTGLOBAL(clk),
                         .LOCK(resetq),
                         .RESETB(reset),
                         .BYPASS(1'b0)
                        );
`else
    SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  .DIVR(4'b0000),
                  .DIVF(7'b0110011),
                  .DIVQ(3'b101),
                  .FILTER_RANGE(3'b001),
                 ) uut (
                         .REFERENCECLK(pclk),
                         .PLLOUTCORE(clk),
                         //.PLLOUTGLOBAL(clk),
                         .LOCK(resetq),
                         .RESETB(reset),
                         .BYPASS(1'b0)
                        );
`endif
	reg [31:0] counter = 0,counter_preset = 0;
	reg [7:0] leds;

    // ------------------------------------------------------------------------------------
    // Main 6502 CPU
    // ------------------------------------------------------------------------------------
    wire [15:0] cpu_address;
    wire [7:0] D_in;
    wire [7:0] D_out;
    reg IRQ,NMI,RDY;
    wire W_en;

	cpu main_cpu(
	     .clk(clk),
	     .reset(~resetq),
	     .AB(cpu_address),
	     .DI(D_in),
	     .DO(D_out),
	     .WE(W_en),
	     .IRQ(IRQ),
	     .NMI(NMI),
	     .RDY(RDY) );
    // ------------------------------------------------------------------------------------


    wire latch_counter;

    // ------------------------------------------------------------------------------------
    // reset and tick counter
	// ------------------------------------------------------------------------------------
	always@(posedge clk) begin
	    if (~resetq) begin
	       RDY<= 1;
	       NMI<=0;
	       IRQ<=0;
	    end else begin
	       counter <= counter + 1; // 32 bit tick timer 
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
   	wire [7:0] PIO_out;
   	/* Numpad pull-up settings for columns:
       PIN_TYPE: <output_type=0>_<input=1>
       PULLUP: <enable=1>
       PACKAGE_PIN: <user pad name>
       D_IN_0: <internal pin wire (data in)>
    */

    `pull_up(rept_key,  rept_key_t,		rept_keyp)
    `pull_up(shift_key, shift_keyt,		shift_keyp)
    `pull_up(ctrl_key,  ctrl_keyt,		ctrl_keyp)
    `pull_up(key_col5,  key_col5t,		key_col5p)
    `pull_up(key_col4,  key_col4t,		key_col4p)
    `pull_up(key_col3,  key_col3t,		key_col3p)
    `pull_up(key_col2,  key_col2t,key_col2p)
    `pull_up(key_col1,  key_col1t,key_col1p)
    `pull_up(key_col0,  key_col0t,   key_col0p)
    `pull_up(key_reset, key_reset_t, key_reset_p)

    
    
	always@(posedge clk) begin
	    if (~resetq) begin
	       graphics_mode <= 4'h0;
	       keyboard_row <=  4'hf;
	       Port_C_low <= 4'h0;
	    end else begin
	        // grab keyboard_input
	        keyboard_input <= { shift_keyp, ctrl_keyp, key_col5p, key_col4p, key_col3p, key_col2p , key_col1p, key_col0p };
	        Port_C_high <= { vga_vsync_out, rept_keyp, 2'b11};
//	        keyboard_input <= { shift_key, ctrl_key, key_col5, key_col4, key_col3, key_col2 , key_col1, key_col0 };
//	        Port_C_high <= { vga_vsync_out, rept_key, 2'b11};
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
	assign {key_row9,key_row8,key_row7,key_row6,key_row5,key_row4,key_row3,key_row2,key_row1,key_row0} = key_demux;

    assign PIO_out = (PIO_select==0) ? 0 :
                    (cpu_address[1:0]==2'b00) ? { graphics_mode, keyboard_row } :
                    (cpu_address[1:0]==2'b01) ? keyboard_input :
                    (cpu_address[1:0]==2'b10) ? { Port_C_high, Port_C_low} : 8'hFF;
    
	// ------------------------------------------------------------------------------------
	// VGA registers:
	// #BC00 - #BFFF
	//
	//   T.B.D.
	// 4 bit RGB output.
	// 
	// ------------------------------------------------------------------------------------

    // ------------------------------------------------------------------------------------
    // MOS ROM, BASIC ROM and minimal RAM
	// ------------------------------------------------------------------------------------
    reg [15:0] latched_cpu_addr;
    reg [7:0] latched_D_out;
    reg latched_W_en;
    `include "BASIC_ROM.v"
`ifdef MOS_BRAM
    `include "MOS_ROM.v"
`endif
    `include "ram_areas.v"
	// ------------------------------------------------------------------------------------		
	vga display(
		.clk( clk ),
		.reset(~resetq),
		.address(vdu_address),
		.data(VID_RAM_out),
		.settings(graphics_mode),
		.red(vga_red_out),
		.blue(vga_blue_out),
		.green1(vga_green1_out),
		.green2(vga_green2_out),
		.hsync(vga_hsync_out),
		.vsync(vga_vsync_out)
		);
		
    
	always@(posedge clk) begin
		red      <= vga_red_out;
		blue     <= vga_blue_out;
		green1   <= vga_green1_out;
		green2   <= vga_green2_out;
		vsync    <= vga_vsync_out;
		hsync    <= vga_hsync_out;
		end


	// ------------------------------------------------------------------------------------
	// collect IO outputs
	// ------------------------------------------------------------------------------------
    
	// ------------------------------------------------------------------------------------

	// ------------------------------------------------------------------------------------
	// interlace video and cpu on memory bus (should be okay at 130 MHz..)
	// vdu_address and cpu_addres are both latched on clk so this should be fine.
	// we can always go to 65MHz cpu and vdu using an interlaced clock.
	// ------------------------------------------------------------------------------------
	
	

    assign vid_address = (cpu_address[15:13]==3'b100) ? cpu_address[12:0] : vdu_address[12:0];

`ifdef MOS_BRAM
	assign D_in = (latched_cpu_addr[15:13]==3'b100) ? VID_RAM_out : ( ZP_RAM_out| BAS_RAM_out | BASIC_ROM_out | MOS_ROM_out | IO_out );
/*
	reg [7:0] ROM_DAT;
    assign D_in = (latched_cpu_addr[15:13]==3'b100) ? VID_RAM_out : ( ZP_RAM_out | BASIC_ROM_out | ROM_DAT | IO_out );

    //reg [7:0] BASIC_ROM[0:4096];
    reg [7:0] MOS_ROM[0:4096];
	//wire BASIC_select  = cpu_address[15:12]==4'hC;
	wire Kernel_select = cpu_address[15:12]==4'hF;
	
	//wire [7:0] BAS_ROM_dat = BASIC_ROM[cpu_address[11:0]];
	wire [7:0] MOS_ROM_dat = MOS_ROM[cpu_address[11:0]];
     
    
    initial begin
	//	$readmemb("BASIC_ROM.list", BASIC_ROM); // memory_list is memory file
		$readmemb("MOS_ROM.list", MOS_ROM); // memory_list is memory file
	end
	always@(posedge clk) begin
	//	if (BASIC_select)
	//		ROM_DAT <= BAS_ROM_dat;
	//	else
		 if (Kernel_select)
			ROM_DAT <= MOS_ROM_dat ;
		else ROM_DAT<=0;
	end
*/


`else
	reg [7:0] ROM_DAT;
    assign D_in = (latched_cpu_addr[15:13]==3'b100) ? VID_RAM_out : ( ZP_RAM_out | BASIC_ROM_out | ROM_DAT | IO_out );

    //reg [7:0] BASIC_ROM[0:4096];
    reg [7:0] MOS_ROM_A[0:1024];
    reg [7:0] MOS_ROM_B[0:1024];
    reg [7:0] MOS_ROM_C[0:1024];
    reg [7:0] MOS_ROM_D[0:1024];
	//wire BASIC_select  = cpu_address[15:12]==4'hC;
	wire Kernel_select = cpu_address[15:12]==4'hF;
	wire MOS_ROM_A_select = cpu_address[11:10]==2'b00;
	wire MOS_ROM_B_select = cpu_address[11:10]==2'b01;
	wire MOS_ROM_C_select = cpu_address[11:10]==2'b10;
	wire MOS_ROM_D_select = cpu_address[11:10]==2'b11;
	
	//wire [7:0] BAS_ROM_dat = BASIC_ROM[cpu_address[11:0]];
	wire [7:0] MOS_ROM_A_dat = MOS_ROM_A_select ? MOS_ROM_A[cpu_address[9:0]] :0 ;
	wire [7:0] MOS_ROM_B_dat = MOS_ROM_B_select ? MOS_ROM_B[cpu_address[9:0]]:0 ;
	wire [7:0] MOS_ROM_C_dat = MOS_ROM_C_select ? MOS_ROM_C[cpu_address[9:0]]:0 ;
	wire [7:0] MOS_ROM_D_dat = MOS_ROM_D_select ? MOS_ROM_D[cpu_address[9:0]]:0 ;
      
    // try the OR
    // 
    initial begin
	//	$readmemb("BASIC_ROM.list", BASIC_ROM); // memory_list is memory file
		$readmemb("MOS_ROMA.list", MOS_ROM_A); // memory_list is memory file
		$readmemb("MOS_ROMB.list", MOS_ROM_B); // memory_list is memory file
		$readmemb("MOS_ROMC.list", MOS_ROM_C); // memory_list is memory file
		$readmemb("MOS_ROMD.list", MOS_ROM_D); // memory_list is memory file
	end
	always@(posedge clk) begin
	//	if (BASIC_select)
	//		ROM_DAT <= BAS_ROM_dat;
	//	else
		 if (Kernel_select)
			ROM_DAT<=MOS_ROM_A_dat|MOS_ROM_B_dat|MOS_ROM_C_dat|MOS_ROM_D_dat;
		else ROM_DAT<=0;
	end
`endif
	
	// -------------------------------------------------------------------------------------

	always@(posedge clk) begin
		if (RDY)
		begin
		   latched_cpu_addr <= cpu_address;
		   latched_vid_addr <= vid_address;
		   latched_D_out <= D_out;
		   latched_W_en <= W_en;
		end
		leds     <= keyboard_input;
		//leds     <=cpu_address[15:8];
	end
	assign {LED0, LED1, LED2, LED3, LED4, LED5, LED6, LED7} = leds;
	
endmodule
