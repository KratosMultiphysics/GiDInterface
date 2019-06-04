namespace eval Structural::examples {

}

proc Structural::examples::Init { } {
    uplevel #0 [list source [file join $::Structural::dir examples TrussCantilever.tcl]]
    uplevel #0 [list source [file join $::Structural::dir examples HighRiseBuilding.tcl]]
}

proc Structural::examples::UpdateMenus { } {
    set menu_id 7
    GiDMenu::InsertOption "Kratos" [list "Truss cantilever" ] [incr menu_id] PRE [list ::Structural::examples::TrussCantilever] "" "" insertbefore =
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "High-rise building" ] [incr menu_id] PRE [list ::Structural::examples::HighRiseBuilding] "" "" insertbefore =
    }
    GiDMenu::InsertOption "Kratos" [list "---"] [incr menu_id] PRE "" "" "" insertbefore =
    GiDMenu::UpdateMenus
}

Structural::examples::Init