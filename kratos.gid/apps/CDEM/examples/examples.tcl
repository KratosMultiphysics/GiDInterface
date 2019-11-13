namespace eval CDEM::examples {

}

proc CDEM::examples::Init { } {
    uplevel #0 [list source [file join $::CDEM::dir examples ContinuumDrop.tcl]]
}

proc CDEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Stone block and sand" ] 8 PRE [list ::CDEM::examples::ContinuumDrop] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Stone block and sand" ] 8 PRE [list ::CDEM::examples::BulkGroup] "" "" insertafter =
    GiDMenu::UpdateMenus
}

CDEM::examples::Init