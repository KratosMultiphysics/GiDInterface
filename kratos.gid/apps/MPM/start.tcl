namespace eval ::MPM {
    # Variable declaration
    variable dir
    variable _app
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

proc ::MPM::GetAttribute {name} {return [$::MPM::_app getProperty $name]}
proc ::MPM::GetUniqueName {name} {return [$::MPM::_app getUniqueName $name]}
proc ::MPM::GetWriteProperty {name} {return [$::MPM::_app getWriteProperty $name]}
