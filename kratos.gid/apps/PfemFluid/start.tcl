namespace eval ::PfemFluid {
    # Variable declaration
    variable dir
    variable _app
}

proc ::PfemFluid::Init { app } {
    # Variable initialization
    variable dir
    variable _app
    set dir [apps::getMyDir "PfemFluid"]
    set _app $app

    PfemFluid::xml::Init
    PfemFluid::write::Init
}

proc ::PfemFluid::CustomToolbarItems { } {
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
    Kratos::ToolbarAddItem "Examples" "losta.png" [list -np- ::Examples::StartWindow [apps::getActiveAppId]] [= "Examples window"]   
    Kratos::ToolbarAddItem "SpacerApp" "" "" ""
}

proc ::PfemFluid::GetAttribute {name} {return [$::PfemFluid::_app getProperty $name]}
proc ::PfemFluid::GetUniqueName {name} {return [$::PfemFluid::_app getUniqueName $name]}
proc ::PfemFluid::GetWriteProperty {name} {return [$::PfemFluid::_app getWriteProperty $name]}
