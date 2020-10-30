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
	
	set dir [apps::getMyDir "PfemThermic"]
    set prefix PFEMTHERMIC_
	set kratos_name PfemThermicDynamicsApplication
    set attributes [dict create]
	dict set attributes UseIntervals 1
	dict set attributes UseRestart 1

	apps::LoadAppById "PfemFluid"
    apps::LoadAppById "ConvectionDiffusion"
	
	if {$::Kratos::kratos_private(DevMode) ne "dev"} {error [= "You need to change to Developer mode in the Kratos menu"] }
	
    set ::spdAux::TreeVisibility 1
    set ::Model::ValidSpatialDimensions [list 2D 3D]

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
