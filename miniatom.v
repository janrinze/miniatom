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
`include "m6522/via6522.v"
`include "utils/debounce.v"
/*
   Include the sources from Arlet's 6502 verilog implementation.
   
*/
`include "Arlet6502/ALU.v"
`include "Arlet6502/cpu.v"
`include "spi/spi.v"
`include "flashmem/icosoc_flashmem.v"

/*  TODO:

    - implement new 6502

          Memory map of this ATOM

          FFFF   Top of memory


          F000   ROM     MM52164    IC20  - onboard MOS
          E000   ROM                      - onboard SDDOS
          D000   ROM     MM52132    IC21	- onboard FPROM
          C000   ROM     MM52164    IC20  - onboard BASIC
          BC00   extension                - VGA colour table.
          B800   VIA     6522	    IC1     - onboard VIA 6522
          B400   Extension	        PL8
          B000   PPI     INS8255    IC25	- keyboard
          A000   ROM     MN52132    IC24	- onboard P-Charme
          0-9FFF                          - onboard RAM

  General Idea:

    1024x768 ATOM screen with 4x4 pixel size.

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
	
    // vga RGB 4:4:4 output
    output reg hsync,
    output reg vsync,
    
    output reg [3:0] red,
    output reg [3:0] green,
    output reg [3:0] blue,
    output vgaclk,
    output vgade,
	
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
  output reg led1,
  input  miso,
  output mosi,
  output ss,
  output sclk,

  output SPI_FLASH_CS,
  output SPI_FLASH_SCLK ,
  output SPI_FLASH_MOSI ,
  input SPI_FLASH_MISO
  
);

 reg vgaclk=0;
  // clock signals
  wire fclk;			// 100 MHz clock icoboard
  wire pll_locked;	// signal when pll has reached lock
  reg [11:0]rcnt=0;
  reg hard_reset=0;
  reg n_hard_reset=0;
  always@(posedge fclk)
  begin
	hard_reset   <= ~rcnt[11];
	n_hard_reset <= rcnt[11];
	if(~pll_locked)
		rcnt<=0;
	else
		if(~rcnt[11]) rcnt<=rcnt+1;
  end
  
  
  //reg reset=0;		// global reset register

  reg cpuclk,vidclk;			// 32.5 MHz derived system clocks
  reg boot;
  wire ready;
  reg phi2_we;
  
  wire vga_req;

  
  // reset signals
  wire kbd_reset;
  wire cpu_reset = kbd_reset | hard_reset | boot;
  wire reboot_req; 
  
  // CPU Bus signals
  wire [15:0] cpu_address;
  reg [7:0] D_in;
  wire [7:0] D_out;
  wire W_en;
  reg wg,n_wg;

  reg IRQ=0,NMI=0,RDY=0;
  
  /* 
  // Latched CPU signals  
  reg [15:0] Lcpu_address;
  reg [7:0] LD_out;
  reg LW_en;
  */
  
  // VGA bus and signals
  wire [12:0] vdu_address;
  reg  [7:0]  vid_data;
  reg  [7:0]  t_vid_data;
  wire [5:0]  vga_rgb;
  wire        vga_hsync_out;
  wire        vga_vsync_out;
  wire [7:0]  via_dout;
  wire        via_irq_n;
  
  // ------------------------------------------------------------------------------------
  // Clock generation
  // ------------------------------------------------------------------------------------
	
