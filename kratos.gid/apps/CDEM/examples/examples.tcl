namespace eval CDEM::examples {

}

proc CDEM::examples::Init { } {
    W "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    W $::Model::SpatialDimension
    W "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    uplevel #0 [list source [file join $::CDEM::dir examples ContinuumDrop2D.tcl]]
    if {$::Model::SpatialDimension eq "3D"} {
    uplevel #0 [list source [file join $::CDEM::dir examples ContSpheresDrop3D.tcl]]
    }
}

proc CDEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    if {$::Model::SpatialDimension eq "2D"} {
    GiDMenu::InsertOption "Kratos" [list "Stone block and sand" ] 8 PRE [list ::CDEM::examples::ContinuumDrop2D] "" "" insertafter =
    }
    if {$::Model::SpatialDimension eq "3D"} {
    GiDMenu::InsertOption "Kratos" [list "Stone block and sand" ] 8 PRE [list ::CDEM::examples::ContSpheresDrop3D] "" "" insertafter =
    }
    GiDMenu::InsertOption "Kratos" [list "Bulk groups" ] 8 PRE [list ::CDEM::xml::BulkGroup] "" "" insertafter =
    GiDMenu::UpdateMenus
    W "2"
}

CDEM::examples::Init