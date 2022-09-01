namespace eval ::ConvectionDiffusion {
    Kratos::AddNamespace [namespace current]
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::ConvectionDiffusion::Init { app } {
    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "ConvectionDiffusion"]
    
    # XML init event
    ::ConvectionDiffusion::xml::Init
    ::ConvectionDiffusion::write::Init
}
