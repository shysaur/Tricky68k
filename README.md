# Tricky68k
####[Download Here!](https://github.com/shysaur/Tricky68k/releases)

Tricky68k is a Motorola 68000 simulator for Mac OS X, based on Volker  
Barthelmann's [VASM](http://sun.hasenbraten.de/vasm/) assembler, the 
[GNU binutils](http://www.gnu.org/software/binutils/) package, Karl Stenerud's 
[Musashi](https://github.com/kstenerud/Musashi) emulator, and the
[Fragaria](https://github.com/shysaur/Fragaria) editor.

Tricky68k currently runs on Mavericks and higher.

###About the Teletype
The simulator implements a single I/O device (the teletype), mapped from
0xFFE000 to 0xFFFFFF inclusive.
 - You write a (16 bit) word to that range to output a character to the 
   teletype
 - You read from the same range to fetch character from the keyboard FIFO.
If the keyboard FIFO is empty, -1 will be read. No interrupts are fired when
the FIFO gets data, so you need a loop which waits until a character is read:
```
fetchChar:
  move.w $FFE000,d0
  bmi fetchChar         ;Loop while reads a < 0 value
  ;Read something > 0 => got a character
```

