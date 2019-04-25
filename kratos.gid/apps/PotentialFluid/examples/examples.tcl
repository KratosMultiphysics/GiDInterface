namespace eval PotentialFluid::examples {

}

proc PotentialFluid::examples::Init { } {
    uplevel #0 [list source [file join $::PotentialFluid::dir examples NACA0012.tcl]]
}

proc PotentialFluid::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "NACA 0012" ] 8 PRE [list ::PotentialFluid::examples::NACA0012] "" "" insertafter =
    GiDMenu::UpdateMenus
}

PotentialFluid::examples::Init