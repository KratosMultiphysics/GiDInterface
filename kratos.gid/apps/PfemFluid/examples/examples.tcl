namespace eval PfemFluid::examples {

}

proc PfemFluid::examples::Init { } {
    uplevel #0 [list source [file join $::PfemFluid::dir examples WaterDamBreak.tcl]]
}

proc PfemFluid::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 7 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Water dam break" ] 7 PRE [list ::PfemFluid::examples::WaterDamBreak] "" "" insertafter =
    GiDMenu::UpdateMenus
}

PfemFluid::examples::Init
