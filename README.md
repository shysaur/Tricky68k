# Tricky68k
####[Download Here!](https://github.com/shysaur/Tricky68k/releases)

Tricky68k is a Motorola 68000 simulator for Mac OS X, based on Volker  
Barthelmann's [VASM](http://sun.hasenbraten.de/vasm/) assembler, the 
[GNU binutils](http://www.gnu.org/software/binutils/) package, Karl Stenerud's 
[Musashi](https://github.com/kstenerud/Musashi) emulator, and Jonathan
Mitchell's [Fragaria](http://www.mugginsoft.com/code/fragaria) editor.

Tricky68k currently runs on Mavericks and higher.

## Notes on building
Since I am using the stock GNU binutils from GNU's anonymous git repository,
when building Tricky68k it's necessary to deal with autotools. 

Because `make` takes a great amount of time even when nothing is to be rebuilt, 
the app's Xcode target does not have `binutils` as a dependency. So, you have 
to build the `binutils` target at least once, before the app's build can
succeed.

##Notes on the simulator
The actual simulation of your code is run in a separate process. So, if your 
fans are spinning mad and `m68ksim` is the culprit, then:
 - If `Tricky68k.app` is closed, it's a bug;
 - If `Tricky68k.app` is open you never ran anything, it's still a bug;
 - If `Tricky68k.app` is open and you are running a program, then it's correct
   behavior, just pause the running executable and `m68ksim` will stop eating
   your CPU.
   
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

