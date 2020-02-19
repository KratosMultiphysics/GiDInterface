namespace eval MPM::examples {

}

proc MPM::examples::Init { } {
    uplevel #0 [list source [file join $::MPM::dir examples FallingSandBall.tcl]]
}

proc MPM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 7 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Falling sand ball" ] 7 PRE [list ::MPM::examples::FallingSandBall] "" "" insertafter =
    GiDMenu::UpdateMenus
}

MPM::examples::Init