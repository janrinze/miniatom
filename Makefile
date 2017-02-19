PROJ = miniatom
DEVICE = hx8k
BOARD = icoboard
PIN_DEF = $(PROJ)_$(BOARD).pcf
END_SPEED = 33
SEED = 1587685918

all: $(PROJ).rpt $(PROJ).bin

rom_file.v: roms/genAtomROM.py
	./roms/genAtomROM.py > rom_file.v

%.blif: %.v rom_file.v vga/vga.v 
	yosys -q -p 'synth_ice40 -top top -blif $@' $<

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -s $(SEED) -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin rom_file.v build/*

.SECONDARY:
.PHONY: all prog clean
