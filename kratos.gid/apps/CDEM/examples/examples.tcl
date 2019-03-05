namespace eval CDEM::examples {

}

proc CDEM::examples::Init { } {
    uplevel #0 [list source [file join $::CDEM::dir examples SpheresDrop.tcl]]
}

proc CDEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Spheres drop" ] 8 PRE [list ::CDEM::examples::SpheresDrop] "" "" insertafter =
    GiDMenu::UpdateMenus
}

CDEM::examples::Init