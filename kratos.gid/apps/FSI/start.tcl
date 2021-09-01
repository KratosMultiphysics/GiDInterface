namespace eval ::FSI {
    # Variable declaration
    variable dir
    variable _app
}

proc ::FSI::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set _app $app
    set dir [apps::getMyDir "FSI"]
    
    apps::LoadAppById "Structural"
    apps::LoadAppById "Fluid"
    
    ::FSI::xml::Init
    ::FSI::write::Init
}

proc ::FSI::GetAttribute {name} {return [$::FSI::_app getProperty $name]}
proc ::FSI::GetUniqueName {name} {return [$::FSI::_app getUniqueName $name]}
proc ::FSI::GetWriteProperty {name} {return [$::FSI::_app getWriteProperty $name]}
