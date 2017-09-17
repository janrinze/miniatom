PROJ = miniatom
DEVICE = hx8k
BOARD = icoboard
PIN_DEF = $(PROJ)_$(BOARD).pcf
END_SPEED = 33

SEED=3156017665

all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v vga/vga.v 
	yosys -p 'synth_ice40  -abc2 -top top -blif $@' $< > YOSYS.LOG

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -s $(SEED) -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^ 

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime -d $(DEVICE) -mtr $@ $<

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
