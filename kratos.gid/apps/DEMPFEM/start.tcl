namespace eval ::DEMPFEM {
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
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
