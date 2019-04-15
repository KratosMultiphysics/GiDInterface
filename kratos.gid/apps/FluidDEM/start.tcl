namespace eval ::FluidDEM {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::FluidDEM::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set attributes [dict create]
    set kratos_name FluidDEMapplication

    #W "Sourced FSI"
    set dir [apps::getMyDir "FluidDEM"]
    set prefix FluidDEM_

    set ::spdAux::TreeVisibility 0

    apps::LoadAppById "DEM"
    apps::LoadAppById "Fluid"

    # Intervals
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    set ::Model::ValidSpatialDimensions [list 3D]
    LoadMyFiles
    # ::spdAux::CreateDimensionWindow
}

proc ::FluidDEM::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    #uplevel #0 [list source [file join $dir examples examples.tcl]]
}

proc ::FluidDEM::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::FluidDEM::AfterMeshGeneration { fail } {
    ::DEM::AfterMeshGeneration fail
}

proc ::FluidDEM::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::FluidDEM::CustomToolbarItems { } {
    variable dir
    #Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::FluidDEM::examples::InnerSphere] [= "Example\nInnerSphere"]
}

::FluidDEM::Init
