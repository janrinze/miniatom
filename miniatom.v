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


`include "vga/vga.v"
`include "PIA8255/pia8255.v"
`include "utils/debounce.v"
/*
   Include the sources from Arlet's 6502 verilog implementation.
   
*/
`include "Arlet6502/ALU.v"
`include "Arlet6502/cpu.v"
`include "spi/spi.v"

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
    
`define pull_up( source , type, dest) 	wire dest;  SB_IO #(	.PIN_TYPE(6'b0000_01),.PULLUP(1'b1)	) type (.PACKAGE_PIN(source),.D_IN_0(dest));
`define pull_N_up( source , type,num, dest) 	wire [num:0] dest;  SB_IO #(	.PIN_TYPE(6'b0000_01),.PULLUP(1'b1)	) type[num:0] (.PACKAGE_PIN(source),.D_IN_0(dest));

`define FAST_CPU

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
	output SRAM_nUB,
  output led1,
  input  miso,
  output mosi,
  output ss,
  output sclk

  
);

  // clock signals
  wire fclk;			// 100 MHz clock icoboard
  wire pll_locked;	// signal when pll has reached lock
	reg reset=1;		// global reset register

  reg clk,vidclk,spiclk;			// 32.5 MHz derived system clock
	reg boot;
  wire ready;
  reg phi2_we;
  
  // reset signals
  wire kbd_reset;
  wire cpu_reset = kbd_reset | ~pll_locked | boot;
  wire reboot_req; 
  
  // CPU Bus signals
  wire [15:0] cpu_address;
  reg [7:0] D_in;
  wire [7:0] D_out;
  wire W_en;
  reg wg;

  reg IRQ,NMI,RDY;  
  // Latched CPU signals  
  reg [15:0] Lcpu_address;
  reg [7:0] LD_out;
  reg LW_en;
  
  // VGA bus and signals
  wire [12:0] vdu_address;
  reg [7:0] vid_data;
  reg [7:0] t_vid_data;
	wire [5:0] vga_rgb;
	wire vga_hsync_out,vga_vsync_out;
  
  
  // ------------------------------------------------------------------------------------
  // Clock generation
  // ------------------------------------------------------------------------------------
	
/* 65 MHz	*/
    SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  /*       
                  // 120 MHz
                  .DIVR(4'b0100),		// DIVR =  4
                  .DIVF(7'b0101111),	// DIVF = 47
                  .DIVQ(3'b011),		// DIVQ =  3
                  .FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
*/            
                  
                  // 130 Mhz
                  .DIVR(4'b0100),		// DIVR =  4
                  .DIVF(7'b0110011),	// DIVF = 51
                  .DIVQ(3'b011),		// DIVQ =  3
                  .FILTER_RANGE(3'b010)	// FILTER_RANGE = 2
/*
    // 150 MHz
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0000),		// DIVR =  0
		.DIVF(7'b0000101),	// DIVF =  5
		.DIVQ(3'b010),		// DIVQ =  2
		.FILTER_RANGE(3'b101)	// FILTER_RANGE = 5

*/

                 ) uut (
                         .REFERENCECLK(pclk),
                         .PLLOUTCORE(fclk),
                         //.PLLOUTGLOBAL(clk),
                         .LOCK(pll_locked),
                         .RESETB(reset),
                         .BYPASS(1'b0)
                        );

	// fclk is 120 MHz
  // spiclk is 60 Mhz
  // clk is 30 MHz
	// vidclk is 30 MHz

`ifdef FAST_CPU  
  // 30 MHz cpu
  reg [1:0] cnt;
  wire [1:0] nxtcnt;
  assign nxtcnt = cnt +1;
	always@(posedge fclk) begin
    spiclk <= ~nxtcnt[0];
		vidclk <= ~nxtcnt[1];
    clk <= ~nxtcnt[1] ;
    // write gate and write cycle
    wg  <= (nxtcnt!=3)|~(W_en | boot) ;
    phi2_we <= (W_en | boot ) & nxtcnt[1];
    cnt<=nxtcnt;
    if (nxtcnt==0) begin
      Lcpu_address <= cpu_address;
      LD_out <= D_out;
      LW_en <= W_en;
    end
	end
