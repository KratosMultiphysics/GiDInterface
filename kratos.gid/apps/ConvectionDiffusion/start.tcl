namespace eval ::ConvectionDiffusion {
    # Variable declaration
    variable dir
    variable _app
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

proc ::ConvectionDiffusion::GetAttribute {name} {return [$::ConvectionDiffusion::_app getProperty $name]}
proc ::ConvectionDiffusion::GetUniqueName {name} {return [$::ConvectionDiffusion::_app getUniqueName $name]}
proc ::ConvectionDiffusion::GetWriteProperty {name} {return [$::ConvectionDiffusion::_app getWriteProperty $name]}
