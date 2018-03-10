namespace eval EmbeddedFluid::examples {
    variable CylinderInFlow_Data
}

proc EmbeddedFluid::examples::Init { } {
    uplevel #0 [list source [file join $::EmbeddedFluid::dir examples CylinderInFlow.tcl]]
}

proc EmbeddedFluid::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Embedded cylinder test" ] 8 PRE [list ::EmbeddedFluid::examples::CylinderInFlow] "" "" insertafter =
    GiDMenu::UpdateMenus
}

EmbeddedFluid::examples::Init