`else
  // 15Mhz cpu
  reg [4:0] cnt;
  wire [4:0] nxtcnt;
  assign nxtcnt = cnt +1;
	always@(posedge fclk) begin
    spiclk <= ~nxtcnt[1];
		vidclk <= ~nxtcnt[1];
    clk <= ~nxtcnt[4] ;
    // write gate and write cycle
    wg  <= (nxtcnt!=31)|~(W_en | boot) ;
    phi2_we <= (nxtcnt[4:1]== 15) && (W_en | boot );
    cnt<=nxtcnt;
	end
`endif

  // ------------------------------------------------------------------------------------
  // Main 6502 CPU
  // ------------------------------------------------------------------------------------

	cpu main_cpu(
	     .clk(clk),
	     .reset(cpu_reset),
	     .AB(cpu_address),
	     .DI(D_in),
	     .DO(D_out),
	     .WE(W_en),
	     .IRQ(0),
	     .NMI(0),
	     .RDY(1) );

	// ------------------------------------------------------------------------------------
	// IO_space
	// ------------------------------------------------------------------------------------

  wire IO_select;
	wire PIO_select;
	wire Extension_select;
	wire VIA_select;
  wire ROMBank_select;
	wire VGAIO_select;
	wire IO_wr;
  wire SDcard_select;
  wire [7:0] IO_out;

	assign IO_select        = (cpu_address[15:12]==4'hB) ? 1 : 0         ; // #BXXX address
	assign PIO_select       = (cpu_address[11:10]==2'h0) ? IO_select : 0 ; // #B000 - #B3FF is PIO
	assign Extension_select = (cpu_address[11:10]==2'h1) ? IO_select : 0 ; // #B400 - #B7FF is Extension port
	assign VIA_select       = (cpu_address[11:10]==2'h2) ? IO_select : 0 ; // #B800 - #BBFF is VIA
	assign ROMBank_select   = (cpu_address[11:8]==4'hF) ? IO_select : 0 ; // #BF00 - #BFFF is ROMBank_select
	assign VGAIO_select     = (cpu_address[11:8]==4'hD) ? IO_select : 0 ; // #BD00 - #BDFF is VGAIO
  assign SDcard_select    = (cpu_address[11:8]==4'hC) ? IO_select : 0 ; // #BC00 - #BCFF is SDcard SPI
  
	assign IO_wr = ~wg;

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

  wire [7:0] piaPortA , PIO_out;
  wire unused,Speaker,CassOutEn,TapeOut;

  // interface to Keyboard
  wire [3:0] keyboard_row,graphics_mode;
  assign keyboard_row = piaPortA[3:0];
  assign graphics_mode = piaPortA[7:4];

  `pull_up(rept_key,  rept_key_t,		rept_keyp)
  `pull_up(shift_key, shift_keyt,		shift_keyp)
  `pull_up(ctrl_key,  ctrl_keyt,		ctrl_keyp)
  `pull_N_up(key_col,  key_colt,5,		key_colp)
  `pull_up(key_reset, key_reset_t, key_reset_p)

  PushButton_Debouncer rstkey(
    .clk(vidclk),
    .PB(key_reset_p),
    .PB_state(kbd_reset));
  
	// demux key row select
	reg[9:0] key_demux;
	assign key_row = key_demux;
  	
	always@*
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
  
  assign reboot_req = ~pll_locked | (kbd_reset & ~rept_keyp);  
  reg [3:0] Chigh;
  always @*
    Chigh <= {vga_vsync_out, rept_keyp, 2'b00};

  // connect PIA to keyboard and VGA generator.
  PIA8255 pia (
    //.clk(clk),
    .cs(PIO_select),
    .reset(reboot_req),
    .address(cpu_address[1:0]),
    .Din(D_out),
    .we(wg),
    .PIAout(PIO_out),
    .Port_A(piaPortA),
    .Port_B({shift_keyp, ctrl_keyp, key_colp}),
    .Port_C_low({unused,Speaker,CassOutEn,TapeOut}),
    .Port_C_high(Chigh)
  );

  

  wire [7:0] sd_out;
  assign IO_out = (SDcard_select)? sd_out: PIO_out;

    spi sdcard
  (
   .clk(spiclk),
   .reset(cpu_reset),
   .enable(SDcard_select),
   .rnw(wg|boot),
   .addr(cpu_address[2:0]),
   .din(D_out),
   .dout(sd_out),
   .miso(miso),
   .mosi(mosi),
   .ss(ss),
   .sclk(sclk)
   );
   


  // ------------------------------------------------------------------------------------
  // MOS ROM, BASIC ROM and minimal RAM
	// ------------------------------------------------------------------------------------


    reg [7:0] kernel_rom[0:4095];
    reg [7:0] basic_rom[0:4095];
    //reg [7:0] pcharme_rom[0:4095];
    reg [7:0] fp_rom[0:4095];
    reg [7:0] sddos_rom[0:4095];

    //initial $readmemh("roms/kernel.hex"		,kernel_rom);
    initial $readmemh("roms/akernel_patched.hex"		,kernel_rom);
    initial $readmemh("roms/basic.hex"		,basic_rom);
    
    initial $readmemh("roms/sddos.hex"	,sddos_rom);
    //initial $readmemh("roms/pcharme.hex"	,pcharme_rom);
    initial $readmemh("roms/floatingpoint.hex",fp_rom);
    
    wire [16:0] romaddr;
    wire [7:0] kernel_dat;
    wire [7:0] basic_dat;
    //wire [7:0] pcharme_dat;
    wire [7:0] fp_dat;
    wire [7:0] sddos_dat;
    
    
    assign kernel_dat  = (romaddr[15:12]==4'hF) ? kernel_rom[romaddr[11:0]]  : 8'h00;
    assign basic_dat   = (romaddr[15:12]==4'hC) ? basic_rom[romaddr[11:0]]   : 8'h00;
    //assign pcharme_dat = (romaddr[15:12]==4'hA) ? pcharme_rom[romaddr[11:0]] : 8'h00;
    assign fp_dat      = (romaddr[15:12]==4'hD) ? fp_rom[romaddr[11:0]]      : 8'h00;
    assign sddos_dat   = (romaddr[15:12]==4'hE) ? sddos_rom[romaddr[11:0]]   : 8'h00;
    
    
    wire [7:0] boot_data;
        
    //assign boot_data = kernel_dat | basic_dat | pcharme_dat | fp_dat;   
    assign boot_data = kernel_dat | basic_dat | sddos_dat | fp_dat;   

  // ------------------------------------------------------------------------------------
  // Bootloader
	// ------------------------------------------------------------------------------------
    reg [16:0] dma_addr;
    wire [16:0] next_dma_addr = dma_addr + 1;
    
    assign romaddr = dma_addr;
    
    
    always@(posedge clk) begin
      if (reboot_req)
        begin
          dma_addr <= 17'hC000;
          boot <= 1;
        end
      else
        if (dma_addr[16])
          boot <= 0;
        else
          dma_addr <= next_dma_addr;
    end
    
  // ------------------------------------------------------------------------------------
  // VGA signal generation
	// ------------------------------------------------------------------------------------

	
	vga display(
		.clk( vidclk ),
		.reset(reboot_req),
		.address(vdu_address),
		.data(vid_data),
		.settings(graphics_mode),
		.rgb(vga_rgb),
		.hsync(vga_hsync_out),
		.vsync(vga_vsync_out),
    .cs(VGAIO_select),
    .we(wg),
    .cpu_address(cpu_address[3:0]),
    .Din(D_out)
		);
		
    
	always@(posedge vidclk) begin
		rgb   <= vga_rgb;
		vsync <= vga_vsync_out;
		hsync <= vga_hsync_out;
		end

	// ------------------------------------------------------------------------------------
	// interlace video and cpu on memory bus (should be okay up to 50 MHz with 100MHz SRAM)
	// vdu_address and cpu_addres are both latched on clk so this should be fine.
	// ------------------------------------------------------------------------------------

    reg [1:0] sram_state;
    wire sram_wrlb, sram_wrub;
    wire [18:0] sram_addr;
    wire [15:0] sram_dout;
    wire [15:0] sram_din;

    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) sram_io [15:0] (
        .PACKAGE_PIN(SRAM_D),
        .OUTPUT_ENABLE(phi2_we),
        .D_OUT_0(sram_dout),
        .D_IN_0(sram_din)
    );

	// redirect ROM write.
	// Perhaps in future we want to enable dynamic roms
	wire romwrite = W_en & cpu_address[15] & cpu_address[14];//|cpu_address[13]) ;

    assign SRAM_A = vidclk ? { 6'b000100, vdu_address[12:0] } :boot ? {2'b00,dma_addr } :{ romwrite,2'b00,cpu_address};


    assign SRAM_nCE = 0;
    assign SRAM_nWE =  wg  ;
    assign SRAM_nOE = (phi2_we);
    assign SRAM_nLB = 0;//(phi2_we) ? wg : 0;
    assign SRAM_nUB = 0;//(phi2_we) ? wg : 0;
    assign sram_dout = { 8'd0, boot ? boot_data : D_out};

	
    reg [7:0] latch_SRAM_out;

    reg [7:0] tDin;


    // --------- phi2  video data -----------    
    always@(negedge vidclk) begin
      t_vid_data <= sram_din[7:0];
		end
    
    always@(posedge vidclk) begin
      vid_data <=t_vid_data;
    end
    
/*       
    assign D_in = IO_select? PIO_out:sram_din[7:0];
*/    
    // --------- data bus latch ---------
    always@(posedge clk) begin
      if (IO_select)
        D_in <= IO_out;
      else
        D_in <= sram_din[7:0];
    end

    // shiftlock led  
    reg lock;
    always@(posedge wg) if (cpu_address == 16'h00E7) lock <= D_out[5];
    
    assign led1 = lock;
    


endmodule
