//! Loop Core – Safe abstractions for seL4 (mock mode for host testing)

#![cfg_attr(not(feature = "mock"), no_std)]

pub mod debug;

pub use debug::{serial_write, serial_write_str};