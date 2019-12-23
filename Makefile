SHELL=/bin/bash
PROJ = AcornAtom
DEVICE = up5k
FOOTPRINT = sg48
#BOARD = upduino2
#BOARD = 5kevb


DEVICE = hx8k
BOARD = miniatom_hx8k_sram
FOOTPRINT = ct256

PIN_DEF = $(BOARD).pcf
END_SPEED = 44



SEED = $(shell /bin/bash -c "echo $$RANDOM")
#SEED =  7354

SEED =  30659

all: $(PROJ).json $(PROJ).asc $(PROJ).bin

%.json: rtl/atom.v
	yosys -p 'synth_ice40  -top top -json $@' $< |grep arning

%.asc: %.json
	nextpnr-ice40 --seed $(SEED) --placer heap --pcf $(PIN_DEF) --json $< --asc $@ --$(DEVICE) --package $(FOOTPRINT) --freq $(END_SPEED)
	#nextpnr-ice40 --seed $(SEED) --placer heap  --opt-timing --timing-allow-fail --pcf $(PIN_DEF) --json $< --asc $@ --$(DEVICE) --package $(FOOTPRINT) --freq $(END_SPEED)
	echo "SEED = " $(SEED)
	icetime -d $(DEVICE) -P $(FOOTPRINT) -tm $@

%.bin: %.asc
	icepack -s $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -P $(FOOTPRINT) -tm $<

rewire:
	rm -f $(PROJ).asc $(PROJ).rpt $(PROJ).bin
	make

prog: $(PROJ).bin
	iceprog $<
	iceprog -o 256k appimage.bin

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json

.SECONDARY:
.PHONY: all prog clean
