# miniatom
Acorn Atom in minimal cofiguration for iCE40 HX8K board

The Acorn Atom is a 1980's home computer. It requires very little resources.
It makes a very good candidate for a minimal implementation on the HX8K.

--- Work in Progress ---
status:
	- VGA is booting and generates proper sync pulses for 1024x768 vga output
	- CPU seems to be running. 
	- no keyboard row activity seen yet.

requirements:

	- IceStorm tools for verilog compilation and HX8K programming
	- Arlet's 6502 in directory ../verilog-6502
	- GNU make
	- Lattice iCE-HX8K breakout board

Memory map:

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

It requires the verilog 6502 CPU and has the following I/O:

Generic:

		set_io LED0 B5
		set_io LED1 B4
		set_io LED2 A2
		set_io LED3 A1
		set_io LED4 C5
		set_io LED5 C4
		set_io LED6 B3
		set_io LED7 C3
		set_io pclk J3
		set_io reset A16

VGA-out:

		set_io hsync C16
		set_io vsync B16
		set_io blue D16
		set_io red D14
		set_io green1 E16
		set_io green2 D15

KeyBoard:

		set_io shift_key F16
		set_io ctrl_key E14
		set_io key_col5 G16
		set_io key_col4 F15
		set_io key_col3 H16
		set_io key_col2 G15
		set_io key_col1 J15
		set_io key_col0 H14
		set_io rept_key G14
		set_io key_row3 K14
		set_io key_row2 J14
		set_io key_row1 K15
		set_io key_row0 K16
		
It still needs more attention to get it fully working.

Jan Rinze.
