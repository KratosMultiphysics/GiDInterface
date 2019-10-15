namespace eval Solid::examples {

}

proc Solid::examples::Init { } {
    uplevel #0 [list source [file join $::Solid::dir examples DynamicBeam.tcl]]
    uplevel #0 [list source [file join $::Solid::dir examples CircularTank.tcl]]
    uplevel #0 [list source [file join $::Solid::dir examples EccentricColumn.tcl]]
    uplevel #0 [list source [file join $::Solid::dir examples DynamicRod.tcl]]
    uplevel #0 [list source [file join $::Solid::dir examples NotchedBeam.tcl]]
    uplevel #0 [list source [file join $::Solid::dir examples StaticBeamLattice.tcl]]
}

proc Solid::examples::UpdateMenus3D { } {
    set menu_id 7
    GiDMenu::InsertOption "Kratos" [list "DynamicBeam" ] [incr menu_id] PRE [list ::Solid::examples::DynamicBeam] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "CircularTank" ] [incr menu_id] PRE [list ::Solid::examples::CircularTank] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "EccentricColumn" ] [incr menu_id] PRE [list ::Solid::examples::EccentricColumn] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] [incr menu_id] PRE [list ::Solid::examples::DynamicRod] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "StaticBeamLattice" ] [incr menu_id] PRE [list ::Solid::examples::StaticBeamLattice] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "---"] [incr menu_id] PRE "" "" "" insertbefore =
    GiDMenu::UpdateMenus
}

proc Solid::examples::UpdateMenus2D { } {
    set menu_id 7
    GiDMenu::InsertOption "Kratos" [list "NotchedBeam" ] [incr menu_id] PRE [list ::Solid::examples::NotchedBeam] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] [incr menu_id] PRE [list ::Solid::examples::DynamicRod] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "---"] [incr menu_id] PRE "" "" "" insertbefore =
    GiDMenu::UpdateMenus
}

proc Solid::examples::UpdateMenus2Da { } {
    set menu_id 7
    GiDMenu::InsertOption "Kratos" [list "CircularTank" ] [incr menu_id] PRE [list ::Solid::examples::CircularTank] "" "" insertbefore =
    GiDMenu::InsertOption "Kratos" [list "---"] [incr menu_id] PRE "" "" "" insertbefore =
    GiDMenu::UpdateMenus
}


Solid::examples::Init
