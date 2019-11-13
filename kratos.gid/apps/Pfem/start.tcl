namespace eval ::Pfem {
    # Variable declaration
    variable dir
    variable attributes
    variable kratos_name
}

proc ::Pfem::Init { } {
    # Variable initialization
    variable dir
    variable attributes
    variable kratos_name
    set kratos_name PfemFluidDynamicsApplication

    set dir [apps::getMyDir "Pfem"]
    set ::Model::ValidSpatialDimensions [list 2D 2Da 3D]
    # Allow to open the tree
    set ::spdAux::TreeVisibility 1
    set attributes [dict create]
    dict set attributes UseIntervals 1
    if {$::Kratos::kratos_private(DevMode) ne "dev"} {error [= "You need to change to Developer mode in the Kratos menu"] }
    dict set attributes UseRestart 1
    LoadMyFiles
}

proc ::Pfem::LoadMyFiles { } {
    variable dir
    uplevel #0 [list source [file join $dir xml XmlController.tcl]]
    uplevel #0 [list source [file join $dir xml BodiesWindowController.tcl]]
    uplevel #0 [list source [file join $dir .. Solid write write.tcl]]
    uplevel #0 [list source [file join $dir write write.tcl]]
    uplevel #0 [list source [file join $dir write writeProjectParameters.tcl]]
}


proc ::Pfem::GetAttribute {name} {
    variable attributes
    set value ""
    if {[dict exists $attributes $name]} {set value [dict get $attributes $name]}
    return $value
}

proc ::Pfem::CustomToolbarItems { } {
    variable dir
    # Reset the left toolbar
    set Kratos::kratos_private(MenuItems) [dict create]
    set img_dir [file join $dir images]
    if {[gid_themes::GetCurrentTheme] eq "GiD_black"} {
        set img_dir [file join $img_dir Black]
    }
    Kratos::ToolbarAddItem "Model" [file join $img_dir "modelProperties.png"] [list -np- gid_groups_conds::open_conditions menu] [= "Define the model properties"]
    Kratos::ToolbarAddItem "Bodies" [file join $img_dir "body.png"] [list -np- Pfem::xml::BodiesWindow::Start] [= "Bodies window"]
    Kratos::ToolbarAddItem "Spacer" "" "" ""
    Kratos::ToolbarAddItem "Run" [file join $img_dir "runSimulation.png"] {Utilities Calculate} [= "Run the simulation"]
    Kratos::ToolbarAddItem "Output" [file join $img_dir "view.png"] [list -np- PWViewOutput] [= "View process info"]
    Kratos::ToolbarAddItem "Stop" [file join $img_dir "cancelProcess.png"] {Utilities CancelProcess} [= "Cancel process"]
    Kratos::ToolbarAddItem "SpacerApp" "" "" ""

}

::Pfem::Init
