PROJ = miniatom
DEVICE = hx8k
BOARD = icoboard
PIN_DEF = $(PROJ)_$(BOARD)_hdmi.pcf
END_SPEED = 33
FOOTPRINT = ct256

all: $(PROJ).rpt $(PROJ).bin

%.json: %.v
	yosys -p 'synth_ice40 -abc9 -top top -json $@' $< |grep arning
	#yosys -p 'synth_ice40 -abc2 -top main -json $@' $< |grep arning

%.asc: %.json
	#nextpnr-ice40 -r --placer heap --timing-allow-fail --pcf $(PIN_DEF) --json $< --asc $@ --$(DEVICE) --package $(FOOTPRINT) --freq $(END_SPEED)
	nextpnr-ice40 -r --placer heap --timing-allow-fail --pcf $(PIN_DEF) --json $< --asc $@ --$(DEVICE) --package $(FOOTPRINT) 

%.bin: %.asc
	icepack -s $< $@

%.rpt: %.asc
	icetime -c $(END_SPEED) -d $(DEVICE) -P $(FOOTPRINT) -tm $<

rewire:
	rm -f $(PROJ).asc $(PROJ).rpt $(PROJ).bin
	make

prog: $(PROJ).bin
	iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json

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

icoboard: $(PROJ).bin appimage.bin
	icoprog -f < $(PROJ).bin
	icoprog -O 4 -f < appimage.bin
	icoprog -b

.SECONDARY:
.PHONY: all prog clean
