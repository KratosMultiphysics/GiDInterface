namespace eval PfemFluid::examples {

}

proc PfemFluid::examples::Init { } {
    uplevel #0 [list source [file join $::PfemFluid::dir examples WaterDamBreak.tcl]]
    uplevel #0 [list source [file join $::PfemFluid::dir examples DamBreakFSI.tcl]]
}

proc PfemFluid::examples::UpdateMenus { } {
    if {$::Model::SpatialDimension eq "2D"} {
        GiDMenu::InsertOption "Kratos" [list "---"] 7 PRE "" "" "" insertafter =
        GiDMenu::InsertOption "Kratos" [list "Water dam break" ] 7 PRE [list ::PfemFluid::examples::WaterDamBreak] "" "" insertafter =
        GiDMenu::InsertOption "Kratos" [list "Dam break FSI" ] 7 PRE [list ::PfemFluid::examples::DamBreakFSI] "" "" insertafter =
        GiDMenu::UpdateMenus
    }
}

PfemFluid::examples::Init
