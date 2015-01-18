# Tricky68k
Tricky68k is a Motorola 68000 simulator for Mac OS X, based on the 
[VASM](http://sun.hasenbraten.de/vasm/) assembler by Volker Barthelmann, the 
[GNU binutils](http://www.gnu.org/software/binutils/), the 
[Musashi](https://github.com/kstenerud/Musashi) emulator by Karl Stenerud, and
the [Fragaria](http://www.mugginsoft.com/code/fragaria) editor by Jonathan
Mitchell.

Tricky68k currently runs on Mavericks and higher.

## Notes on building
Since I am using the stock GNU binutils from GNU's anonymous git repository,
when building it is necessary to deal with autotools. 

Because make takes a great amount of time even when nothing is to be rebuilt, 
the app's Xcode target does not have binutils as a dependency; so, you have to
build binutils at least once before the app's build can succeed.

##Notes on the simulator
The actual simulation of your code is run in a separate process; if your fans
are spinning mad and m68ksim is the culprit, then:
 - If Tricky68k.app is closed, it's a bug;
 - If Tricky68k.app is open you never ran anything, it's still a bug;
 - If Tricky68k.app is open and you are running a program, then it's correct
   behavior, just pause the running executable and the CPU usage will stop.
   
The simulator implements a single I/O device, a teletype, mapped from
0xFFE000 to 0xFFFFFF inclusive. You write a (16 bit) word to that range to 
output a character to the teletype, and you read from the same range to fetch a 
character from the keyboard FIFO. If the keyboard FIFO is empty, -1 will be
read. No interrupts are fired when the FIFO gets data.

