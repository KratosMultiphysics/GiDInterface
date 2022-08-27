namespace eval ::PfemThermic {
    Kratos::AddNamespace [namespace current]

    # Variable declaration
    variable dir
    variable _app

    proc GetAttribute {name} {variable _app; return [$_app getProperty $name]}
    proc GetUniqueName {name} {variable _app; return [$_app getUniqueName $name]}
    proc GetWriteProperty {name} {variable _app; return [$_app getWriteProperty $name]}
}

proc ::PfemThermic::Init { app } {
    # Variable initialization
    variable dir
	set dir [apps::getMyDir "PfemThermic"]

    variable _app
	set _app $app

    PfemThermic::xml::Init
    PfemThermic::write::Init
}

proc ::PfemThermic::CustomToolbarItems { } {
    variable dir
    # Reset the left toolbar
    set Kratos::kratos_private(MenuItems) [dict create]
    set img_dir [file join $dir images]
    if {[gid_themes::GetCurrentTheme] eq "GiD_black"} {
        set img_dir [file join $img_dir Black]
    }
	Kratos::ToolbarAddItem "Model"                [file join $img_dir "modelProperties.png"] [list -np- gid_groups_conds::open_conditions menu] [= "Define the model properties"]
    Kratos::ToolbarAddItem "Run"                  [file join $img_dir "runSimulation.png"]   {Utilities Calculate}                              [= "Run the simulation"]
    Kratos::ToolbarAddItem "Output"               [file join $img_dir "view.png"]            [list -np- PWViewOutput]                           [= "View process info"]
    Kratos::ToolbarAddItem "Stop"                 [file join $img_dir "cancelProcess.png"]   {Utilities CancelProcess}                          [= "Cancel process"]
    Kratos::ToolbarAddItem "Examples" "losta.png" [list -np- ::Examples::StartWindow         [apps::getActiveAppId]]                            [= "Examples window"]
    Kratos::ToolbarAddItem "SpacerApp1" "" "" ""
    if {[info exists Kratos::kratos_private(UseFiles)] && $Kratos::kratos_private(UseFiles) == 1} {
        Kratos::ToolbarAddItem "Files" "files.png" [list -np- spdAux::LaunchFileWindow] [= "File handler window"]
    }
}
