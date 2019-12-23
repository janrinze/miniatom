/*

	UP5K Atom
	
*/

// Include the sources from Arlet's 6502 verilog implementation.
// `include "6502/ALU.v"
`include "6502/cpu.v"

// ps2 interface
`include "ps2/keyboard.v"

`include "pll.v"
`include "vga/vga.v"
`include "pia8255.v"
`include "spi/spi.v"

`include "boot/bootloader.v"

`define __external_sram_


module top (
		// main clock
		input	pclk,
		
		output [7:0] LED,
		
		// diagnostic LEDs
		output	led1,
		output	led2,
//		output	led3,
		
		// VGA ouput on PMOD
		output	reg hsync,
		output	reg vsync,
		output	reg [3:0] red,
		output	reg [3:0] blue,
		output	reg [3:0] green,
	
`ifdef __external_sram_

		inout [7:0] SRAM_D,
		output reg [18:0] SRAM_A,
		output SRAM_nCE,
		output SRAM_nWE,
		output SRAM_nOE,
`endif
		// SD Card
		  input  miso,
		  output mosi,
		  output ss,
		  output sclk,

		// PS2 keyboard
		input	ps2_clk,
		input	ps2_data,

		// on-board SPI flash
		output	SPI_FLASH_CS,
		output	SPI_FLASH_SCLK,
		output	SPI_FLASH_MOSI,
		input	SPI_FLASH_MISO
	);

	//------------------------------------------------------------
	// base clock 
	//------------------------------------------------------------
	wire clk65;
	wire pll_locked;


	//------------------------------------------------------------
	// derived clock 
	//------------------------------------------------------------
	//reg cpu_clk;
	reg vga_clk;
	reg mem_clk;
	reg [6:0]	phase=0;
	
		// enable the high frequency oscillator,
	// which generates a 48 MHz clock
	wire clk_78;
	/*
	SB_HFOSC u_hfosc (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk_48)
	);
	*/
	pll uut(
		.clock_in(pclk),
		.clock_out(clk_78),
		.locked(pll_locked)
		);
	

	reg cpu_clk;
	reg writegate;
	
	// 25.3 ns cycle (275 MHz / 7)
	always@(posedge clk_78) begin
		phase <= {phase[5:0],~(|phase[5:0])};
		cpu_clk <= phase[0]|phase[1];						 					// 14.4 ns setup
		writegate <= ~((cpu_write | booting) & (phase[4]|phase[5]|phase[6]));	// 10.9 ns write pulse
	end
	
	
	
	always@(posedge cpu_clk) begin
		//cpu_clk <= ~cpu_clk;
		vga_clk <= ~vga_clk;
		mem_clk <= cpu_clk;
	end	
	
	
	
	
	
	//------------------------------------------------------------
	// Reset generation
	//------------------------------------------------------------

	reg [9:0] pwr_up_reset_counter = 0; // hold reset low for ~1ms
	wire      pwr_up_reset_n = &pwr_up_reset_counter;
	reg		  cpu_reset;
	reg		  hard_reset_n;
	wire	  break_n;
	
	always @(posedge cpu_clk)
		begin
			if (!pwr_up_reset_n)
				pwr_up_reset_counter <= pwr_up_reset_counter + 1;
			hard_reset_n <= pwr_up_reset_n;
			cpu_reset <= !hard_reset_n | !break_n |booting;
		end

	//------------------------------------------------------------
	// Internal Bus 
	//------------------------------------------------------------


	wire		cpu_write;
	wire [15:0]	cpu_address;
	reg  [7:0]	cpu_data_in;
	wire [7:0]	cpu_data_out;

	wire cs_vga_mem			= (cpu_address[15:13]==3'b100); // #8000-#9fff
	
	//------------------------------------------------------------
	// I/O Bus selectors (BXXXX)
	//------------------------------------------------------------

	wire Bxxx_select = (cpu_address[15:12]==4'hB);
	wire B0xx_select = (cpu_address[15:8]==8'hB0);
	wire B1xx_select = (cpu_address[15:8]==8'hB1);
	wire B2xx_select = (cpu_address[15:8]==8'hB2);
	wire B3xx_select = (cpu_address[15:8]==8'hB3);
	wire B4xx_select = (cpu_address[15:8]==8'hB4);
	wire B5xx_select = (cpu_address[15:8]==8'hB5);
	wire B6xx_select = (cpu_address[15:8]==8'hB6);
	wire B7xx_select = (cpu_address[15:8]==8'hB7);
	wire B8xx_select = (cpu_address[15:8]==8'hB8);
	wire B9xx_select = (cpu_address[15:8]==8'hB9);
	wire BAxx_select = (cpu_address[15:8]==8'hBA);
	wire BBxx_select = (cpu_address[15:8]==8'hBB);
	wire BCxx_select = (cpu_address[15:8]==8'hBC);
	wire BDxx_select = (cpu_address[15:8]==8'hBD);
	wire BExx_select = (cpu_address[15:8]==8'hBE);
	wire BFxx_select = (cpu_address[15:8]==8'hBF);
	
	wire cs_pia				= B0xx_select; // #b000-#b00f


  // ------------------------------------------------------------------------------------
  // Bootloader
  // ------------------------------------------------------------------------------------

	wire booting;
	wire [7:0] boot_data;
	wire [15:0] boot_address;
	
	bootloader boot (
		// clock and reset
		.clk(cpu_clk),
		.reset(~hard_reset_n),
		// control
		.reboot_request(~(break_n|rept_n)),
		.booting(booting),
		// bus
		.boot_data(boot_data),
		.boot_address(boot_address),
		// flash
		.SPI_FLASH_CS(SPI_FLASH_CS),
		.SPI_FLASH_SCLK(SPI_FLASH_SCLK),
		.SPI_FLASH_MOSI(SPI_FLASH_MOSI),
		.SPI_FLASH_MISO(SPI_FLASH_MISO)
	);

	
	//-------------------------------------------------
	// Single port RAM
	//-------------------------------------------------
	
	wire [15:0] data_lo,data_hi;
	wire[15:0] sram_address = booting ? boot_address : cpu_address;
	
	wire [7:0] sram_dout = booting ? boot_data : cpu_data_out;
	
	
	
`ifdef __external_sram_
	reg [7:0] mem_dat;
	
  wire [18:0] sram_addr;
  //wire [7:0] sram_dout;
  wire [7:0] sram_din;
  wire sram_write = (booting|cpu_write);
  wire sram_writegate = writegate ;//(~sram_write)|cpu_clk;
  
  SB_IO #(
        .PIN_TYPE(6'b 1010_01),
        .PULLUP(1'b 0)
    ) sram_io [7:0] (
        .PACKAGE_PIN(SRAM_D),
        .OUTPUT_ENABLE(sram_write),
        .D_OUT_0(sram_dout),
        .D_IN_0(sram_din)
    );	
	
	always@*
		SRAM_A={3'b000,sram_address};
	
	assign SRAM_nCE=1'b0;
	//assign sram_dout = 
	assign SRAM_nWE = writegate;
	assign SRAM_nOE = sram_write;// ~writegate;//sram_write;
	
	always@(posedge cpu_clk)
		cpu_data_in <= Bxxx_select ? IO_out : sram_din;
`else

	SB_SPRAM256KA memlo (
		.ADDRESS(sram_address[14:1]),
		.DATAIN({sram_write_data,sram_write_data}),
		.MASKWREN(sram_address[0]?4'b1100:4'b0011),
		.WREN((cpu_write|booting)&~sram_address[15]),
		.CHIPSELECT(1'b1),
		.CLOCK(mem_clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(data_lo)
	);
	SB_SPRAM256KA memhi (
		.ADDRESS(sram_address[14:1]),
		.DATAIN({sram_write_data,sram_write_data}),
		.MASKWREN(sram_address[0]?4'b1100:4'b0011),
		.WREN((cpu_write|booting)&sram_address[15]),
		.CHIPSELECT(1'b1),
		.CLOCK(mem_clk),
		.STANDBY(1'b0),
		.SLEEP(1'b0),
		.POWEROFF(1'b1),
		.DATAOUT(data_hi)
	);

	reg [7:0] mem_dat;
	
	always@(posedge cpu_clk)
		cpu_data_in <= Bxxx_select ? IO_out : (cpu_address[15] ? (cpu_address[0]?data_hi[15:8]:data_hi[7:0]) : (cpu_address[0]?data_lo[15:8]:data_lo[7:0]));
`endif	
	//------------------------------------------------------------
	// 6502 cpu 
	//------------------------------------------------------------

	cpu main_cpu(
	     .clk(cpu_clk),
	     .reset(cpu_reset),
	     .AB(cpu_address),
	     .DI(cpu_data_in),
	     .DO(cpu_data_out),
	     .WE(cpu_write),
	     .IRQ(0),
	     .NMI(0),
	     .RDY(1'b1) );

	//------------------------------------------------------------
	// PIA
	//------------------------------------------------------------

	wire [7:0] pia_out;
	wire [7:0] piaPortA;
	wire [3:0] keyboard_row,graphics_mode;
	assign keyboard_row = piaPortA[3:0];
	assign graphics_mode = piaPortA[7:4];
	
	wire vga_hsync_out,vga_vsync_out;
  
	reg [3:0] Chigh;
	always @*
		Chigh <= {vga_vsync_out, rept_n, 2'b00};  
    
	PIA8255 pia (
		.clk(cpu_clk),
		.cs(cs_pia),
		.reset(cpu_reset),
		.address(cpu_address),
		.Din(cpu_data_out),
		.we(cpu_write),
		.PIAout(pia_out),
		.Port_A(piaPortA),
		.Port_B({shift_n, ctrl_n, keyout}),
		.Port_C_low(),
		.Port_C_high(Chigh)
    );
    reg [7:0] IO_out;
    wire [7:0] sd_out;
    always@*
		if (BCxx_select) IO_out=sd_out;
		else if (cs_pia) IO_out=pia_out;
			else IO_out=8'h00;



   // ===============================================================
   // Keyboard
   // ===============================================================

   wire       rept_n;
   wire       shift_n;
   wire       ctrl_n;
   wire [3:0] row = piaPortA[3:0];
   wire [5:0] keyout;

   keyboard KBD
     (
      .CLK(cpu_clk),
      .nRESET(hard_reset_n),
      .PS2_CLK(ps2_clk),
      .PS2_DATA(ps2_data),
      .KEYOUT(keyout),
      .ROW(row),
      .SHIFT_OUT(shift_n),
      .CTRL_OUT(ctrl_n),
      .REPEAT_OUT(rept_n),
      .BREAK_OUT(break_n),
      //.TURBO(turbo)
      );
/*
	wire [8:0] rgb;	
	video_chip vga(
		.clk(vga_clk),
		.reset(cpu_reset),
		.graphics_mode(graphics_mode),
		.reg_cs(BExx_select),
		.mem_cs(cs_vga_mem),
		.we(cpu_write),
		.address(cpu_address),
		.data(cpu_data_out),
		.rgb(rgb),
		.hsync(vga_hsync_out),
		.vsync(vga_vsync_out)
	);
	*/	
	//------------------------------------------------------------
	// video chip
	//------------------------------------------------------------

	reg [7:0] vram[0:8191];
	wire [5:0] rgb;
	wire [12:0] vid_address;
	reg [7:0] to_video;
	
	always@(posedge cpu_clk)
		if (cpu_write & cs_vga_mem) vram[cpu_address[12:0]]<=cpu_data_out;
	
	always@(posedge cpu_clk)
		to_video <= vram[vid_address];
	
	wire vga_vsync_out,vga_hsync_out;
	vga video_chip(
		.clk(vga_clk),
		.cpu_clk(cpu_clk),
		.reset(~pll_locked),
		.data(to_video),
		.settings(graphics_mode),
		.address(vid_address),
		.rgb(rgb),
		.hsync(vga_hsync_out),
		.vsync(vga_vsync_out),
		.req(),
		.cs(BExx_select),
		.we(cpu_write),
		.cpu_address(cpu_address),
		.Din(cpu_data_out)
	);

	always@(posedge vga_clk) begin
		red		<= {rgb[5:4],rgb[5:4]};
		green	<= {rgb[3:2],rgb[3:2]};
		blue	<= {rgb[1:0],rgb[1:0]};
		vsync	<= vga_vsync_out;
		hsync	<= vga_hsync_out;
		end

	reg [24:0] cpu_cnt=0;
	always@(posedge cpu_clk)
		cpu_cnt<=cpu_cnt+1;
	
	assign LED=cpu_cnt[24:17];
	//------------------------------------------------------------
	// SDcard SPI
	//------------------------------------------------------------
	
    spi sdcard
	  (
		   .clk(cpu_clk),
		   .reset(cpu_reset),
		   .enable(BCxx_select),
		   .rnw(cpu_write),
		   .addr(cpu_address[2:0]),
		   .din(cpu_data_out),
		   .dout(sd_out),
		   .miso(miso),
		   .mosi(mosi),
		   .ss(ss),
		   .sclk(sclk)
	   );
	   
`ifdef __USE_VIA__	   
   // ===============================================================
   // 6522 VIA at 0xB8xx
   // ===============================================================

   m6522 VIA
     (
      .I_RS(cpu_address[3:0]),
      .I_DATA(cpu_data_out),
      .O_DATA(via_dout),
      .O_DATA_OE_L(),
      .I_RW_L(!cpu_write),
      .I_CS1(B8xx_select),
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
      .I_P2_H(cpu_clk),
      .RESET_L(!cpu_reset),
      .ENA_4(cpu_clk),
      .CLK(cpu_clk)
      );
`endif
      
    reg lock;
      
   // Snoop bit 5 of #E7 (the lock flag)
   always @(posedge cpu_clk)
     if (cpu_reset)
       lock <= 1'b0;
     else 
       if ((cpu_address == 16'he7) && !cpu_write)
         lock <= cpu_data_out[5];
    assign led1=lock;
    assign led2=!ss;
    
endmodule
