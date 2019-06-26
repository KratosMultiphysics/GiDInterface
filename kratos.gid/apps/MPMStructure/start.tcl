namespace eval ::MPMStructure {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::MPMStructure::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes
    
    set kratos_name MPMStructureapplication
    
    set dir [apps::getMyDir "MPMStructure"]
    set prefix MPMStructure
    
    apps::LoadAppById "MPM"
    apps::LoadAppById "Structural"
    
    # Intervals 
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    set ::Model::ValidSpatialDimensions [list 2D 3D]
    LoadMyFiles
}

proc ::MPMStructure::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    #uplevel #0 [list source [file join $dir write write.tcl]]
    #uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::MPMStructure::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

::MPMStructure::Init
