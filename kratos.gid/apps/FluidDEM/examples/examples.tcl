namespace eval FluidDEM::examples {

}

proc FluidDEM::examples::Init { } {
    uplevel #0 [list source [file join $::FluidDEM::dir examples CylinderInFlow.tcl]]
}

proc FluidDEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "FluidDEM CylinderInFlow" ] 8 PRE [list ::FluidDEM::examples::CylinderInFlow] "" "" insertafter =
    GiDMenu::UpdateMenus
}

FluidDEM::examples::Init