namespace eval ::CDEM {
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::CDEM::Init { app } {
    # Variable initialization
    variable dir
    set dir [apps::getMyDir "CDEM"]
    variable _app
    set _app $app
    
    CDEM::xml::Init
    CDEM::write::Init

}

proc ::CDEM::CustomToolbarItems { } {
    ::DEM::CustomToolbarItems
}

proc ::CDEM::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::CDEM::AfterMeshGeneration {fail} {
    ::DEM::AfterMeshGeneration $fail
}

proc ::CDEM::AfterSaveModel {filespd} {
    ::DEM::AfterSaveModel $filespd
}
