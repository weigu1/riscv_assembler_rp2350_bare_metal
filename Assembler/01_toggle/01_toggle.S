### Toggle a GPIO pin (minimal version)
### 01_toggle.S
### weigu.lu

        ### RP2350 Image Definition Block
        # This block is required for the RP2350 to recognize the binary as a valid
        # RISC-V executable. It must appear within the first 4 KB of the image.
        # RP2350 data sheet: 5.9.1. Blocks and block loops
        # 5.9.3. Image definition items, 5.9.3.4. ENTRY_POINT item
        .p2align 8       # Align to 8-byte boundary (required for RP2350 image header)
        .word 0xffffded3 # Header magic number (identifies the image)
        .word 0x11010142 # Item 0 flags: 0b0001 0001 0000 0001 0000 0100 0010
                         # IMAGE_TYPE_EXE, EXE_SECURITY_UNSPECIFIED,
                         # EXE_CPU_RISC,  EXE_CHIP_RP2350
        .word 0x00000344 # Item 1: Block size = 3,
                         # Block type = PICOBIN_BLOCK_ITEM_1BS_ENTRY_POINT
        .word _start     # Item 2: Inital PC (runtime) address (aka entry point)
        .word _stack_top # Item 3: Initial SP address (aka stack pointer)
        .word 0x000004ff # Item 4: Optional SP limit address (aka stack limit)
        .word 0x00000000 # Link: Single block loop has 0 items
        .word 0xab123579 # Footer magic number

         ### Global vars
        .equ PIN_OUT, 15                    # Pin to use
        .equ DELAY_NUMBER,    1000000       # 1000000 gives us ~ 2 Hz (12MHz clock)

        ### Masks and Offsets
        .equ GPIO_OFFSET,     PIN_OUT*8+4   # Offset for GPIO reg. (0=Status, +4=Ctrl)
        .equ PADS_OFFSET,     PIN_OUT*4+4   # Offset for PAD reg. (GPIO0 starts w. +4)
        .equ ATOMIC_CLR,      0x3000        # atomic offset bitmask AND on write
        .equ PAD_MASK_ISO_BIT,0x100         # Bit 8 = Pad Isolation control

        ### Memory-Mapped Register Definitions
        .equ IO_BANK0_BASE,   0x40028000    # IO Bank0 Base Address
        .equ SIO_BASE,        0xD0000000    # SIO (Single-Cycle I/O) Base Address
        .equ PADS_BANK0_BASE, 0x40038000    # User Bank Pad Control register base
        .equ GPIO_CTRL,       IO_BANK0_BASE + GPIO_OFFSET # GPIO_CTRL reg. (for Mux)
        .equ GPIO_OUT_XOR,    SIO_BASE + 0x28 # GPIO output XOR register (atomic)
        .equ GPIO_OE_SET,     SIO_BASE + 0x38 # GPIO output enable reg. (atomic set)
        .equ PAD_CLR,         PADS_BANK0_BASE + PADS_OFFSET + ATOMIC_CLR

        .section .text              # Marks the start of the code section in memory
        .align 1                    # 2 byte for modul C
        .global _start              # Makes the symbol '_start' visible to the linker

### Entry Point: _start
_start:         la sp, _stack_top   # Load the stack pointer with the top of the stack
                call main           # Call the main function
                wfi                 # Wait for interrupt (save power if CPU idle)
                j _start            # safeguard if main returns (should never happen)

### Main Function
        .section .text              # Code section
        .align 1                    # 2 byte for modul C
        .global main                # Make 'main' visible to the linker
main:
setup:          # SETUP: Tell the multiplexer to set our Pin to GPIO
                li t0, GPIO_CTRL    # Load the address of the GPIO_CTRL reg. to t0
                lw t1, 0(t0)        # Load current value of the GPIO_CTRL reg. to t1
                andi t1, t1, ~0x1F  # Clear the lower 5 bits (function select)
                ori t1, t1, 5       # Set the function select to 5 (GPIO mode)
                sw t1, 0(t0)        # Store updated value back to the GPIO_CTRL reg.

                ### SETUP: Set GPIO as an output
                li t0, GPIO_OE_SET  # Load address of atomic GPIO out enable set reg.
                li t1, 1 << PIN_OUT # Load the bitmask for the used GPIO
                sw t1, 0(t0)        # Store updated value back to the register

                ### Setup: Clear Pad Isolation for GPIO
                li t0, PAD_CLR      # Load the address of the pad register
                li t1, PAD_MASK_ISO_BIT # Load the bitmask for the used GPIO
                sw t1, 0(t0)        # Store updated value back to the register

                li t0, GPIO_OUT_XOR # Load the address of the GPIO_OUT_XOR
                li t1, 1 << PIN_OUT # Load the bit for the output GPIO to be toggled

mainloop:       # Main Loop: Toggle output on GPIOx
                sw t1, 0(t0)        # Set the bit (atomic bit setting-writing)
                #li a0, DELAY_NUMBER # set counter for delay loop (parameter a0)
                #jal delay          # jump and link delay (command call for big jumps)
                j mainloop          # jump mainloop forever

delay:          # Subroutine delay (parameter a0)
                addi a0, a0, -1     # decrement a0
                bnez a0, delay      # stay in loop until counter = 0
                ret
