namespace eval ::Buoyancy {
    # Variable declaration
    variable dir
    variable _app
}

proc ::Buoyancy::Init { app } {
    # Variable initialization
    variable dir
    variable _app
    
    #W "Sourced FSI"
    set dir [apps::getMyDir "Buoyancy"]
    set _app $app
    
    apps::LoadAppById "Fluid"
    apps::LoadAppById "ConvectionDiffusion"

    ::Buoyancy::xml::Init
    ::Buoyancy::write::Init
    
}

proc ::Buoyancy::GetAttribute {name} {return [$::Buoyancy::_app getProperty $name]}
proc ::Buoyancy::GetUniqueName {name} {return [$::Buoyancy::_app getUniqueName $name]}
proc ::Buoyancy::GetWriteProperty {name} {return [$::Buoyancy::_app getWriteProperty $name]}
