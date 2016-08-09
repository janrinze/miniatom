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


def write_ram_512byte( myfile, address , rom_name):

    rom_block_name = format(address,'04x')
    
    # setup verilog boilerplate
    print("reg [7:0] D_IN_%s;"%(rom_block_name))
    print("SB_RAM512x8 %s_%s (" %(rom_name,rom_block_name) )
    print("     .RDATA (D_IN_%s),"%(rom_block_name))
    print("     .RCLK(clk),")
    print("     .RCLKE(1'b1),")
    print("     .RADDR(cpu_address[8:0]),")
    print("     .RE(1'b1)")
    print("     //.WCLK, .WCLKE, .WE,.WADDR,.MASK,.WDATA")
    print(");")
    for index in range(0,16):
        print('  defparam %s_%s.INIT_%s = 256\'h%s ;' %(rom_name, rom_block_name, format(index,'01X'), permute_data_read(myfile) ))


def write_ROM(romname,file_name,base_address,rom_size):
    myfile=open(file_name,'rb')
    mydecode = ""
    for address in range(base_address,base_address+rom_size,512):
        write_ram_512byte( myfile, address , romname)
        mydecode = " (cpu_address[15:9] == 7'h" + format((address >> 9),'02x') + ") ? D_IN_" + format(address,'04x') + " : " + mydecode
    print("wire [7:0] %s_out; " %(romname))
    print(" assign %s_out = %s 0;" %(romname,mydecode))

def write_ROMs(romlist):
    print("/*")
    print("      Auto generated ROM file for Acorn Atom ")
    print(" ")
    print("     %-9s %-16s     Address Size" %("ROM","FileName"))
    for romname,filename,address,rom_size in romlist:
        print("     %-9s %-16s     %04X     %d " %(romname,filename,address,rom_size))
    print("*/")
    print("// wire [7:0] ROM_read;")
    mydecode = ""
    for romname,filename,address,rom_size in romlist:
        write_ROM(romname,filename,address,rom_size)
        # we will assume that roms are always 4KB
        mydecode = " (cpu_address[15:12] == 4'h" + format((address >> 12),'01x') + ") ? " + romname +"_out : " + mydecode
    print("// always ROM_read = %s 0; " %(mydecode))

write_ROMs([('MOS_ROM',"Atom_Kernel.rom",0xf000,4096),('BASIC_ROM',"Atom_Basic.rom",0xc000,4096)])
    
