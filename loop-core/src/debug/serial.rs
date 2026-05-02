//! Serial port debugging utilities for Loop OS
//! 
//! This module provides functions for writing debug output to the serial port
//! on x86_64 systems. It's used by compartments to output debug messages
//! during the integration smoke test and regular operation.

/// Write a string to the serial port (COM1 on x86_64)
/// 
/// This function writes the given string to the COM1 serial port at I/O port 0x3F8.
/// It's used by compartments for debug output during testing and normal operation.
/// 
/// # Arguments
/// 
/// * `s` - The string to write to the serial port
/// 
/// # Safety
/// 
/// This function uses unsafe inline assembly to access I/O ports.
/// It's safe to call in the context of Loop OS compartments.
pub fn serial_write_str(s: &str) {
    const COM1: u16 = 0x3F8;
    
    for byte in s.bytes() {
        // Wait for transmitter to be ready
        while !is_transmit_ready() {}
        
        // Send the byte
        unsafe {
            core::arch::asm!(
                "out dx, al",
                in("dx") COM1,
                in("al") byte,
                options(nostack, preserves_flags)
            );
        }
    }
}

/// Write a single character to the serial port
/// 
/// This is a helper function for writing individual characters.
/// 
/// # Arguments
/// 
/// * `c` - The character to write
pub fn serial_write_char(c: char) {
    const COM1: u16 = 0x3F8;
    
    // Wait for transmitter to be ready
    while !is_transmit_ready() {}
    
    // Send the character
    unsafe {
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1,
            in("al") c as u8,
            options(nostack, preserves_flags)
        );
    }
}

/// Check if the serial transmitter is ready
/// 
/// Returns true if the transmitter holding register is empty and ready
/// to accept new data.
/// 
/// # Returns
/// 
/// `true` if ready to transmit, `false` otherwise
fn is_transmit_ready() -> bool {
    const COM1: u16 = 0x3F8;
    let mut status: u8;
    
    unsafe {
        core::arch::asm!(
            "in al, dx",
            out("al") status,
            in("dx") COM1 + 5,  // Line Status Register
            options(nostack, preserves_flags)
        );
    }
    
    // Check if transmitter holding register is empty (bit 5)
    (status & 0x20) != 0
}

/// Initialize the serial port for debugging
/// 
/// This function initializes COM1 with standard settings:
/// - 38400 baud rate
/// - 8 data bits
/// - No parity
/// - 1 stop bit
/// - FIFO enabled
pub fn init_serial() {
    const COM1: u16 = 0x3F8;
    
    // Disable interrupts
    unsafe {
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 1,
            in("al") 0x00u8,
            options(nostack, preserves_flags)
        );
        
        // Enable DLAB (set baud rate divisor)
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 3,
            in("al") 0x80u8,
            options(nostack, preserves_flags)
        );
        
        // Set divisor to 3 (lo byte) for 38400 baud
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 0,
            in("al") 0x03u8,
            options(nostack, preserves_flags)
        );
        
        // Set divisor to 0 (hi byte)
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 1,
            in("al") 0x00u8,
            options(nostack, preserves_flags)
        );
        
        // 8 bits, no parity, one stop bit
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 3,
            in("al") 0x03u8,
            options(nostack, preserves_flags)
        );
        
        // Enable FIFO, clear them, with 14-byte threshold
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 2,
            in("al") 0xC7u8,
            options(nostack, preserves_flags)
        );
        
        // IRQs enabled, RTS/DSR set
        core::arch::asm!(
            "out dx, al",
            in("dx") COM1 + 4,
            in("al") 0x0Bu8,
            options(nostack, preserves_flags)
        );
    }
}

/// Write a formatted string to the serial port
/// 
/// This function provides a simple formatting capability for debug output.
/// It supports basic format specifiers like %s, %d, %x.
/// 
/// # Arguments
/// 
/// * `format` - The format string
/// * `args` - Format arguments (simplified)
pub fn serial_printf(format: &str, args: &[&str]) {
    let mut chars = format.chars().peekable();
    
    while let Some(ch) = chars.next() {
        if ch == '%' {
            if let Some(next_ch) = chars.next() {
                match next_ch {
                    's' => {
                        if let Some(arg) = args.first() {
                            serial_write_str(arg);
                        }
                    }
                    'd' => {
                        if let Some(arg) = args.first() {
                            // Simple integer formatting (simplified)
                            serial_write_str(arg);
                        }
                    }
                    'x' => {
                        if let Some(arg) = args.first() {
                            serial_write_str(arg);
                        }
                    }
                    '%' => {
                        serial_write_char('%');
                    }
                    _ => {
                        serial_write_char('%');
                        serial_write_char(next_ch);
                    }
                }
            }
        } else {
            serial_write_char(ch);
        }
    }
}