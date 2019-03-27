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
    GiDMenu::InsertOption "Kratos" [list "DynamicBeam" ] 8 PRE [list ::Solid::examples::DynamicBeam] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "CircularTank" ] 9 PRE [list ::Solid::examples::CircularTank] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "EccentricColumn" ] 10 PRE [list ::Solid::examples::EccentricColumn] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] 11 PRE [list ::Solid::examples::DynamicRod] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "StaticBeamLattice" ] 12 PRE [list ::Solid::examples::StaticBeamLattice] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "---"] 13 PRE "" "" "" insertafter =
    GiDMenu::UpdateMenus
}

proc Solid::examples::UpdateMenus2D { } {
    GiDMenu::InsertOption "Kratos" [list "NotchedBeam" ] 8 PRE [list ::Solid::examples::NotchedBeam] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "DynamicRod" ] 9 PRE [list ::Solid::examples::DynamicRod] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "---"] 10 PRE "" "" "" insertafter =
    GiDMenu::UpdateMenus
}

proc Solid::examples::UpdateMenus2Da { } {
    GiDMenu::InsertOption "Kratos" [list "CircularTank" ] 8 PRE [list ::Solid::examples::CircularTank] "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "---"] 9 PRE "" "" "" insertafter =
    GiDMenu::UpdateMenus
}


Solid::examples::Init
