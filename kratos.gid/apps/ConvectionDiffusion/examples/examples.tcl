namespace eval  ConvectionDiffusion::examples {

}

proc  ConvectionDiffusion::examples::Init { } {
    uplevel #0 [list source [file join $:: ConvectionDiffusion::dir examples CylinderHeatFlow.tcl]]
    #uplevel #0 [list source [file join $::FSI::dir examples HorizontalFlexibleBar.tcl]]
}

proc  ConvectionDiffusion::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Cylinder in air flow" ] 8 PRE [list :: ConvectionDiffusion::examples::CylinderHeatFlow] "" "" insertafter =
    #GiDMenu::InsertOption "Kratos" [list "Horizontal flexible bar" ] 8 PRE [list ::FSI::examples::HorizontalFlexibleBar] "" "" insertafter =
    GiDMenu::UpdateMenus
}

 ConvectionDiffusion::examples::Init