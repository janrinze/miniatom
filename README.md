# miniatom
Acorn Atom in minimal configuration for iCE40 HX8K ICOboard

The Acorn Atom is a 1980's home computer. It requires very little resources.
It makes a very good candidate for a minimal implementation on the ICOboard.

--- Work in Progress ---

status:

	- VGA 1024x768 vga output for text and mode 4 scaled.
	- RGB 2:2:2 output, 4 entry LUT for colors
	- CPU runs at 32.5 MHz and the prompt is visible
	- fully functional keyboard.
	- BASIC,FP and P-Charme working.
	- SDcard access over SPI and SDDOS rom.

requirements:

	- IceStorm tools for verilog compilation.
	- Arlet's 6502 in directory  available in Arlet6502
	- GNU make
	- icotools for programming ICOboard
	- ICOboard with 1MB SRAM (128K should work too, untested)
	- SDcard connection
	- VGA connection PMOD-VGA.

Memory map of this ATOM:

	F000   ROM     MM52164    IC20  - onboard MOS
	E000   ROM                      - onboard SDDOS
	D000   ROM     MM52132    IC21	- onboard FPROM
	C000   ROM     MM52164    IC20  - onboard BASIC
	BD00   IO      Extension        - VGA colour table.
	B800   VIA     6522       IC1   - onboard VIA 6522
	B400   IO      Extension        - PL8
	B000   PPI     INS8255    IC25	- keyboard
	A000   ROM     MN52132    IC24	- onboard P-Charme
	9xxx   Video   RAM              - external SRAM
	8xxx   Video   RAM              - external SRAM
	0000 - 7FFF    RAM              - external SRAM

VGA output:

# PMOD VGA (diligent)
# connects to two PMOD connectors.
 hsync B8
 vsync A9
 red[0] A5
 red[1] A2
 red[2] C3
 red[3] B4
 blue[0] B7
 blue[1] B6
 blue[2] B3
 blue[3] B5
 green[0] D8
 green[1] B9
 green[2] B10
 green[3] B11
	
Keyboard connection:

	set_io key_col[0]       F11
	set_io key_col[1]       E14
	set_io key_col[2]       F12
	set_io key_col[3]       E11
	set_io key_col[4]       D11
	set_io key_col[5]       D10
	set_io ctrl_key         G11
	set_io shift_key        E13
	set_io rept_key         F9
	set_io key_reset        E10

	set_io key_row[0]       K13
	set_io key_row[1]       J13
	set_io key_row[2]       J11
	set_io key_row[3]       M15
	set_io key_row[4]       M16
	set_io key_row[5]       H14
	set_io key_row[6]       K15
	set_io key_row[7]       G13
	set_io key_row[8]       F14
	set_io key_row[9]       T16

SD Card connection:

	set_io ss       T15
	set_io mosi     T14
	set_io sclk     T11
	set_io miso     R10
		
It still needs more attention to get it fully compatible.
Next up will be timers and more screen modes.
Hopefully some nice high res text modes too.

Jan Rinze.
