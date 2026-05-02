fn main() {
    loop_core::serial_write_str("Hello from Loop OS!\n");
    loop_core::serial_write_str("If you see this, the mock core works.\n");
}