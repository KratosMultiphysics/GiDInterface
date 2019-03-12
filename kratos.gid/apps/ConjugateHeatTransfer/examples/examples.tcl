namespace eval ConjugateHeatTransfer::examples {

}

proc ConjugateHeatTransfer::examples::Init { } {
    uplevel #0 [list source [file join $::ConjugateHeatTransfer::dir examples HeatedSquare.tcl]]
    uplevel #0 [list source [file join $::ConjugateHeatTransfer::dir examples cylinder_cooling.tcl]]
    uplevel #0 [list source [file join $::ConjugateHeatTransfer::dir examples BFS.tcl]]
}

proc ConjugateHeatTransfer::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Heated square" ] 8 PRE [list ::ConjugateHeatTransfer::examples::HeatedSquare] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Cylinder cooling" ] 8 PRE [list ::ConjugateHeatTransfer::examples::CylinderCooling] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "BFS" ] 8 PRE [list ::ConjugateHeatTransfer::examples::BFS] "" "" insertafter =
    GiDMenu::UpdateMenus
}

ConjugateHeatTransfer::examples::Init