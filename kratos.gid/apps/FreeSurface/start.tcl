namespace eval ::FreeSurface {
    # Variable declaration
    variable dir
    variable _app
    Kratos::AddNamespace [namespace current]

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::FreeSurface::Init { app } {
    # Variable initialization
    variable dir
    variable _app

    #W "Sourced FSI"
    set dir [apps::getMyDir "FreeSurface"]
    set _app $app

    ::FreeSurface::xml::Init
    ::FreeSurface::write::Init

}
