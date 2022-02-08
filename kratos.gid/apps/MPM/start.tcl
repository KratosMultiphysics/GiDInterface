namespace eval ::MPM {
    Kratos::AddNamespace [namespace current]
    
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::MPM::Init { app } {
    # Variable initialization
    variable dir
    variable _app
    set _app $app

    set dir [apps::getMyDir "MPM"]
    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1

    # XML init event
    ::MPM::xml::Init
    ::MPM::write::Init
}
