namespace eval ::Solid {
    # Variable declaration
    variable dir
    variable attributes
    variable kratos_name
}

proc ::Solid::Init { } {
    # Variable initialization
    variable dir
    variable attributes
    variable kratos_name
    set kratos_name SolidMechanicsApplication
    
    set dir [apps::getMyDir "Solid"]
    set ::Model::ValidSpatialDimensions [list 2D 2Da 3D]
    set attributes [dict create]
    
    # Intervals
    dict set attributes UseIntervals 1
    
    # Restart available
    dict set attributes UseRestart 1
    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    LoadMyFiles
    #::spdAux::CreateDimensionWindow
}

proc ::Solid::LoadMyFiles { } {
    variable dir
    
    uplevel #0 [list source [file join $dir examples examples.tcl]]
    uplevel #0 [list source [file join $dir xml GetFromXML.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}

proc ::Solid::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::Solid::CustomToolbarItems { } {
    variable dir
    # Reset the left toolbar
    set Kratos::kratos_private(MenuItems) [dict create]
    set img_dir [file join $dir images]
    if {[gid_themes::GetCurrentTheme] eq "GiD_black"} {
        set img_dir [file join $img_dir Black]
    }
    Kratos::ToolbarAddItem "Model" [file join $img_dir "modelProperties.png"] [list -np- gid_groups_conds::open_conditions menu] [= "Define the model properties"]
    Kratos::ToolbarAddItem "Spacer" "" "" ""
    Kratos::ToolbarAddItem "Run" [file join $img_dir "runSimulation.png"] {Utilities Calculate} [= "Run the simulation"]
    Kratos::ToolbarAddItem "Output" [file join $img_dir "view.png"] [list -np- PWViewOutput] [= "View process info"]
    Kratos::ToolbarAddItem "Stop" [file join $img_dir "cancelProcess.png"] {Utilities CancelProcess} [= "Cancel process"]
    Kratos::ToolbarAddItem "Spacer" "" "" ""
    # Add examples
    if { $::Model::SpatialDimension eq "2Da" } {
	Kratos::ToolbarAddItem "Example" [file join $img_dir "tank_example.png"] [list -np- ::Solid::examples::CircularTank] [= "Example\nCircular water tank"]
    }
    if { $::Model::SpatialDimension eq "2D" } {
	Kratos::ToolbarAddItem "Example" [file join $img_dir "notched_example.png"] [list -np- ::Solid::examples::NotchedBeam] [= "Example\nNotched beam damage"]	
	Kratos::ToolbarAddItem "Example" [file join $img_dir "rod_example.png"] [list -np- ::Solid::examples::DynamicRod] [= "Example\nDynamic rod pendulus"]
    }
    if { $::Model::SpatialDimension eq "3D" } {
	Kratos::ToolbarAddItem "Example" [file join $img_dir "beam_example.png"] [list -np- ::Solid::examples::DynamicBeam] [= "Example\nDynamic beam rotating"]
	Kratos::ToolbarAddItem "Example" [file join $img_dir "tank_example.png"] [list -np- ::Solid::examples::CircularTank] [= "Example\nCircular water tank"]
	Kratos::ToolbarAddItem "Example" [file join $img_dir "column_example.png"] [list -np- ::Solid::examples::EccentricColumn] [= "Example\nEccentric column"]
	Kratos::ToolbarAddItem "Example" [file join $img_dir "rod_example.png"] [list -np- ::Solid::examples::DynamicRod] [= "Example\nDynamic rod pendulus"]
    }
    Kratos::ToolbarAddItem "Spacer" "" "" ""
    
}

proc ::Solid::CustomMenus { } {
    Solid::examples::UpdateMenus$::Model::SpatialDimension
}

::Solid::Init
