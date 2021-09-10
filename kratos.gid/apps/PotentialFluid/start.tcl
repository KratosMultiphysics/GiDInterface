namespace eval ::PotentialFluid {
    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::PotentialFluid::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    set dir [apps::getMyDir "PotentialFluid"]
    set _app $app
    
    Kratos::AddRestoreVar "::GidPriv(DuplicateEntities)"
    set ::GidPriv(DuplicateEntities) 1
    PotentialFluid::xml::Init
    PotentialFluid::write::Init

}