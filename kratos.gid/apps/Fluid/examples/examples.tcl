namespace eval Fluid::examples {

}

proc Fluid::examples::Init { } {
    uplevel #0 [list source [file join $::Fluid::dir examples CylinderInFlow.tcl]]
    uplevel #0 [list source [file join $::Fluid::dir examples HighRiseBuilding.tcl]]
}

proc Fluid::examples::UpdateMenus { } {
}

Fluid::examples::Init