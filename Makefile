.PHONY: clean flash

%.sim: tb/%_tb.sv
	iverilog -g2012 -o build/$@ $
	vvp build/$@
	gtkwave build/$*.vcd

top.bit: src/top.sv src/sprite_buf_Ex1.sv
	yosys -p "synth_ecp5 -json build/top.json" $^
	nextpnr-ecp5 --25k --package CABGA256 --speed 6 --json build/top.json --textcfg build/top.cfg --lpf top.lpf --freq 65
	ecppack --svf build/top.svf build/top.cfg build/top.bit

flash: top.bit
	icesprog top.bit

%.bin: src/%.sv
	yosys -p "synth_ice40 -json build/$*.json" $^
	nextpnr-ice40 --up5k --package sg48 --json build/$*.json --pcf $*.pcf --asc build/$*.asc --freq 12
	icepack build/$*.asc build/$@

clean:
	rm -f build/*