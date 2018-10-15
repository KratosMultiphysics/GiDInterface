namespace eval ::ConvectionDiffusion {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::ConvectionDiffusion::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable attributes
    variable kratos_name

    set kratos_name "ConvectionDiffusionApplication"
    set dir [apps::getMyDir "ConvectionDiffusion"]
    set attributes [dict create]

    set prefix CNVDFF
    set ::Model::ValidSpatialDimensions [list 2D 3D]

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    dict set attributes UseIntervals 1

    LoadMyFiles
    #::spdAux::CreateDimensionWindow
}

proc ::ConvectionDiffusion::LoadMyFiles { } {
    variable dir

    #uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::ConvectionDiffusion::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::ConvectionDiffusion::CustomToolbarItems { } {
    variable dir
    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::ConvectionDiffusion::examples::CylinderHeatFlow] [= "Example\nCylinder heat flow"]   
}

proc ::ConvectionDiffusion::CustomMenus { } {
     #ConvectionDiffusion::examples::UpdateMenus
}

::ConvectionDiffusion::Init
