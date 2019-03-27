namespace eval ::Buoyancy {
    # Variable declaration
    variable id
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::Buoyancy::Init { } {
    # Variable initialization
    variable id
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set id "Buoyancy"
    
    set kratos_name Buoyancyapplication
    
    #W "Sourced FSI"
    set dir [apps::getMyDir "Buoyancy"]
    set prefix Buoyancy_
    
    apps::LoadAppById "Fluid"
    apps::LoadAppById "ConvectionDiffusion"
    
    # Intervals 
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    set ::Model::ValidSpatialDimensions [list 2D 3D]
    LoadMyFiles
    #::spdAux::CreateDimensionWindow
}

proc ::Buoyancy::LoadMyFiles { } {
    variable id
    variable dir
    
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    if {[apps::getActiveAppId] eq $id} {
        uplevel #0 [list source [file join $dir examples examples.tcl]]
    }
}

proc ::Buoyancy::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::Buoyancy::CustomToolbarItems { } {
    variable dir
    Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::Buoyancy::examples::HeatedSquare] [= "Example\nBuoyancy driven cavity flow (Ra = 1e6 - Pr = 0.71)"]   
}

::Buoyancy::Init
