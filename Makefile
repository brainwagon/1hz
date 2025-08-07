ASM = ./p65

all: 1hz.bin rom.bin
	
1hz.bin: tmp.p65 vcs.h pfdata.h digits.plain.h
	$(ASM) -v tmp.p65 1hz.bin	

tmp.p65: 1hz.m4
	m4 1hz.m4 > tmp.p65

# 
# the EEPROMS that I have are 8K, so I decided just to 
# replicate the same 2K rom 4 times.  Wasteful?  Perhaps.
#

rom.bin: 1hz.bin
	/bin/cat 1hz.bin 1hz.bin 1hz.bin 1hz.bin > rom.bin
