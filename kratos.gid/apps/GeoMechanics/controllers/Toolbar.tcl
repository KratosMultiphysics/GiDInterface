namespace eval ::GeoMechanics::toolbar {
    namespace path ::GeoMechanics
    Kratos::AddNamespace [namespace current]

    variable phases
    variable phases_toolbar_name
}

# This application has it's own toolbar, so common toolbar is disabled and here we can find the custom toolbar implementation
proc ::GeoMechanics::toolbar::Init { } {
    variable phases_toolbar_name
    set phases_toolbar_name phases_toolbar
    variable phases PhasesTBar
    set phases [list Geometry Stages]
    #CreateToolbarPhases

}

proc ::GeoMechanics::toolbar::CreateToolbarPhases { } {
    # Load phases menu items
    variable phases
    lappend phases 1
    lappend phases 2

    # Shows phases menu on top
    ::GeoMechanics::toolbar::CreatePhasesTBar
}

proc ::GeoMechanics::toolbar::CreatePhasesTBar { {type "DEFAULT INSIDELEFT"} } {
    if { [GidUtils::IsTkDisabled] } { return 0 }
    variable phases
    variable phases_toolbar_name

    global KGMBitmapsNames KGMBitmapsCommands KGMMBitmapsHelp
    
    
    ::GeoMechanics::toolbar::EndPhasesTBar
    
    set theme [gid_themes::GetCurrentTheme]
    set dir [file join $::Kratos::kratos_private(Path) images ]
    set iconslist [list ]
    set commslist [list ]
    set helpslist [list ]
    foreach phase $phases {
        # lappend iconslist [file join [file dirname [apps::getImgPathFrom [[apps::getActiveApp] getName] ]] [$phase get_icon] ]
        # lappend iconslist [file join [file dirname [apps::getImgPathFrom [[apps::getActiveApp] getName] ]] logo.png ]
        lappend iconslist "images/groups.gif"
        # lappend commslist [$phase get_command]
        lappend commslist [list Utilities CancelProcess]
        # lappend helpslist [$phase get_text]
        lappend helpslist "holaa"
    }

    set KGMBitmapsNames(0) $iconslist
    set KGMBitmapsCommands(0) $commslist
    set KGMBitmapsHelp(0) $helpslist

    set prefix Pre
    set name $phases_toolbar_name
    set procname ::GeoMechanics::toolbar::CreatePhasesTBar
    set ::Kratos::kratos_private(ToolBars,$name) [CreateOtherBitmaps ${name} [= "Geomechanics phases toolbar"] KGMBitmapsNames KGMBitmapsCommands KGMBitmapsHelp $dir $procname $type $prefix]

    AddNewToolbar [= "Geomechanics phases toolbar"] ${prefix}${name}WindowGeom $procname
    
}

proc ::GeoMechanics::toolbar::EndPhasesTBar { } {
    variable phases_toolbar_name

    set name $phases_toolbar_name

    ReleaseToolbar ${name}
    if {[info exists kratos_private(ToolBars,PreprocessModelTBar)]} {
        destroy $kratos_private(ToolBars,PreprocessModelTBar)
    }
    if {[info exists kratos_private(MenuItems)]} {
        unset kratos_private(MenuItems)
    }
    update
}