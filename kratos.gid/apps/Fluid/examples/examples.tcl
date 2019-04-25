namespace eval Fluid::examples {

}

proc Fluid::examples::Init { } {
    uplevel #0 [list source [file join $::Fluid::dir examples CylinderInFlow.tcl]]
    uplevel #0 [list source [file join $::Fluid::dir examples HighRiseBuilding.tcl]]
}

proc Fluid::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Cylinder in air flow" ] 8 PRE [list ::Fluid::examples::CylinderInFlow] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "High-rise building" ] 8 PRE [list ::Fluid::examples::HighRiseBuilding] "" "" insertafter =
    GiDMenu::UpdateMenus
}

Fluid::examples::Init