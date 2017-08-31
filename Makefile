PROJ = miniatom
DEVICE = hx8k
BOARD = icoboard
PIN_DEF = $(PROJ)_$(BOARD).pcf
END_SPEED = 33
#SEED = 1587685918
#SEED=4246941055
SEED=1660300435

all: $(PROJ).rpt $(PROJ).bin

%.blif: %.v 
	yosys -q -p 'synth_ice40 -top top -abc2 -blif $@' $<

%.asc: $(PIN_DEF) %.blif
	arachne-pnr -r -d $(subst hx,,$(subst lp,,$(DEVICE))) -o $@ -p $^

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
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin

.SECONDARY:
.PHONY: all prog clean
