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
    GiDMenu::InsertOption "Kratos" [list "---"] 7 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Thermic sloshing" ]            7 PRE [list ::PfemThermic::examples::ThermicSloshing]           "" "" insertafter =
	GiDMenu::InsertOption "Kratos" [list "Thermic convection" ]          7 PRE [list ::PfemThermic::examples::ThermicConvection]         "" "" insertafter =
	GiDMenu::InsertOption "Kratos" [list "Thermic sloshing convection" ] 7 PRE [list ::PfemThermic::examples::ThermicSloshingConvection] "" "" insertafter =
	GiDMenu::InsertOption "Kratos" [list "Thermic dam break FSI" ]       7 PRE [list ::PfemThermic::examples::ThermicDamBreakFSI]        "" "" insertafter =
	GiDMenu::InsertOption "Kratos" [list "Thermic cube drop" ]           7 PRE [list ::PfemThermic::examples::ThermicCubeDrop]           "" "" insertafter =
	GiDMenu::InsertOption "Kratos" [list "Thermic fluid drop" ]          7 PRE [list ::PfemThermic::examples::ThermicFluidDrop]          "" "" insertafter =
    GiDMenu::UpdateMenus
}

PfemThermic::examples::Init
