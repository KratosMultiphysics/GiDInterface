namespace eval DEM::examples {

}

proc DEM::examples::Init { } {
    uplevel #0 [list source [file join $::DEM::dir examples SpheresDrop.tcl]]
    uplevel #0 [list source [file join $::DEM::dir examples CirclesDrop.tcl]]
}

proc DEM::examples::UpdateMenus { } {

}

DEM::examples::Init