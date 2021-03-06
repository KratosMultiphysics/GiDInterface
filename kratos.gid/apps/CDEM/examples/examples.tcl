namespace eval CDEM::examples {

}

proc CDEM::examples::Init { } {
    uplevel #0 [list source [file join $::CDEM::dir examples ContinuumDrop2D.tcl]]
    uplevel #0 [list source [file join $::CDEM::dir examples ContSpheresDrop3D.tcl]]
}

proc CDEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Bulk groups" ] 8 PRE [list ::CDEM::xml::BulkGroup] "" "" insertafter =
    GiDMenu::UpdateMenus
}

CDEM::examples::Init