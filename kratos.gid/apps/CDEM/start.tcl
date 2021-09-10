namespace eval ::CDEM {
    # Variable declaration
    variable dir
    variable _app
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

proc ::CDEM::GetAttribute {name} {return [$::CDEM::_app getProperty $name]}
proc ::CDEM::GetUniqueName {name} {return [$::CDEM::_app getUniqueName $name]}
proc ::CDEM::GetWriteProperty {name} {return [$::CDEM::_app getWriteProperty $name]}
