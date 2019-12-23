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
 
`include "icosoc_flashmem.v"

  // ------------------------------------------------------------------------------------
  // Bootloader
  // ------------------------------------------------------------------------------------

module bootloader (
		// clock and reset
		input clk,
		input reset,
		// control
		input reboot_request,
		output reg booting,
		// bus
		output reg [7:0] boot_data,
		output reg [15:0] boot_address,
		// flash
		output SPI_FLASH_CS,
		output SPI_FLASH_SCLK,
		output SPI_FLASH_MOSI,
		input SPI_FLASH_MISO,
	);
	
	wire [31:0]	flash_data;
	reg [23:0]	flash_addr;
	reg			flash_valid;
	wire		flash_ready;

	reg [31:0]	flash_copy;
	reg [16:0]	dma_addr;
	reg [2:0]	bl_state;
	wire [16:0]	next_dma_addr = dma_addr + 1;
	wire [23:0]	next_flash_addr = flash_addr + 4;

  icosoc_flashmem flasmem( 
		.clk(clk),
		.resetn(~reset),
		.valid(flash_valid),
		.ready(flash_ready),
		.addr(flash_addr),
		.rdata(flash_data),
		.spi_cs(SPI_FLASH_CS),
		.spi_sclk(SPI_FLASH_SCLK ),
		.spi_mosi(SPI_FLASH_MOSI ),
		.spi_miso(SPI_FLASH_MISO)
	);
  
	// Bootloader statemachine.  
	`define BL_IDLE 0
	`define BL_SETUP 1
	`define BL_WAITFLASH 2
	`define BL_WRITE1 3
	`define BL_WRITE2 4
	`define BL_WRITE3 5
	`define BL_WRITE4 6
	`define BL_DONE 7

	always@*
		boot_address=dma_addr[15:0];
    
    always@(posedge clk) begin
      if (reset) begin
        booting <= 0;
        flash_valid <=0;
        bl_state <= `BL_SETUP;
        flash_addr <= 24'h40000;
        boot_data <= 8'h00;
      end
      else 
        case (bl_state)
        `BL_IDLE:       begin
                          booting <= 0;
                          flash_valid <=0;
                          bl_state <= reboot_request ? `BL_SETUP : `BL_IDLE;
                        end
        `BL_SETUP:      begin
                          flash_addr <= 24'h40000;
                          dma_addr <= 17'h8000;
                          flash_valid <=1;
                          booting <=1;
                          bl_state <= `BL_WAITFLASH;
                        end
        `BL_WAITFLASH:  if (flash_ready) begin
                           flash_copy <= flash_data;
                           flash_addr <= next_flash_addr;
                           bl_state <= `BL_WRITE1;
                        end
        `BL_WRITE1:     begin
                          //boot_we<=1;
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

endmodule
