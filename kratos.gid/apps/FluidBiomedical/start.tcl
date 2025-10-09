namespace eval ::FluidBiomedical {
    # Variable declaration
    variable dir
    variable _app
    Kratos::AddNamespace [namespace current]

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::FluidBiomedical::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    #W "Sourced FSI"
    set dir [apps::getMyDir "FluidBiomedical"]
    set _app $app

    ::FluidBiomedical::xml::Init
    ::FluidBiomedical::write::Init

}
