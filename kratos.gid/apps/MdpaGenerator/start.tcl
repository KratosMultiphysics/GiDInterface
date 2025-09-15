namespace eval ::MdpaGenerator {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable _app
    variable dir

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
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

proc write::GetWriteMode {} {
    return [::MdpaGenerator::xml::GetCurrentWriteMode]
}


proc ::MdpaGenerator::CustomToolbarItems { } {
    variable dir

    Kratos::ToolbarAddItem "OpenFlowgraph" "graph.png" [list -np- Flowgraph::LaunchFlowgraph] [= "Open Flowgraph"]
}