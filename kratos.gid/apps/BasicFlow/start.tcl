namespace eval ::BasicFlow {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable _app
    variable dir

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::BasicFlow::Init { app } {
    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "BasicFlow"]
    
    # XML init event
    ::BasicFlow::xml::Init
    ::BasicFlow::write::Init
}
