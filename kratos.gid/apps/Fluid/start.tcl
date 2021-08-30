namespace eval ::Fluid {
    # Variable declaration
    variable _app
    variable dir
}

proc ::Fluid::Init { app } {
    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "Fluid"]
    
    # XML init event
    ::Fluid::xml::Init
    ::Fluid::write::Init
}

proc ::Fluid::GetAttribute {name} {return [$::Fluid::_app getProperty $name]}
proc ::Fluid::GetUniqueName {name} {return [$::Fluid::_app getUniqueName $name]}
proc ::Fluid::GetWriteProperty {name} {return [$::Fluid::_app getWriteProperty $name]}
