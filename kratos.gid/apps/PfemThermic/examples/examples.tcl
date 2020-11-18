namespace eval PfemThermic::examples {

}

proc PfemThermic::examples::Init { } {
    uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicSloshing.tcl]]
	uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicConvection.tcl]]
	uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicSloshingConvection.tcl]]
	uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicDamBreakFSI.tcl]]
	uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicCubeDrop.tcl]]
	uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicFluidDrop.tcl]]
}

proc PfemThermic::examples::UpdateMenus { } {
}

PfemThermic::examples::Init
