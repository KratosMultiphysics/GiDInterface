namespace eval PfemThermic::examples {

}

proc PfemThermic::examples::Init { } {
    uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicSloshing.tcl]]
	uplevel #0 [list source [file join $::PfemThermic::dir examples ThermicConvection.tcl]]
}

proc PfemThermic::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 7 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Thermic sloshing" ]   7 PRE [list ::PfemThermic::examples::ThermicSloshing]   "" "" insertafter =
	GiDMenu::InsertOption "Kratos" [list "Thermic convection" ] 7 PRE [list ::PfemThermic::examples::ThermicConvection] "" "" insertafter =
    GiDMenu::UpdateMenus
}

PfemThermic::examples::Init
