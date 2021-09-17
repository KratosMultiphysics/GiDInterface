namespace eval ::PfemMelting {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable dir
    variable _app
    
    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::PfemMelting::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set dir [apps::getMyDir "PfemMelting"]
    set _app $app

    PfemMelting::xml::Init
    PfemMelting::write::Init
}

proc ::PfemMelting::BeforeMeshGeneration {elementsize} {
    ::Buoyancy::BeforeMeshGeneration $elementsize
}

proc ::PfemMelting::AfterMeshGeneration {fail} {
    ::Buoyancy::AfterMeshGeneration $fail
}

proc ::PfemMelting::AfterSaveModel {filespd} {
    if {[info exists ::Buoyancy::AfterSaveModel]} {::Buoyancy::AfterSaveModel $filespd}
}

