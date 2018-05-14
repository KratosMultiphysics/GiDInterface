namespace eval Solid::examples {

}

proc Solid::examples::Init { } {
    uplevel #0 [list source [file join $::Solid::dir examples DynamicRod.tcl]]

}

proc Solid::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] 8 PRE [list ::Solid::examples::DynamicRod] "" "" insertafter =
    GiDMenu::UpdateMenus
}

Solid::examples::Init
