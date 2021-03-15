namespace eval ::PfemMelting {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::PfemMelting::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set attributes [dict create]
    set kratos_name PfemMelting

    set dir [apps::getMyDir "PfemMelting"]
    set prefix PFEMMELTING_
    set ::spdAux::TreeVisibility 0

    apps::LoadAppById "Buoyancy"

    # Intervals
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    
    #TODO: dimensions?
    set ::Model::ValidSpatialDimensions [list 2D 3D] 

    LoadMyFiles
}

proc ::PfemMelting::LoadMyFiles { } {
    variable dir

    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeMDPA_Parts.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    #uplevel #0 [list source [file join $dir examples examples.tcl]]
}

proc ::PfemMelting::BeforeMeshGeneration {elementsize} {
    ::Buoyancy::BeforeMeshGeneration $elementsize
}

proc ::PfemMelting::AfterMeshGeneration {fail} {
    ::Buoyancy::AfterMeshGeneration $fail
}

proc ::PfemMelting::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::PfemMelting::AfterSaveModel {filespd} {
    ::Buoyancy::AfterSaveModel $filespd
}

::PfemMelting::Init
