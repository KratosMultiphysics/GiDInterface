namespace eval ::Fluid {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
    variable app_id
}

proc ::Fluid::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
    variable app_id
    
    set app_id Fluid

    set kratos_name "FluidDynamicsApplication"
    set dir [apps::getMyDir "Fluid"]
    set attributes [dict create]

    set prefix FL
    set ::Model::ValidSpatialDimensions [list 2D 3D]

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    dict set attributes UseIntervals 1

    #LoadMyFiles
    #::spdAux::CreateDimensionWindow
}

# proc ::Fluid::LoadMyFiles { } {
#     variable dir

#     uplevel #0 [list source [file join $dir examples examples.tcl]]
#     uplevel #0 [list source [file join $dir xml XmlController.tcl]]
#     uplevel #0 [list source [file join $dir write write.tcl]]
#     uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
# }

proc ::Fluid::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

::Fluid::Init
