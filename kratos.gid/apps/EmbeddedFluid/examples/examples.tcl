namespace eval EmbeddedFluid::examples {
    variable CylinderInFlow_Data
}

proc EmbeddedFluid::examples::Init { } {
    uplevel #0 [list source [file join $::EmbeddedFluid::dir examples CylinderInFlow.tcl]]
}

proc EmbeddedFluid::examples::UpdateMenus { } {
}

EmbeddedFluid::examples::Init