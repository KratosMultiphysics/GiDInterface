namespace eval Chimera::examples {

}

proc Chimera::examples::Init { } {
    uplevel #0 [list source [file join $::Chimera::dir examples ChimeraCross.tcl]]
}

proc Chimera::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 7 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Cross section flow" ] 7 PRE [list ::Chimera::examples::ChimeraCross] "" "" insertafter =
    GiDMenu::UpdateMenus
}

Chimera::examples::Init