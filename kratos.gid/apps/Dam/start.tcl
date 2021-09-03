namespace eval ::Dam {
    # Variable declaration
    variable dir
    variable _app
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

proc ::Dam::GetAttribute {name} {return [$::Dam::_app getProperty $name]}
proc ::Dam::GetUniqueName {name} {return [$::Dam::_app getUniqueName $name]}
proc ::Dam::GetWriteProperty {name} {return [$::Dam::_app getWriteProperty $name]}
