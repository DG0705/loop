/// Serial debug output for Loop OS.
/// When feature "mock" is enabled, prints to host terminal via println!.
/// Otherwise writes to x86 I/O port 0x3F8.

#[cfg(feature = "mock")]
pub fn serial_write(c: char) {
    use std::io::{self, Write};
    let mut stdout = io::stdout();
    let _ = stdout.write_all(&[c as u8]);
    let _ = stdout.flush();
}

#[cfg(feature = "mock")]
pub fn serial_write_str(s: &str) {
    for c in s.chars() {
        serial_write(c);
    }
}

#[cfg(not(feature = "mock"))]
pub fn serial_write(c: char) {
    unsafe {
        core::ptr::write_volatile(0x3F8 as *mut u8, c as u8);
    }
}

#[cfg(not(feature = "mock"))]
pub fn serial_write_str(s: &str) {
    for c in s.chars() {
        serial_write(c);
    }
}