namespace eval ::DEMThermic {
    # Variable declaration
    variable dir
	variable prefix
    variable attributes
    variable kratos_name
}

proc ::DEMThermic::Init { } {
    # Variable initialization
    variable dir
	variable prefix
    variable kratos_name
	variable attributes
	
	set attributes [dict create]
	set kratos_name DEMThermicApplication
	
	set dir [apps::getMyDir "DEMThermic"]
	set prefix DEMThermic_
	
	set ::spdAux::TreeVisibility 0
	
	apps::LoadAppById "DEM"
	
	# Intervals
	dict set attributes UseIntervals 1
	
	# Allow to open the tree
    set ::spdAux::TreeVisibility 1
	
	set ::Model::ValidSpatialDimensions [list 2D 3D]
	LoadMyFiles
}

proc ::DEMThermic::LoadMyFiles { } {
    variable dir
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
    uplevel #0 [list source [file join $dir examples examples.tcl]]
}

proc ::DEMThermic::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::DEMThermic::BeforeMeshGeneration {elementsize} {
    ::DEM::BeforeMeshGeneration $elementsize
}

proc ::DEMThermic::AfterMeshGeneration {fail} {
    ::DEM::AfterMeshGeneration $fail
}

proc ::DEMThermic::AfterSaveModel {filespd} {
    ::DEM::AfterSaveModel $filespd
}

::DEMThermic::Init