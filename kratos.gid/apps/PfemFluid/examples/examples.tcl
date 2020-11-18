namespace eval PfemFluid::examples {

}

proc PfemFluid::examples::Init { } {
    uplevel #0 [list source [file join $::PfemFluid::dir examples WaterDamBreak.tcl]]
    uplevel #0 [list source [file join $::PfemFluid::dir examples DamBreakFSI.tcl]]
}

proc PfemFluid::examples::UpdateMenus { } {
}

PfemFluid::examples::Init
