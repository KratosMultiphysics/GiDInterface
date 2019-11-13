namespace eval ::CDEM {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::CDEM::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set attributes [dict create]
    set kratos_name DEMapplication

    set dir [apps::getMyDir "CDEM"]
    set prefix CDEM_
    set ::spdAux::TreeVisibility 0

    apps::LoadAppById "DEM"

    # Intervals
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    set ::Model::ValidSpatialDimensions [list 2D 3D]

    LoadMyFiles
}

proc ::CDEM::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Parts.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Walls.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]
}

proc ::CDEM::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::CDEM::AfterMeshGeneration {fail} {
    ::DEM::AfterMeshGeneration $fail
}

proc ::CDEM::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::CDEM::CustomToolbarItems { } {
    variable dir
    if {$::Model::SpatialDimension eq "2D"} {
        Kratos::ToolbarAddItem "Example" [file join $dir images drop.png] [list -np- ::CDEM::examples::ContinuumDrop] [= "Example\nRocks fall"]
    }
    Kratos::ToolbarAddItem "Bulk grouping" [file join $dir images stone.png] [list -np- ::CDEM::examples::BulkGroup] [= "Plugin\nBulk grouping"]
}

::CDEM::Init
