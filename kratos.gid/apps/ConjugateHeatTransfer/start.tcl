namespace eval ::ConjugateHeatTransfer {
    # Variable declaration
    variable id
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::ConjugateHeatTransfer::Init { } {
    # Variable initialization
    variable id
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set kratos_name ConvectionDiffusionApplication

    set id ConjugateHeatTransfer
    set dir [apps::getMyDir "ConjugateHeatTransfer"]
    set prefix ConjugateHeatTransfer

    apps::LoadAppById "Buoyancy"

    # Intervals
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    set ::Model::ValidSpatialDimensions [list 2D 3D]
    LoadMyFiles
}

proc ::ConjugateHeatTransfer::LoadMyFiles { } {
    variable id
    variable dir

    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    if {[apps::getActiveAppId] eq $id} {
        uplevel #0 [list source [file join $dir examples examples.tcl]]
    }
}

proc ::ConjugateHeatTransfer::CustomToolbarItems { } {
    variable dir
    if {$::Model::SpatialDimension eq "2D"} {
        Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::ConjugateHeatTransfer::examples::HeatedSquare] [= "Example\nSquare heat source"]
        Kratos::ToolbarAddItem "ExampleCylinderCooling" "example.png" [list -np- ::ConjugateHeatTransfer::examples::CylinderCooling] [= "Example\nCylinder cooling (Re = 100 - Pr = 2)"]
        Kratos::ToolbarAddItem "ExampleBFS" "example.png" [list -np- ::ConjugateHeatTransfer::examples::BFS] [= "Example\nBackward Facing Step (BFS)"]
    }
}

proc ::ConjugateHeatTransfer::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}
proc ::ConjugateHeatTransfer::CustomMenus { } {
    ConjugateHeatTransfer::examples::UpdateMenus
}

::ConjugateHeatTransfer::Init
