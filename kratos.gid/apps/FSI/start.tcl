namespace eval ::FSI {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::FSI::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes
    
    set kratos_name FSIapplication

    #W "Sourced FSI"
    set dir [apps::getMyDir "FSI"]
    set prefix FSI
    
    
    apps::LoadAppById "Structural"
    apps::LoadAppById "Fluid"
    
    # Intervals 
    dict set attributes UseIntervals 1
    # dict set ::Fluid::attributes UseIntervals 0
    # dict set ::Structural::attributes UseIntervals 0

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    set ::Model::ValidSpatialDimensions [list 2D 3D]
    LoadMyFiles
    #::spdAux::CreateDimensionWindow
}

proc ::FSI::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $FSI::dir examples examples.tcl]]
}

proc ::FSI::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

::FSI::Init
