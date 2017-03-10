# miniatom
Acorn Atom in minimal cofiguration for iCE40 HX8K ICOboard

The Acorn Atom is a 1980's home computer. It requires very little resources.
It makes a very good candidate for a minimal implementation on the HX8K.

--- Work in Progress ---

status:

	- VGA 1024x768 vga output for text and mode 4 scaled.
	- RGB 2:2:2 output, 4 entry LUT for colors
	- CPU runs at 32.5 MHz and the prompt is visible
	- fully functional keyboard.
	- BASIC,FP and P-Charme working.

requirements:

	- IceStorm tools for verilog compilation and HX8K programming
	- Arlet's 6502 in directory ../verilog-6502
	- GNU make
	- icotools for programming ICOboard
	- ICOboard with 1MB SRAM (128K should work too, untested)

Memory map:

	Fxxx   ROM     MM52164    IC20        - onboard MOS

	Exxx   Reserved -Disk Operating System

	Dxxx   ROM     MM52132    IC21        - onboard FP-ROM

	C000   ROM     MM52164    IC20        - onboard BASIC

	BC00   VGA LUT						  - BC00 : Background color
											BC01 : Foreground color
	
	B800   VIA     6522       IC1         - timer ? N.A.
	B400   Extension          PL8
	B000   PPI     INS8255    IC25        - keyboard

	A000   ROM     MN52132    IC24        - onboard P-Charme

	9xxx   Video RAM                      - external SRAM
	8xxx   Video RAM                      - external SRAM

	0000 - 7FFF    RAM                    - external SRAM

VGA output:

	hsync B4
	vsync B5

	# RGB 2:2:2
	rgb[0] B3 (blue  lsb)
	rgb[1] C3 (blue  msb)
	rgb[2] B7 (green lsb)
	rgb[3] A5 (green msb)
	rgb[4] B6 (red   lsb)
	rgb[5] A2 (red   msb)
	
	Current RGB 2:2:2 to VGA connector
	msb connects to vga connector with 390 ohm
	lsb connects to vga connector with 820 ohm.
	hsync and vsync connected with 120 ohm.

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

		
It still needs more attention to get it fully compatible.
Next up will be timers and more screen modes.
Hopefully some nice high res text modes too.

Jan Rinze.
