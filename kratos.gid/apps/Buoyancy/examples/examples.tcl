namespace eval Buoyancy::examples {

}

proc Buoyancy::examples::Init { } {
    uplevel #0 [list source [file join $::Buoyancy::dir examples HeatedSquare.tcl]]
}

proc Buoyancy::examples::UpdateMenus { } {
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
        GiDMenu::InsertOption "Kratos" [list "Heated square" ] 8 PRE [list ::Buoyancy::examples::HeatedSquare] "" "" insertafter =
        GiDMenu::UpdateMenus
    }
}

Buoyancy::examples::Init