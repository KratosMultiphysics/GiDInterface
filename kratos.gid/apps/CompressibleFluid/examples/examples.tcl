namespace eval CompressibleFluid::examples {

}

proc CompressibleFluid::examples::Init { } {
    uplevel #0 [list source [file join $::CompressibleFluid::dir examples CylinderInFlow.tcl]]
    uplevel #0 [list source [file join $::CompressibleFluid::dir examples HighRiseBuilding.tcl]]
}

proc CompressibleFluid::examples::UpdateMenus { } {
}

CompressibleFluid::examples::Init