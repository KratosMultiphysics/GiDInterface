namespace eval ::Structural {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
    proc SetWriteProperty {name value} {variable _app; return [$_app setWriteProperty $name $value]}
}

proc ::Structural::Init { app } {
    # Variable initialization
    variable dir
    set dir [apps::getMyDir "Structural"]
    variable _app
    set _app $app

    ::Structural::xml::Init
    ::Structural::write::Init
}

# Some conditions applied over small displacement parts must change the topology name... una chufa
proc ::Structural::ApplicationSpecificGetCondition {condition group etype nnodes} {
    return [Structural::write::ApplicationSpecificGetCondition $condition $group $etype $nnodes]
}

# Add formfinding button in Kratos menu in postprocess
proc ::Structural::CustomMenus { } {
    Structural::examples::UpdateMenus

    GiDMenu::InsertOption "Kratos" [list "---"] 8 POST "" "" "" insertafter =
    GiDMenu::InsertOption "Kratos" [list "Formfinding - Update geometry" ] end POST [list ::Structural::Formfinding::UpdateGeometry] "" "" insert =
    GiDMenu::UpdateMenus
}