namespace eval FluidDEM::examples {

}

proc FluidDEM::examples::Init { } {
    uplevel #0 [list source [file join $::FluidDEM::dir examples CylinderInFlow.tcl]]
}

proc FluidDEM::examples::UpdateMenus { } {
}

FluidDEM::examples::Init