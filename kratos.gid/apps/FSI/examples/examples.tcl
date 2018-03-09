namespace eval FSI::examples {

}

proc FSI::examples::Init { } {
    uplevel #0 [list source [file join $::FSI::dir examples MokChannelWithFlexibleWall.tcl]]
    uplevel #0 [list source [file join $::FSI::dir examples TurekBenchmark.tcl]]
    #uplevel #0 [list source [file join $::FSI::dir examples HorizontalFlexibleBar.tcl]]
    GiDMenu::InsertOption "Kratos" [list "---"] 6 PRE "" "" "" replace =
    GiDMenu::InsertOption "Kratos" [list "Mok - Channel with flexible wall" ] 7 PRE [list ::FSI::examples::MokChannelFlexibleWall] "" "" replace =
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "Turek benchmark - FSI2" ] 8 PRE [list ::FSI::examples::TurekBenchmark] "" "" replace =
    }
    #GiDMenu::InsertOption "Kratos" [list "Horizontal flexible bar" ] 9 PRE [list ::FSI::examples::HorizontalFlexibleBar] "" "" replace =
    GiDMenu::UpdateMenus
}

FSI::examples::Init