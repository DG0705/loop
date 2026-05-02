SECTIONS {
    . = 0x100000;
    .root_task : { *(.root_task) }
    
    . = 0x400000;
    .broker : { *(.broker) }
    
    . = 0x600000;
    .shell : { *(.shell) }
    
    . = 0xA00000;
    .aura : { *(.aura) }
    
    /* other sections */
}