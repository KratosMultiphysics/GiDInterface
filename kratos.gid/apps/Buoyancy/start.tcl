namespace eval ::Buoyancy {
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::Buoyancy::Init { app } {
    # Variable initialization
    variable dir
    variable _app
    
    #W "Sourced FSI"
    set dir [apps::getMyDir "Buoyancy"]
    set _app $app
    
    ::Buoyancy::xml::Init
    ::Buoyancy::write::Init
    
}
