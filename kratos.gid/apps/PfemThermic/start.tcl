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
    # Reset the left toolbar
    set Kratos::kratos_private(MenuItems) [dict create]
    set img_dir [file join $dir images]
    if {[gid_themes::GetCurrentTheme] eq "GiD_black"} {
        set img_dir [file join $img_dir Black]
    }
	Kratos::ToolbarAddItem "Model" [file join $img_dir "modelProperties.png"] [list -np- gid_groups_conds::open_conditions menu] [= "Define the model properties"]
    Kratos::ToolbarAddItem "Run" [file join $img_dir "runSimulation.png"] {Utilities Calculate} [= "Run the simulation"]
    Kratos::ToolbarAddItem "Output" [file join $img_dir "view.png"] [list -np- PWViewOutput] [= "View process info"]
    Kratos::ToolbarAddItem "Stop" [file join $img_dir "cancelProcess.png"] {Utilities CancelProcess} [= "Cancel process"]
	if {$::Model::SpatialDimension eq "2D"} {
	    Kratos::ToolbarAddItem "Examples" "losta.png" [list -np- ::Examples::StartWindow [apps::getActiveAppId]] [= "Examples window"]
    }
}

::PfemThermic::Init
