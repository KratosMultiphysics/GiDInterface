namespace eval ::Dam {
    # Variable declaration
    variable dir
    variable kratos_name
}

proc ::Dam::Init { } {
    # Variable initialization
    variable dir
    variable kratos_name
    set kratos_name "DamApplication"
    
    set dir [apps::getMyDir "Dam"]
    set ::Model::ValidSpatialDimensions [list 2D 3D]
    
    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    LoadMyFiles    
}

proc ::Dam::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]   
}

::Dam::Init
