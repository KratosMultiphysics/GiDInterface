namespace eval Solid::examples {

}

proc Solid::examples::Init { } {
    uplevel #0 [list source [file join $::Solid::dir examples DynamicRod.tcl]]
    uplevel #0 [list source [file join $::Solid::dir examples CircularTank.tcl]]

}

proc Solid::examples::UpdateMenus3D { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] 8 PRE [list ::Solid::examples::DynamicRod] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "CircularTank" ] 9 PRE [list ::Solid::examples::CircularTank] "" "" insertafter =
    GiDMenu::UpdateMenus
}

proc Solid::examples::UpdateMenus2D { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] 8 PRE [list ::Solid::examples::DynamicRod] "" "" insertafter =
    GiDMenu::UpdateMenus
}

proc Solid::examples::UpdateMenus2Da { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "CircularTank" ] 8 PRE [list ::Solid::examples::CircularTank] "" "" insertafter =
    GiDMenu::UpdateMenus
}


Solid::examples::Init
