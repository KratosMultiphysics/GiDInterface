namespace eval ::ConjugateHeatTransfer {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::ConjugateHeatTransfer::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes
    
    set kratos_name ConjugateHeatTransferApplication
    
    #W "Sourced ConjugateHeatTransfer"
    set dir [apps::getMyDir "ConjugateHeatTransfer"]
    set prefix ConjugateHeatTransfer
    
    
    apps::LoadAppById "Buoyancy"
    apps::LoadAppById "ConvectionDiffusion"
    
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

proc ::ConjugateHeatTransfer::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    #uplevel #0 [list source [file join $dir write write.tcl]]
    #uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    #uplevel #0 [list source [file join $ConjugateHeatTransfer::dir examples examples.tcl]]
}

proc ::ConjugateHeatTransfer::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

::ConjugateHeatTransfer::Init
