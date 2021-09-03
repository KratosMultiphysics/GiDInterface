namespace eval ::ConjugateHeatTransfer {
    # Variable declaration
    variable dir
    variable _app
}

proc ::ConjugateHeatTransfer::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    
    set _app $app
    set dir [apps::getMyDir "ConjugateHeatTransfer"]

    apps::LoadAppById "Buoyancy"

    ::ConjugateHeatTransfer::xml::Init
    ::ConjugateHeatTransfer::write::Init

}

proc ::ConjugateHeatTransfer::GetAttribute {name} {return [$::ConjugateHeatTransfer::_app getProperty $name]}
proc ::ConjugateHeatTransfer::GetUniqueName {name} {return [$::ConjugateHeatTransfer::_app getUniqueName $name]}
proc ::ConjugateHeatTransfer::GetWriteProperty {name} {return [$::ConjugateHeatTransfer::_app getWriteProperty $name]}