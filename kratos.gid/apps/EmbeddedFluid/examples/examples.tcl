namespace eval EmbeddedFluid::examples {
    variable CylinderInFlow_Data
}

proc EmbeddedFluid::examples::Init { } {
    uplevel #0 [list source [file join $::EmbeddedFluid::dir examples CylinderInFlow.tcl]]
    #uplevel #0 [list source [file join $::FSI::dir examples HorizontalFlexibleBar.tcl]]
    GiDMenu::InsertOption "Kratos" [list "---"] 6 PRE "" "" "" replace =
    GiDMenu::InsertOption "Kratos" [list "Cylinder in air flow" ] 7 PRE [list ::EmbeddedFluid::examples::CylinderInFlow] "" "" replace =
    #GiDMenu::InsertOption "Kratos" [list "Horizontal flexible bar" ] 8 PRE [list ::FSI::examples::HorizontalFlexibleBar] "" "" replace =
    GiDMenu::UpdateMenus
}

EmbeddedFluid::examples::Init