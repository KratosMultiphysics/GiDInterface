namespace eval ::ConvectionDiffusion {
    # Variable declaration
    variable id
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::ConvectionDiffusion::Init { } {
    # Variable initialization
    variable id
    variable dir
    variable prefix
    variable attributes
    variable kratos_name

    set id ConvectionDiffusion
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
    variable id
    variable dir

    #uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    if {[apps::getActiveAppId] eq $id} {
        uplevel #0 [list source [file join $dir examples examples.tcl]]
    }
}

proc ::ConvectionDiffusion::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::ConvectionDiffusion::CustomToolbarItems { } {
    variable dir
    if {$::Model::SpatialDimension eq "2D"} {
        Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::ConvectionDiffusion::examples::HeatedSquare] [= "Example\nSquare heat flow"]
    }
}

proc ::ConvectionDiffusion::CustomMenus { } {
     #ConvectionDiffusion::examples::UpdateMenus
}

::ConvectionDiffusion::Init
