namespace eval Dam::examples {

}

proc Dam::examples::Init { } {
    if {$::Model::SpatialDimension eq "2D"} {
        uplevel #0 [list source [file join $::Dam::dir examples ThermoMechaDam2D.tcl]]
    } {
        uplevel #0 [list source [file join $::Dam::dir examples ThermoMechaDam3D.tcl]]
    }
    GiDMenu::InsertOption "Kratos" [list "---"] 6 PRE "" "" "" replace =
    GiDMenu::InsertOption "Kratos" [list "Thermo-Mechanical Dam" ] 7 PRE [list ::Dam::examples::ThermoMechaDam] "" "" replace =
    GiDMenu::UpdateMenus
}

Dam::examples::Init
