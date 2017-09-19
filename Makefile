PROJ = miniatom
DEVICE = hx8k
BOARD = icoboard
PIN_DEF = $(PROJ)_$(BOARD).pcf
END_SPEED = 33
FOOTPRINT = ct256
SEED=3775152925
# 2416205610 502071218
# -retime -abc2 

all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v vga/vga.v 
	yosys -p 'synth_ice40 -top top -blif $@' $< > YOSYS.LOG

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -r -d $(subst hx,,$(subst lp,,$(DEVICE))) -P $(FOOTPRINT) -o $@ -p $^ 

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -tr $@ $<

rewire:
	rm -f $(PROJ).asc $(PROJ).rpt $(PROJ).bin
	make

prog: $(PROJ).bin
	iceprog $<

icoboard: $(PROJ).bin
	icoprog -f < $<
	icoprog -b

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
