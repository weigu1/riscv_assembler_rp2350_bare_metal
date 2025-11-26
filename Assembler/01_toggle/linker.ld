/* Minimal linker script example */
OUTPUT_ARCH(riscv) /* Adjust for your architecture */
ENTRY(_start)      /* Entry point symbol */

MEMORY {
    FLASH (rx)  : ORIGIN = 0x10000000, LENGTH = 2M   /* FLASH read only */
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 256K /* SRAM read/write */
}

SECTIONS {
    .text : ALIGN(4) {       /* All .text sections */
        *(.text*)
    } > FLASH                /* in FLASH */

    .data : ALIGN(4) {       /* All .data sections */
        *(.data*)
    } > RAM                  /* in RAM */

    .bss : ALIGN(4) {        /* All .bss sections */
        *(.bss*)
    } > RAM                  /* in RAM */

    .stack (NOLOAD) : {      /* Stack */
        . = ALIGN(8);
        _stack_top = . + 4K; /* Reserve 4KB for stack */
    } > RAM                  /* in RAM */
}
