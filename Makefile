PROJ = miniatom
DEVICE = hx8k
BOARD = icoboard
PIN_DEF = $(PROJ)_$(BOARD).pcf
END_SPEED = 33
FOOTPRINT = ct256
SEED=3775152925
# 2416205610 502071218 3488400551 (36.66MHz)
# -retime -abc2 1031308875

all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v vga/vga.v 
	yosys -p 'synth_ice40 -top top -blif $@' $< > YOSYS.LOG
	grep arning YOSYS.LOG

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -s 1086239526 -d $(subst hx,,$(subst lp,,$(DEVICE))) -P $(FOOTPRINT) -o $@ -p $^ > ARACHNE.LOG
	cat ARACHNE.LOG

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -tr $@ $<

rewire:
	rm -f $(PROJ).asc $(PROJ).rpt $(PROJ).bin
	make

appimage.bin:
	echo "@8000" > appimage.hex
	cat splashscreen.hex >> appimage.hex
	echo "@a000" >> appimage.hex
	cat roms/pcharme.hex >> appimage.hex
	echo "@c000" >> appimage.hex
	cat roms/basic.hex >> appimage.hex
	echo "@d000" >> appimage.hex
	cat roms/floatingpoint.hex >> appimage.hex
	echo "@e000" >> appimage.hex
	cat roms/sddos.hex >> appimage.hex
	echo "@f000" >> appimage.hex
	cat roms/akernel_patched.hex >> appimage.hex
	./flashbin.py

prog: $(PROJ).bin 
	iceprog $<

icoboard: $(PROJ).bin appimage.bin
	icoprog -f < $(PROJ).bin
	icoprog -O 4 -f < appimage.bin
	icoprog -b

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin appimage.bin

.SECONDARY:
.PHONY: all prog clean
