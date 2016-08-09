PROJ = miniatom
DEVICE = hx8k
PIN_DEF = $(PROJ)_$(DEVICE).pcf
END_SPEED = 33

all: $(PROJ).rpt $(PROJ).bin

ram_areas.v: genAtomRAM.py
	./genAtomRAM.py > ram_areas.v

rom_file.v: genAtomROM.py
	./genAtomROM.py > rom_file.v

%.blif: %.v ram_areas.v rom_file.v
	yosys -p 'synth_ice40 -top top -blif $@' $<

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

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
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin ram_areas.v rom_file.v

.SECONDARY:
.PHONY: all prog clean
