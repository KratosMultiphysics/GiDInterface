namespace eval ::PotentialFluid {
    # Variable declaration
    variable dir
    variable _app
}

proc ::PotentialFluid::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    apps::LoadAppById "Fluid"

    set dir [apps::getMyDir "PotentialFluid"]
    set _app $app
    
    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1
    PotentialFluid::xml::Init
    PotentialFluid::write::Init

}

proc ::PotentialFluid::GetAttribute {name} {return [$::PotentialFluid::_app getProperty $name]}
proc ::PotentialFluid::GetUniqueName {name} {return [$::PotentialFluid::_app getUniqueName $name]}
proc ::PotentialFluid::GetWriteProperty {name} {return [$::PotentialFluid::_app getWriteProperty $name]}
