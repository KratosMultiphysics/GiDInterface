namespace eval ConvectionDiffusion::examples {

}

proc ConvectionDiffusion::examples::Init { } {
    uplevel #0 [list source [file join $::ConvectionDiffusion::dir examples HeatedSquare.tcl]]
    #uplevel #0 [list source [file join $::FSI::dir examples HorizontalFlexibleBar.tcl]]
}

proc ConvectionDiffusion::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "Cylinder in air flow" ] 8 PRE [list ::ConvectionDiffusion::examples::HeatedSquare] "" "" insertafter =
    }
    GiDMenu::UpdateMenus
}

ConvectionDiffusion::examples::Init