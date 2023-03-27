namespace eval ::GeoMechanics {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable _app
    variable dir

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::GeoMechanics::Init { app } {
    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "GeoMechanics"]
    
    # XML init event
    ::GeoMechanics::xml::Init
    ::GeoMechanics::write::Init
}
