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
`include "IO/IOsys.v"

`include "65Mhz.v"

`include "Bus/cpubus.v"

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

	
	reg  cpu_clock_A,cpu_clock_B,cpu_clock_C,cpu_clock_D;
	reg [2:0] ph;
	wire [2:0] addph;
	assign addph = ph + 1;
	
	reg vidgate;
	
	always@(posedge fclk ) begin
		if (~pll_locked) begin
			cpu_clock_A <= 0;
			cpu_clock_B <= 0;
			cpu_clock_C <= 0;
			cpu_clock_D <= 0;
			clk <= 1;
			ph <= 3'b000;
		end else begin
			ph <= addph;
			cpu_clock_A <= (addph!=3'b001);//cpu_clock_D;
			cpu_clock_B <= (addph!=3'b011);//cpu_clock_D;
			cpu_clock_C <= (addph!=3'b101);//cpu_clock_D;
			cpu_clock_D <= (addph!=3'b111);//cpu_clock_D;
			clk <= !addph[0];
		end
	end

    // ------------------------------------------------------------------------------------
    // Main 6502 CPU
    // ------------------------------------------------------------------------------------
    wire [18:0] cpu_address;
	  wire [7:0] Din;
    wire [7:0] D_out;
    reg IRQ,NMI,RDY;
    wire W_en;
    reg kbd_reset;
    wire cpu_reset = ~kbd_reset | ~pll_locked | boot ;

	cpubus main_cpuA(
	     .clks({clk,cpu_clock_D,cpu_clock_C,cpu_clock_B,cpu_clock_A}),
	     .reset(cpu_reset),
	     .AB(cpu_address),
	     .DI(Din),
	     .DO(D_out),
	     .offset(ph),
	     .nextoff(addph),
	     .WE(W_en),
	     .IRQ(IRQ),
	     .NMI(NMI),
	     .RDY(RDY) );
	     /*
	cpubus main_cpuB(
	     .clk(cpu_clock_B),
	     .reset(cpu_reset),
	     .AB(cpu_address),
	     .DI(Din),
	     .DO(D_out),
	     .offset(3'b001),
	     .out_en( (ph[2:1]==2'b01) ),
	     .WE(W_en),
	     .IRQ(IRQ),
	     .NMI(NMI),
	     .RDY(RDY) );     
	*/
	// ------------------------------------------------------------------------------------
  // Bus timeshare 
	// ------------------------------------------------------------------------------------
	// assign cpu_address = ph[1] ? ( ph[2]? { 3'b011, cpu_addressD } /* 11 D */ : { 3'b010, cpu_addressC } /* 10 C */) : (ph[2]? { 3'b001, cpu_addressB } /* 01 B */ : { 3'b000, cpu_addressA } /* 00 A */);
	// assign W_en = ph[1] ? (ph[2]? W_enD /* 11 D */ : W_enC /* 10 C */) : (ph[2]? W_enB /* 01 B */ : W_enA /* 00 A */);
	// assign D_out = ph[1] ? (ph[2]? D_outD /* 11 D */ : D_outC /* 10 C */) : (ph[2]? D_outB /* 01 B */ : D_outA /* 00 A */);

  // ------------------------------------------------------------------------------------
  // reset 
	// ------------------------------------------------------------------------------------
	always@(posedge fclk) begin
	    if (~pll_locked) begin
	       RDY<= 1;
	       NMI<=0;
	       IRQ<=0;
	    end 
	end
	// ------------------------------------------------------------------------------------
	    


	// ------------------------------------------------------------------------------------
	// Keyboard
	// ------------------------------------------------------------------------------------

    `pull_up(rept_key,  rept_key_t,		rept_keyp)
    `pull_up(shift_key, shift_keyt,		shift_keyp)
    `pull_up(ctrl_key,  ctrl_keyt,		ctrl_keyp)
    `pull_N_up(key_col, key_colt,5,		key_colp)
    `pull_up(key_reset, key_reset_t, key_reset_p)

	always@(posedge clk)
		begin
		kbd_reset <= key_reset_p;
	end

	// demux key row select
	reg[9:0] key_demux;

	
	wire [3:0] keyboard_row;
	
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
  
	reg[1:0] focus;

	
  wire focus_toggle = !(shift_keyp | ctrl_keyp | rept_keyp);
  
	wire [1:0] next_focus = focus + 1;
    
  reg [18:0] tab_count;
  
  wire [18:0] next_tab = tab_count + 1;
  
	reg next_window;
	reg prev_window;
	always@(posedge clk)
	begin
		if (~pll_locked)
     begin
			focus <= 2'b00;
      tab_count <= 19'h40000;
     end
    else
     begin
      if (focus_toggle)
       begin
        if (tab_count[18]==0)
          focus <= next_focus;         
        tab_count <= 19'h40000;
       end
      else
       if (tab_count[18]) tab_count <= next_tab;
		 end
	end

	// ------------------------------------------------------------------------------------
	// IO Space
	// ------------------------------------------------------------------------------------
	reg [3:0] graphics_mode;
	wire [7:0] PIO;
	wire IOSEL;
	wire [5:0] color0,color1,color2,color3 ;
	
	// combine all using bus.
	
	IOsys IOA (
			.reset(cpu_reset),
			.clk(clk),
			.address(cpu_address),
			.Din(D_out),
			.Dout(PIO),
			.WE(W_en),
			.IO_sel(IOSEL),
			.gmod(graphics_mode),
			.key_row(keyboard_row),
			.PIOinput( {vga_vsync_out, rept_keyp, shift_keyp, ctrl_keyp, key_colp}),
			.colors({color0,color1,color2,color3}),
			.active(focus),
			.visible(vdu_address[17:16])
     );
	
	/*
	wire BCFFsel = (cpu_address == 16'hBCFF)&&(W_en);
	always@(posedge clk)
	begin
		if (cpu_reset)
			focus <= 1;
		else
			if (BCFFsel)
				focus <= D_out[1:0];
	end
	*/
	

	
