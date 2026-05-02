/* Loop OS Integration Test Linker Script
 * 
 * Minimal linker script for the integration test binary.
 * Places the code at 0x100000 (1MB) which is the standard
 * seL4 root task load address.
 */

ENTRY(_start)

SECTIONS
{
    /* Start of the program */
    . = 0x100000;
    
    /* Code section */
    .text :
    {
        *(.text .text.*)
        *(.rodata .rodata.*)
    }
    
    /* Data section */
    .data :
    {
        *(.data .data.*)
    }
    
    /* BSS section */
    .bss :
    {
        *(.bss .bss.*)
        *(COMMON)
    }
    
    /* Stack section */
    .stack (NOLOAD) :
    {
        . = ALIGN(16);
        *(.stack)
        . = . + 0x1000;  /* 4KB stack */
    }
    
    /* End of program */
    _end = .;
    
    /* Discard unused sections */
    /DISCARD/ :
    {
        *(.eh_frame)
        *(.comment)
    }
}
