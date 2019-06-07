namespace eval FSI::examples {

}

proc FSI::examples::Init { } {
    uplevel #0 [list source [file join $::FSI::dir examples MokChannelWithFlexibleWall.tcl]]
    uplevel #0 [list source [file join $::FSI::dir examples TurekBenchmark.tcl]]
    uplevel #0 [list source [file join $::FSI::dir examples HighRiseBuilding.tcl]]
}

proc FSI::examples::UpdateMenus { } {
    set menu_id 7
    GiDMenu::InsertOption "Kratos" [list "Mok - Channel with flexible wall" ] [incr menu_id] PRE [list ::FSI::examples::MokChannelFlexibleWall] "" "" insertbefore =
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "Turek benchmark" ] [incr menu_id] PRE [list ::FSI::examples::TurekBenchmark] "" "" insertbefore =
    }
    GiDMenu::InsertOption "Kratos" [list "High-rise building" ] [incr menu_id] PRE [list ::FSI::examples::HighRiseBuilding] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "---"] [incr menu_id] PRE "" "" "" insertbefore =
    GiDMenu::UpdateMenus
}

FSI::examples::Init