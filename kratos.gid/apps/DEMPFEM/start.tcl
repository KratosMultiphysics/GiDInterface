namespace eval ::DEMPFEM {
    # Variable declaration
    variable dir
    variable _app
}

proc ::DEMPFEM::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set dir [apps::getMyDir "DEMPFEM"]
    set prefix DEMPFEM_

    DEMPFEM::xml::Init
    DEMPFEM::write::Init
}

proc ::DEMPFEM::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::DEMPFEM::AfterMeshGeneration {fail} {
    ::DEM::AfterMeshGeneration $fail
}

proc ::DEMPFEM::AfterSaveModel {filespd} {
    ::DEM::AfterSaveModel $filespd
}
