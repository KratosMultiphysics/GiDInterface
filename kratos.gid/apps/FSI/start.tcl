namespace eval ::FSI {
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::FSI::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set _app $app
    set dir [apps::getMyDir "FSI"]
        
    ::FSI::xml::Init
    ::FSI::write::Init
}