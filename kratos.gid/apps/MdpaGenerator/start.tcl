namespace eval ::MdpaGenerator {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable _app
    variable dir
}


proc ::MdpaGenerator::Init { app } {

    # Variable initialization
    variable _app
    variable dir

    set _app $app
    set dir [apps::getMyDir "MdpaGenerator"]

    ::MdpaGenerator::xml::Init
    ::MdpaGenerator::write::Init
}

proc ::MdpaGenerator::BreakRunCalculation {} {
    return true
}