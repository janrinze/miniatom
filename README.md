# miniatom
Acorn Atom in minimal cofiguration for iCE40 HX8K board

The Acorn Atom is a 1980's home computer. It requires very little resources.
It makes a very good candidate for a minimal implementation on the HX8K.

--- Work in Progress ---

status:

	- VGA 1024x768 vga output for text and mode 4 scaled.
	- CPU runs and the prompt is visible
	- fully functional keyboard.

requirements:

	- IceStorm tools for verilog compilation and HX8K programming
	- Arlet's 6502 in directory ../verilog-6502
	- GNU make
	- ICOboard with 1MB SRAM

Memory map:

	Fxxx   ROM     MM52164    IC20        - onboard MOS

	Exxx   Reserved -Disk Operating System

	Dxxx   ROM     MM52132    IC21

	C000   ROM     MM52164    IC20        - onboard BASIC

	BC00   Empty
	B800   VIA     6522       IC1         - timer ? N.A.
	B400   Extension          PL8
	B000   PPI     INS8255    IC25        - keyboard

	A000   ROM     MN52132    IC24        - mapped as memory

	9xxx   Video RAM                      - onboard
	8xxx   Video RAM                      - onboard

	0000 - 7FFF    RAM                    - onboard

VGA output:

	set_io hsync  C3
	set_io vsync  B3
	set_io blue   A2
	set_io red    B6
	set_io green1 A5
	set_io green2 B7

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
