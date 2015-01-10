
MEMORY {
  ram(rwx) : ORIGIN = 0x00002000, LENGTH = 0x00FFFFFF
}

SECTIONS {
  .text : { *(.text) } > ram
  .rodata : { *(.rodata) } > ram
  .data : { *(.data) } > ram
  .bss :  { *(.bss)  *(COMMON) } > ram
}
