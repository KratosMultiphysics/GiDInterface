namespace eval ::Dam {
    Kratos::AddNamespace [namespace current]
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::Dam::Init { app } {
    # Variable initialization
    variable dir
    variable _app
    
    set dir [apps::getMyDir "Dam"] 
    set _app $app

    ::Dam::xml::Init
    ::Dam::write::Init
}
