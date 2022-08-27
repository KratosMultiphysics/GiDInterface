namespace eval ::FluidDEM {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::FluidDEM::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set _app $app
    set dir [apps::getMyDir "FluidDEM"]

    FluidDEM::xml::Init
    FluidDEM::write::Init
}

proc ::FluidDEM::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::FluidDEM::AfterMeshGeneration { fail } {
    ::DEM::AfterMeshGeneration fail
}

proc ::FluidDEM::AfterSaveModel {filespd} {
    ::DEM::AfterSaveModel $filespd
}

proc ::FluidDEM::CustomToolbarItems { } {
    ::DEM::CustomToolbarItems
}


