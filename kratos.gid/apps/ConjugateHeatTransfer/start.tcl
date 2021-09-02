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
