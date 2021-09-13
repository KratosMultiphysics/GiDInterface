namespace eval ::CompressibleFluid {
    Kratos::AddNamespace [namespace current]
    # Variable declaration
    variable dir
    
    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::CompressibleFluid::Init { app } {
    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "Fluid"]
    
    # XML init event
    ::CompressibleFluid::xml::Init
    ::CompressibleFluid::write::Init
}
