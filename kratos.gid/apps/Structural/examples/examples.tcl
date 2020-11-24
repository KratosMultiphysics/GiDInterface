namespace eval Structural::examples {

}

proc Structural::examples::Init { } {
    uplevel #0 [list source [file join $::Structural::dir examples TrussCantilever.tcl]]
    uplevel #0 [list source [file join $::Structural::dir examples HighRiseBuilding.tcl]]
    uplevel #0 [list source [file join $::Structural::dir examples incompressible_cook_membrane.tcl]]
}

proc Structural::examples::UpdateMenus { } {
}

Structural::examples::Init