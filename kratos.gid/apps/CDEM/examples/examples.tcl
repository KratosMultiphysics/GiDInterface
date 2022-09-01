namespace eval ::CDEM::examples {
    namespace path ::CDEM
    Kratos::AddNamespace [namespace current]

}

proc CDEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Bulk groups" ] 8 PRE [list ::CDEM::xml::BulkGroup] "" "" insertafter =
    GiDMenu::UpdateMenus
}

proc ::CDEM::examples::ErasePreviousIntervals { } {
    set root [customlib::GetBaseRoot]
    set interval_base [spdAux::getRoute "Intervals"]
    foreach int [$root selectNodes "$interval_base/blockdata\[@n='Interval'\]"] {
        if {[$int @name] ni [list Initial Total Custom1]} {$int delete}
    }
}
