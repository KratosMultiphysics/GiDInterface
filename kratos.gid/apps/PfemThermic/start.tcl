namespace eval ::PfemThermic {
    # Variable declaration
    variable dir
    variable prefix
    variable attributes
    variable kratos_name
}

proc ::PfemThermic::Init { } {
    # Variable initialization
    variable dir
    variable prefix
    variable kratos_name
    variable attributes

    set attributes [dict create]
    set kratos_name PfemThermicDynamicsApplication

    set dir [apps::getMyDir "PfemThermic"]
    set prefix PFEMTHERMIC_

    set ::spdAux::TreeVisibility 0

	apps::LoadAppById "PfemFluid"
    apps::LoadAppById "ConvectionDiffusion"
	
	if {$::Kratos::kratos_private(DevMode) ne "dev"} {error [= "You need to change to Developer mode in the Kratos menu"] }

    # Intervals
    dict set attributes UseIntervals 1

    # Allow to open the tree
    set ::spdAux::TreeVisibility 1

    set ::Model::ValidSpatialDimensions [list 2D 3D]
	
	dict set attributes UseRestart 1
    LoadMyFiles
}

proc ::PfemThermic::LoadMyFiles { } {
    variable dir
    uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::PfemThermic::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::PfemThermic::CustomToolbarItems { } {
    variable dir
    if {$::Model::SpatialDimension eq "2D"} {
        Kratos::ToolbarAddItem "Example" "example.png" [list -np- ::PfemThermic::examples::ThermicSloshing] [= "Example\nThermic sloshing"]
    }
}

::PfemThermic::Init