/* 128.125 MHz	*/
SB_PLL40_CORE #(
                .FEEDBACK_PATH("SIMPLE"),
                .DIVR(4'b0011),         // DIVR =  3
                .DIVF(7'b0101000),      // DIVF = 40
                .DIVQ(3'b011),          // DIVQ =  3
                .FILTER_RANGE(3'b010)   // FILTER_RANGE = 2
        ) uut (
                .LOCK(pll_locked),
                .RESETB(1'b1),
                .BYPASS(1'b0),
                .REFERENCECLK(pclk),
                .PLLOUTCORE(fclk)
                );



	// fclk is 130 MHz
	// spiclk is 65 Mhz
	// clk is 32.5 MHz
	// vidclk is 32.5 MHz


  // 30 MHz cpu
  reg ph0 =0;
  reg ph1 =0;
  reg ph2 =0;
  reg ph3 =0;
  reg latch_cpu;
  reg latch_vga;
  reg cpu_window;
  reg vga_window;
  reg [18:0] sram_addr;
  reg sram_noe;
  reg sram_oe;
  reg clk_1mhz=0;
  
  reg [1:0] phcnt=0;
  reg [7:0] preload_div=0;
  
  `define ALLOW_VGA
  /*
  always@(posedge fclk) begin
	blue[3] <= ph0;
	vgaclk  <= ph1;
	blue[0] <= ph2;
	hsync   <= ph3;
   end
   */
   reg [6:0] once_16=0;
   always@(posedge cpuclk) begin
		once_16<=once_16+1;
		if (once_16==7'd15) begin
			once_16<=0;
			clk_1mhz<=~clk_1mhz;
		end
	end

  reg clk_en=0;
  reg [7:0] slow_down=0;
  
  
  always@(posedge fclk) begin
	  phcnt <= phcnt+1;
      ph0 <= phcnt==2'd0;
      ph1 <= phcnt==2'd1;
      ph2 <= phcnt==2'd2;
      ph3 <= phcnt==2'd3;
      
      if (ph3) begin
		if (slow_down==8'd0) begin
		 slow_down<=preload_div;
		 clk_en<=1;
		end
		else begin
		 slow_down<=slow_down+1;
		 clk_en<=0;
		end
      end
      
      cpuclk     <= (ph0|ph1);// & clk_en;// | vga_req ;
      latch_cpu  <= ph0;//& clk_en;
      cpu_window <= (ph3|ph2);//& clk_en;
      wg         <= (W_en | boot)&ph3;//& clk_en;
      n_wg       <= ~((W_en | boot)&ph3);//& clk_en);
      sram_oe    <= ~((W_en | boot)&(ph2|ph3));//& clk_en);
      sram_noe   <= (W_en | boot)&(ph2|ph3);//& clk_en;
      vidclk     <= ph2|ph3;// 180 degree
      latch_vga  <= ph2;
      vga_window <= ph0|ph1; 
      vgaclk     <= ph1|ph3;// 65 MHz
      
      sram_addr  <= (ph0|ph1) ? { 6'b000100, vdu_address[12:0] } :
                            boot ? {2'b00,dma_addr } :
                            { romwrite,2'b00,cpu_address};
	end

  // ------------------------------------------------------------------------------------
  // Main 6502 CPU
  // ------------------------------------------------------------------------------------

	cpu main_cpu(
	     .clk(cpuclk),
	     .reset(cpu_reset|~spi_ready),
	     .AB(cpu_address),
	     .DI(D_in),
	     .DO(D_out),
	     .WE(W_en),
	     .IRQ(via_irq_n),
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
  assign VIA_select       = (cpu_address[11:8]==4'h8) ? IO_select : 0 ; // #B800 - #BBFF is VIA
  assign ROMBank_select   = (cpu_address[11:8]==4'hF) ? IO_select : 0 ; // #BF00 - #BFFF is ROMBank_select
  assign VGAIO_select     = (cpu_address[11:8]==4'hD) ? IO_select : 0 ; // #BD00 - #BDFF is VGAIO
  assign SDcard_select    = (cpu_address[15:4] == 12'hbc0);            // #BC00 - #BC0F is SDcard SPI
  
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

  `pull_up(rept_key,  rept_key_t,  rept_keyp)
  `pull_up(shift_key, shift_keyt,  shift_keyp)
  `pull_up(ctrl_key,  ctrl_keyt,   ctrl_keyp)
  `pull_up(key_reset, key_reset_t, key_reset_p)

  `pull_N_up(key_col, key_colt, 5, key_colp)

  PushButton_Debouncer rstkey(
    .clk(cpuclk),
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
  
  assign reboot_req = kbd_reset & ~rept_keyp;  
  reg [3:0] Chigh;
  always @*
    Chigh <= {~vga_vsync_out, rept_keyp, 2'b00};

  // connect PIA to keyboard and VGA generator.
  PIA8255 pia (
    .clk(cpuclk),
    .cs(PIO_select),
    .reset(cpu_reset),
    .address(cpu_address[1:0]),
    .Din(D_out),
    .we(W_en),
    .PIAout(PIO_out),
    .Port_A(piaPortA),
    .Port_B({shift_keyp, ctrl_keyp, key_colp}),
    .Port_C_low({unused,Speaker,CassOutEn,TapeOut}),
    .Port_C_high(Chigh)
  );

  

  wire [7:0] sd_out;
  assign IO_out = (SDcard_select)? sd_out:(VIA_select)?via_dout :PIO_out;
  `pull_up(miso, miso_t, miso_p)
  wire mosi_r;
  assign mosi= mosi_r;
  wire spi_ready;
  
    spi sdcard
  (
   .clk(cpuclk),
   .reset(cpu_reset),
   .enable(SDcard_select),
   .rnw(~W_en),
   .addr(cpu_address[2:0]),
   .din(D_out),
   .dout(sd_out),
   .miso(miso_p),
   .mosi(mosi_r),
   .ss(ss),
   .sclk(sclk),
   .ready(spi_ready)
   );
   
   // ===============================================================
   // 6522 VIA at 0xB8xx
   // ===============================================================
/*
   m6522 VIA
     (
      .I_RS(cpu_address[3:0]),
      .I_DATA(D_out),
      .O_DATA(via_dout),
      .O_DATA_OE_L(),
      .I_RW_L(~W_en),
      .I_CS1(VIA_select),
      .I_CS2_L(1'b0),
      .O_IRQ_L(via_irq_n),
      .I_CA1(1'b0),
      .I_CA2(1'b0),
      .O_CA2(),
      .O_CA2_OE_L(),
      .I_PA(8'b0),
      .O_PA(),
      .O_PA_OE_L(),
      .I_CB1(1'b0),
      .O_CB1(),
      .O_CB1_OE_L(),
      .I_CB2(1'b0),
      .O_CB2(),
      .O_CB2_OE_L(),
      .I_PB(8'b0),
      .O_PB(),
      .O_PB_OE_L(),
      .I_P2_H(!cpuclk),
      .RESET_L(!cpu_reset),
      .ENA_4(cpuclk),
      .CLK(cpuclk)
      );
*/
via6522 VIA   (.data_out(via_dout),       // cpu interface
               .data_in(D_out),
               .addr(cpu_address[3:0]),
               .strobe(VIA_select),
               .we(W_en),
               .irq(via_irq_n),
				/*
               .porta_out,
               .porta_in,
               .portb_out,
               .portb_in,

               .ca1_in,
               .ca2_out,
               .ca2_in,
               .cb1_out,
               .cb1_in,
               .cb2_out,
               .cb2_in,
				*/
               .slow_clock(clk_1mhz),
               .clk(vidclk),
               .reset(cpu_reset)
       );
  // ------------------------------------------------------------------------------------
  // Bootloader
	// ------------------------------------------------------------------------------------
  
  wire [31:0] flash_data;
  reg [23:0] flash_addr;
  reg flash_valid;
  wire flash_ready;
  
  reg [31:0]  flash_copy;
  
  icosoc_flashmem flasmem( 
  .clk(cpuclk),
  .resetn( n_hard_reset),
  .valid( flash_valid),
  .ready( flash_ready),
  .addr( flash_addr),
  .rdata( flash_data),
  .spi_cs( SPI_FLASH_CS),
  .spi_sclk(SPI_FLASH_SCLK ),
  .spi_mosi(SPI_FLASH_MOSI ),
  .spi_miso(SPI_FLASH_MISO)
   );
    //reg [16:0] dma_addr;
    reg [16:0] dma_addr;
    
    reg [2:0] bl_state;
    wire [16:0] next_dma_addr = dma_addr + 1;
    wire [23:0] next_flash_addr = flash_addr + 4;
    reg [7:0] boot_data;
    
  
// Bootloader statemachine.  
`define BL_IDLE 0
`define BL_SETUP 1
`define BL_WAITFLASH 2
`define BL_WRITE1 3
`define BL_WRITE2 4
`define BL_WRITE3 5
`define BL_WRITE4 6
`define BL_DONE 7
    
    always@(posedge cpuclk) begin
      if (hard_reset) begin
        boot <= 0;
        flash_valid <=0;
        bl_state <= `BL_SETUP;
        flash_addr <= 24'h40000;
        boot_data <= 8'h00;
      end
      else 
        case (bl_state)
        `BL_IDLE:       begin
                          boot <= 0;
                          flash_valid <=0;
                          if (reboot_req)bl_state <= `BL_SETUP;
                        end
        `BL_SETUP:      begin
                          flash_addr <= 24'h40000;
                          dma_addr <= 17'h8000;
                          flash_valid <=1;
                          boot<=1;
                          bl_state <= `BL_WAITFLASH;
                        end
        `BL_WAITFLASH:  if (flash_ready) begin
                           flash_copy <= flash_data;
                           flash_addr <= next_flash_addr;
                           bl_state <= `BL_WRITE1;
                        end
        `BL_WRITE1:     begin
                          // boot_we<=1;
                          boot_data <= flash_copy[7:0];
                          bl_state <= `BL_WRITE2;
                        end
        `BL_WRITE2:     begin
                          dma_addr <= next_dma_addr;
                          boot_data <= flash_copy[15:8];
                          bl_state <= `BL_WRITE3;
                        end
        `BL_WRITE3:     begin
                          dma_addr <= next_dma_addr;
                          boot_data <= flash_copy[23:16];
                          bl_state <= `BL_WRITE4;
                        end
        `BL_WRITE4:     begin
                          dma_addr <= next_dma_addr;
                          boot_data <= flash_copy[31:24];
                          bl_state <= `BL_DONE;
                        end
        `BL_DONE:       begin
                          dma_addr <= next_dma_addr;
                          bl_state <= next_dma_addr[16] ? `BL_IDLE : `BL_WAITFLASH;
                        end
        endcase
    end
    
  // ------------------------------------------------------------------------------------
  // VGA signal generation
	// ------------------------------------------------------------------------------------

	
	vga display(
		.clk( vidclk ),
		.reset(cpu_reset),
		.address(vdu_address),
		.data(vid_data),
		.settings(graphics_mode),
		.rgb(vga_rgb),
		.hsync(vga_hsync_out),
		.vsync(vga_vsync_out),
		.bg(vgade),
	    .req(vga_req),
	    .cs(VGAIO_select),
	    .we(wg),
	    .cpu_address(cpu_address[3:0]),
	    .Din(D_out)
		);
		
    `ifdef ALLOW_VGA
	always@(posedge vidclk) begin
		red   <= {vga_rgb[5:4],vga_rgb[5:4]};
		green <= {vga_rgb[3:2],vga_rgb[3:2]};
		blue  <= {vga_rgb[1:0],vga_rgb[1:0]};
		vsync <= ~vga_vsync_out;
		hsync <= ~vga_hsync_out;
	end
`endif
	// ------------------------------------------------------------------------------------
	// interlace video and cpu on memory bus (should be okay up to 50 MHz with 100MHz SRAM)
	// vdu_address and cpu_addres are both latched on clk so this should be fine.
	// ------------------------------------------------------------------------------------

  wire [15:0] sram_dout;
  wire [15:0] sram_din;

  SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) sram_io [15:0] (
        .PACKAGE_PIN(SRAM_D),
        .OUTPUT_ENABLE(sram_noe),
        .D_OUT_0(sram_dout),
        .D_IN_0(sram_din)
    );

  // redirect ROM write.
  // Perhaps in future we want to enable dynamic roms
  wire romwrite = W_en & cpu_address[15] & cpu_address[14];//|cpu_address[13]) ;
  

  assign SRAM_A    = sram_addr;
  assign SRAM_nCE  = 0;
  assign SRAM_nWE  = n_wg;
  assign SRAM_nOE  = sram_noe;
  assign SRAM_nLB  = 0;
  assign SRAM_nUB  = 0;
  assign sram_dout = { 8'd0, boot ? boot_data : D_out};
   
  always@(posedge latch_vga) begin
    if (vga_req) vid_data <=sram_din[7:0];
  end
   
  // --------- data bus latch ---------
  always@(posedge latch_cpu) begin
    if (IO_select)
      D_in <= IO_out;
    else
      D_in <= sram_din[7:0];
  end

  // shiftlock led  
  reg lock;
  always@(posedge cpuclk) begin
    if (W_en) begin
		if (cpu_address == 16'h00E7) lock <= D_out[5];
		if (cpu_address == 16'hB400) preload_div <= D_out;
	end
  end
  
  reg [31:0] led_cntr=0;
  always@(posedge ph0) begin
	led_cntr<=led_cntr+1;
	led1 <= cpu_reset;
  end

endmodule
