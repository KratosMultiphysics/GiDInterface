namespace eval DEMPFEM::examples {

}

proc DEMPFEM::examples::Init { } {
    uplevel #0 [list source [file join $::DEMPFEM::dir examples InnerSphere.tcl]]
}

proc DEMPFEM::examples::UpdateMenus { } {
    GiDMenu::InsertOption "Kratos" [list "---"] 8 PRE "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Heated square" ] 8 PRE [list ::DEMPFEM::examples::InnerSphere] "" "" insertafter =
    GiDMenu::UpdateMenus
}

DEMPFEM::examples::Init