namespace eval DEM::examples {

}

proc DEM::examples::Init { } {
    uplevel #0 [list source [file join $::DEM::dir examples SpheresDrop.tcl]]
}

proc DEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Spheres drop" ] 8 PRE [list ::DEM::examples::SpheresDrop] "" "" insertafter =
    GiDMenu::UpdateMenus
}

DEM::examples::Init