/*	
	always@(*) begin
	key_colpA = 6'b111111;
	key_colpB = 6'b111111;
	key_colpC = 6'b111111;
	key_colpD = 6'b111111;	
	if (focus[1])
		if (focus[0]) begin
			key_colpA = key_colp;
			keyboard_row = keyrowA;
			graphics_mode = graphics_modeA;
		end else begin
			key_colpB = key_colp;
			keyboard_row = keyrowB;
			graphics_mode = graphics_modeB;
		end
			
	else
		if (focus[0]) begin
			key_colpC = key_colp;
			keyboard_row = keyrowC;
			graphics_mode = graphics_modeC;
		end else begin
			key_colpD = key_colp;
			keyboard_row = keyrowD;
			graphics_mode = graphics_modeD;
		end

	end */
/*	
	always@(vdu_address[16]) begin
		if (vdu_address[17]) begin
			if (vdu_address[16]) 
				graphics_mode = graphics_modeA;
			else
				graphics_mode = graphics_modeC;
		end else
			if (vdu_address[16])
				graphics_mode = graphics_modeB;
			else
				graphics_mode = graphics_modeD;
	end
*/


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
    
    reg [7:0] kernel_dat;
    reg [7:0] basic_dat;
    reg [7:0] pcharme_dat;
    reg [7:0] fp_dat;
    
  // ------------------------------------------------------------------------------------
  // Bootloader
	// ------------------------------------------------------------------------------------
  
  reg [18:0] dma_addr;
  wire [18:0] next_dma_addr = dma_addr + 1;

  always@(posedge clk)
    begin
		if (reboot)
		begin
			dma_addr <= 19'h007000;
			boot <= 1;
		end
		else
			if (next_dma_addr[18]==1)
				boot <= 0;
			else begin
        dma_addr <= next_dma_addr;
      end
	end
  
  always@(posedge clk)
    begin
      kernel_dat  <= kernel_rom[next_dma_addr[11:0]];
      basic_dat   <= basic_rom[next_dma_addr[11:0]];
      pcharme_dat <= pcharme_rom[next_dma_addr[11:0]];
      fp_dat      <= fp_rom[next_dma_addr[11:0]];
    end
  
  wire [7:0] boot_data;
  assign boot_data = (dma_addr[15:12]==4'hF) ? kernel_dat :
                     (dma_addr[15:12]==4'hC) ? basic_dat :
                     (dma_addr[15:12]==4'hA) ? pcharme_dat :
                     (dma_addr[15:12]==4'hD) ? fp_dat : 8'h00;
  

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
	
  wire reboot = (pll_locked==0) || (key_reset_p==0 && rept_keyp==0);

    	
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

    wire [15:0] sram_dout;
    wire [15:0] sram_din;
    //reg [18:0] bus_address;
    wire WriteSRAM;

    assign sram_dout =  boot ? {8'h00,boot_data} : {8'h00,D_out};
    
    assign WriteSRAM = (boot|W_en)&!clk;

`ifdef verilator
	assign sram_din = WriteSRAM? 0 : SRAM_D;
	assign SRAM_D   = WriteSRAM? sram_dout:16'hZZZZ;
`else
    SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) sram_io [15:0] (
        .PACKAGE_PIN(SRAM_D),
        .OUTPUT_ENABLE(WriteSRAM),
        .D_OUT_0(sram_dout),
        .D_IN_0(sram_din)
    );
`endif
	
	// Bus arbitrator for video, BootDMA and CPU
	wire [18:0] bus_selected;
   
	// Hook up our bus signals to the SRAM
	assign SRAM_A = clk ? vdu_address :
                  boot ? dma_addr :
                  cpu_address;// bus_selected;
  assign SRAM_nCE = 0;
  assign SRAM_nWE = WriteSRAM ? fclk :1;
  assign SRAM_nOE = WriteSRAM;
  assign SRAM_nLB = 0;
  assign SRAM_nUB = 1;
	
	assign Din = (IOSEL) ? PIO : sram_din[7:0];
   
  // --------- phi2  video data -----------    
  always@(negedge clk ) begin
	  vid_data <= sram_din[7:0];
  end
    
  //always@(negedge clk ) begin
	//	vid_data <= t_vid_data;
	//	end
	
endmodule
