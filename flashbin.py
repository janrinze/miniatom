#!/usr/bin/env python3

import fileinput

flash_data = list()

def set_flash(addr, value):
    while len(flash_data) <= addr:
        flash_data.append(0)
    flash_data[addr] = value

def set_data(addr, value):
    if 0x8000 <= addr < 0x100000:
        set_flash(addr - 0x8000, value)
    else:
        print("ADDR = %x" % addr)
        assert False

cursor = 0

with open("appimage.hex", "rt") as f:
    for line in f:
        if line.startswith("@"):
            cursor = int(line[1:], 16)
            continue
        for value in line.split():
            set_data(cursor, int(value, 16))
            cursor += 1

with open("appimage.bin", "wb") as f:
    f.write(bytearray(flash_data))

