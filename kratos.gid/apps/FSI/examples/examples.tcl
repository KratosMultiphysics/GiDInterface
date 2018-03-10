namespace eval FSI::examples {

}

proc FSI::examples::Init { } {
    uplevel #0 [list source [file join $::FSI::dir examples MokChannelWithFlexibleWall.tcl]]
    uplevel #0 [list source [file join $::FSI::dir examples TurekBenchmark.tcl]]
}

proc FSI::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Mok - Channel with flexible wall" ] 8 PRE [list ::FSI::examples::MokChannelFlexibleWall] "" "" insertafter =
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "Turek benchmark" ] 9 PRE [list ::FSI::examples::TurekBenchmark] "" "" insertafter =
    }
    GiDMenu::UpdateMenus
}

FSI::examples::Init