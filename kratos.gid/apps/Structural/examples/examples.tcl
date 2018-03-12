namespace eval Structural::examples {

}

proc Structural::examples::Init { } {
    uplevel #0 [list source [file join $::Structural::dir examples TrussCantilever.tcl]]
}

proc Structural::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Truss cantilever" ] 8 PRE [list ::Structural::examples::TrussCantilever] "" "" insertafter =
    GiDMenu::UpdateMenus
}

Structural::examples::Init