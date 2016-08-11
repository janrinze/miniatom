#!/usr/bin/env python3

def permute_data_read(myfile):
    highbyte = []
    lowbyte  = []
    result=0
    # get 64 bytes
    for i in range(0 , 16):
        lowbyte.append(int.from_bytes(myfile.read(1), byteorder='little', signed=False))
        highbyte.append(int.from_bytes(myfile.read(1), byteorder='little', signed=False))
    # interlace the bits because the verilog BRAM works like that when using 8 bit I/O
    for i in range(15,-1,-1):
       bits1 = highbyte[i]
       bits2 = lowbyte[i]
       mask = 128 # top bit
       for j in range(0,8):
           result=result<<1
           if (bits1 & mask) :
              result+=1
           result=result<<1
           if (bits2 & mask) :
              result+=1
           mask = mask >> 1
    # return in string format
    return format(result,'064x')

def permute_data(highbyte,lowbyte,index):
    # interlace the bits because the verilog BRAM works like that when using 8 bit I/O
    result=0
    for i in range(15,-1,-1):
       bits1 = highbyte[i+index*16]
       bits2 = lowbyte[i+index*16]
       mask = 128 # top bit
       for j in range(0,8):
           result=result<<1
           if (bits1 & mask) :
              result+=1
           result=result<<1
           if (bits2 & mask) :
              result+=1
           mask = mask >> 1
    # return in string format
    return format(result,'064x')

def write_ram_512byte( myfile,outfile, address , rom_name):

    rom_block_name = format(address,'04x')
    
    # setup verilog boilerplate
    outfile.write("reg [7:0] D_IN_%s;\n"%(rom_block_name))
    outfile.write("SB_RAM512x8 %s_%s (\n" %(rom_name,rom_block_name) )
    outfile.write("     .RDATA (D_IN_%s),\n"%(rom_block_name))
    outfile.write("     .RCLK(clk),\n")
    outfile.write("     .RCLKE(1'b1),\n")
    outfile.write("     .RADDR(cpu_address[8:0]),\n")
    outfile.write("     .RE(1'b1)\n")
    outfile.write("     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA\n")
    outfile.write(");\n")
    highbyte = []
    lowbyte  = []
    # get 512 bytes
    for i in range(0 , 256):
        lowbyte.append(int.from_bytes(myfile.read(1), byteorder='little', signed=False))
    for i in range(0 , 256):
        highbyte.append(int.from_bytes(myfile.read(1), byteorder='little', signed=False))
    for index in range(0,16):
        outfile.write('  defparam %s_%s.INIT_%s = 256\'h%s ;\n' %(rom_name, rom_block_name, format(index,'01X'), permute_data(highbyte,lowbyte,index) ))


def write_ROM(romname,file_name,base_address,rom_size):
    myfile=open(file_name,'rb')
    outfile=open(romname+".v",'w')
    outfile.write("/*\n")
    outfile.write("      Auto generated ROM file for Acorn Atom \n")
    outfile.write("     %-9s %-16s     Address Size\n" %("ROM","FileName"))
    outfile.write("     %-9s %-16s     %04X     %d \n" %(romname,file_name,base_address,rom_size))
    outfile.write("*/\n")
    outfile.write(" \n")
    mydecode = ""
    for address in range(base_address,base_address+rom_size,512):
        write_ram_512byte( myfile,outfile, address , romname)
        mydecode = " (latched_cpu_addr[15:9] == 7'h" + format((address >> 9),'02x') + ") ? D_IN_" + format(address,'04x') + " : " + mydecode
    outfile.write("wire [7:0] %s_out; \n" %(romname))
    outfile.write(" assign %s_out = %s 0;\n" %(romname,mydecode))

def write_ROMs(romlist):

    for romname,filename,address,rom_size in romlist:
        print("     %-9s %-16s     %04X     %d " %(romname,filename,address,rom_size))
    
    print("// wire [7:0] ROM_read;")
    mydecode = ""
    for romname,filename,address,rom_size in romlist:
        write_ROM(romname,filename,address,rom_size)
        # we will assume that roms are always 4KB
        mydecode = " (latched_cpu_addr[15:12] == 4'h" + format((address >> 12),'01x') + ") ? " + romname +"_out : " + mydecode
    print("// always ROM_read = %s 0; " %(mydecode))

    
def to_bin(value):
	result='';
	for i in range(0,8):
		nextc='0'
		if (value&1):
			nextc='1'
		result=nextc+result;
		value=value>>1
	return result+'\n'

def dump_to_list(romname,file_name,base_address,rom_size):
	myfile=open(file_name,'rb')
	asbytes=[]
	for address in range(0,rom_size):
		asbytes.append(int.from_bytes(myfile.read(1), byteorder='little', signed=False))
	postfix=['A','B','C','D']
	pfindex=0;
	for offset in range(0,4096,1024):
		outfile=open(romname+postfix[pfindex]+".list",'w')
		pfindex=pfindex+1
		for address in range(0,1024):
			outfile.write(to_bin(asbytes[offset+address]))
		outfile.close()
	myfile.close()

def write_lists(romlist):
	for romname,file_name,base_address,rom_size in romlist:
		dump_to_list(romname,file_name,base_address,rom_size)

write_lists([('MOS_ROM',"Atom_Kernel.rom",0xf000,4096),('BASIC_ROM',"Atom_Basic.rom",0xc000,4096)])
write_ROMs([('MOS_ROM',"Atom_Kernel.rom",0xf000,4096),('BASIC_ROM',"Atom_Basic.rom",0xc000,4096)])
