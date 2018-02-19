namespace eval DEM::examples {

}

proc DEM::examples::Init { } {
    uplevel #0 [list source [file join $::DEM::dir examples SpheresDrop.tcl]]
    GiDMenu::InsertOption "Kratos" [list "---"] 6 PRE "" "" "" replace =
    GiDMenu::InsertOption "Kratos" [list "Spheres drop" ] 7 PRE [list ::DEM::examples::SpheresDrop] "" "" replace =
    GiDMenu::UpdateMenus
}

DEM::examples::Init