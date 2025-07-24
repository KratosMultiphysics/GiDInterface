
namespace eval ::spdAux {
    variable info_main_window_text
    variable application_window_id
    set application_window_id .gid.win_app_selection
}

proc spdAux::CreateInitialApplicationsWindow {} {
    variable initwind
    variable must_open_init_window
    variable application_window_id
    
    # No graphics, no window
    if { [GidUtils::IsTkDisabled] } {
        return 0
    }
    
    # Sometimes we dont need the window (load event)
    if {$must_open_init_window == 0} {return ""}

    # If we have an active app, dont open this window
    if {[apps::getActiveApp] ne ""} {return ""}
    
    
    # Window creation
    set w $application_window_id
    set initwind $w
    # Close everything else
    gid_groups_conds::close_all_windows
    spdAux::DestroyInitWindow

    InitWindow $w [_ "Kratos Multiphysics - Application market"] PreKratosWindowGeom "" "" 1 0
    
    ttk::frame $w.top
    spdAux::RegisterWindow $initwind
    
    # List of applications -> by family
    ttk::labelframe $w.applications -text " Applications " -relief ridge 
    
    set appsid [::apps::getAllApplicationsID 0]
    set appspn [::apps::getAllApplicationsName 0]
    
    set col 0
    set row 0
    foreach appname $appspn appid $appsid {
        if {[apps::isPublic $appid] && [apps::isProductionAvailable $appid] } {
            # W "Application $appid is public and production available"
            set img [::apps::getImgFrom $appid]
            ttk::button $w.applications.img$appid -image $img -command [list apps::setActiveApp $appid]
            ttk::label $w.applications.text$appid -text $appname
            
            grid $w.applications.img$appid -column $col -row $row
            grid $w.applications.text$appid -column $col -row [expr $row +1]
            
            bind $w.applications.img$appid <Enter> {::spdAux::PlaceInformationWindowByPath %W applications}

            incr col
            if {$col >= 5} {set col 0; incr row; incr row}
        }
    }

    # List of tools
    ttk::labelframe $w.tools -text " Tools " -relief ridge 
    set toolsid [::apps::getAllApplicationsID 2]
    set toolspn [::apps::getAllApplicationsName 2]
    set col 0
    set row 0
    foreach toolname $toolspn toolid $toolsid {
        if {[apps::isPublic $toolid]} {
            set img [::apps::getImgFrom $toolid]
            set img_button $w.tools.img$toolid
            ttk::button $img_button -image $img -command [list apps::setActiveApp $toolid]
            ttk::label $w.tools.text$toolid -text $toolname
            
            grid $img_button -column $col -row $row
            grid $w.tools.text$toolid -column $col -row [expr $row +1]
            bind $w.tools.img$toolid <Enter> {::spdAux::PlaceInformationWindowByPath %W tools}
                        
            incr col
            if {$col >= 5} {set col 0; incr row; incr row}
        }
    }
    
    # More button
    if {[Kratos::IsDeveloperMode]} {
        set more_path [file nativename [file join $::Kratos::kratos_private(Path) images "more.png"] ]
        set img [gid_themes::GetImage $more_path Kratos]
        ttk::button $w.tools.img_more -image $img -command [list VisitWeb "https://github.com/KratosMultiphysics/GiDInterface"]
        ttk::label $w.tools.text_more -text "More..."

        grid $w.tools.img_more -column $col -row $row
        grid $w.tools.text_more -column $col -row [expr $row +1]
        incr col
        if {$col >= 5} {set col 0; incr row; incr row}
    }

    # Information panel
    ttk::labelframe $w.info -text " Information " -relief ridge 
    ttk::label $w.info.text -textvariable spdAux::info_main_window_text
    grid $w.info.text

    # Settings
    set settings_path [file nativename [file join $::Kratos::kratos_private(Path) images "settings.png"] ]
    set img [gid_themes::GetImage $settings_path Kratos]
    if {[GidUtils::VersionCmp "14.1.4d"] <0 } { set cmd  [list ChangeVariables kratos_preferences] } {set cmd  [list PreferencesWindow kratos_preferences]}
    ttk::button $w.tools.img_preferences -image $img -command $cmd
    ttk::label $w.tools.text_preferences -text "Preferences"
    grid $w.tools.img_preferences -column $col -row $row
    grid $w.tools.text_preferences -column $col -row [expr $row +1]
    incr col
    if {$col >= 5} {set col 0; incr row; incr row}
    
    grid $w.top
    # grid $w.top.title_text
    
    grid $w.applications
    grid $w.tools -columnspan 5 -sticky w
    grid $w.info -columnspan 5 -sticky we
}

proc spdAux::CreateLauncherWindow { current_launcher available_apps {window_text "Applications"} {action_text "Select an application"} } {
    set initwind $::spdAux::initwind

    set root [customlib::GetBaseRoot]
    set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]
    if { $nd ne "undefined" } {
        
    } {
        [$root selectNodes "value\[@n='nDim'\]"] setAttribute v wait

        set initwind $::spdAux::application_window_id
        spdAux::DestroyWindows
        spdAux::RegisterWindow $initwind
        set w $initwind

        InitWindow $w $window_text Kratos "" "" 1
        set initwind $w
        ttk::frame $w.top
        ttk::label $w.top.title_text -text $action_text
        ttk::frame $w.applications  -relief ridge
        set i 0
        set column 0
        set row 0
        foreach app $available_apps {
            # check if app exists
            if {![::apps::appExists $app]} {continue}
            set img [::apps::getImgFrom $app]
            set app_publicname [[::apps::getAppById $app] getPublicName]
            set but [ttk::button $w.applications.img$app -image $img -command [list ::spdAux::ChangeAppTo $current_launcher $app] ]
            bind $w.applications.img$app <Enter> {::spdAux::PlaceInformationWindowByPath %W applications}
            ttk::label $w.applications.text$app -text $app_publicname
            grid $w.applications.img$app -column $column -row $row
            grid $w.applications.text$app -column $column -row [expr $row +1]
            incr i
            incr column
            if {$column >= 5} {set column 0; incr row; incr row}
        }
        grid $w.top
        grid $w.top.title_text

        grid $w.applications

        # Information panel
        set spdAux::info_main_window_text ""
        ttk::labelframe $w.info -text " Information " -relief ridge 
        ttk::label $w.info.text -textvariable spdAux::info_main_window_text
        grid $w.info.text
        grid $w.info -sticky we
    }

}

proc spdAux::ChangeAppTo {current_launcher appid} {
    spdAux::deactiveApp $current_launcher
    spdAux::SetSpatialDimmension undefined
    apps::setActiveApp $appid
}


proc spdAux::PlaceInformationWindowByPath {win_path what} {
    variable application_window_id
    set app_id [string trimleft $win_path $application_window_id.$what.img]
    set app [::apps::getAppById $app_id]
    set description [$app getProperty description]
    set ::spdAux::info_main_window_text $description
}

proc spdAux::DestroyInitWindow { } {
    variable initwind
    if {[winfo exist $initwind]} {destroy $initwind}
}

proc spdAux::CreateDimensionWindow { } {
    variable must_open_dim_window

    if {$must_open_dim_window == 0} {return ""}
    
    spdAux::DestroyWindows
    set root [customlib::GetBaseRoot]
    
    set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]
    if { $nd ne "undefined" } {
        spdAux::SwitchDimAndCreateWindow $nd
        spdAux::RequestRefresh
    } {
        if {[llength $::Model::ValidSpatialDimensions] == 1} {
            spdAux::SwitchDimAndCreateWindow [lindex $::Model::ValidSpatialDimensions 0]
            spdAux::RequestRefresh
            return ""
        }
        set dir $::Kratos::kratos_private(Path)
        
        set initwind .gid.win_dimension
        set w $initwind 
        InitWindow $w [_ "Kratos Multiphysics"] Kratos "" "" 1
        set initwind $w
        spdAux::RegisterWindow $initwind
        ttk::frame $w.top
        ttk::label $w.top.title_text -text [_ " Dimension selection"]
        
        ttk::frame $w.information  -relief ridge
        set i 0
        foreach dim $::Model::ValidSpatialDimensions {
            set imagepath [getImagePathDim $dim]
            if {![file exists $imagepath]} {set imagepath [file nativename [file join $dir images "$dim.png"]]}
            set img [gid_themes::GetImage $imagepath "Kratos"]
            set but [ttk::button $w.information.img$dim -image $img -command [list spdAux::SwitchDimAndCreateWindow $dim] ]
            
            grid $w.information.img$dim -column $i -row 0
            incr i
        }
        grid $w.top
        grid $w.top.title_text
        
        grid $w.information
    }
}

proc spdAux::SetSpatialDimmension {ndim} {
    
    set root [customlib::GetBaseRoot]
    set ::Model::SpatialDimension $ndim
    
    set nd [$root selectNodes "value\[@n='nDim'\]"]
    
    $nd setAttribute v $::Model::SpatialDimension
}

proc spdAux::SwitchDimAndCreateWindow { ndim } {
    variable TreeVisibility
    
    SetSpatialDimmension $ndim
    spdAux::DestroyWindows
    
    processIncludes
    parseRoutes
    
    apps::ExecuteOnCurrentXML MultiAppEvent init
    
    if { $::Kratos::kratos_private(ProjectIsNew) eq 1} {
        spdAux::CustomTreeCommon
        apps::ExecuteOnCurrentXML CustomTree ""
    }
    
    if {$TreeVisibility} {
        customlib::UpdateDocument
        spdAux::PreChargeTree
        spdAux::TryRefreshTree
        spdAux::OpenTree
    }
    ::Kratos::CreatePreprocessModelTBar
    ::Kratos::UpdateMenus
}

proc spdAux::reactiveApp { } {
    #W "Reactive"
    variable initwind    
    if { ![GidUtils::IsTkDisabled] } {
        if { [winfo exists $initwind] } {
            destroy $initwind
        }
    }
    set root [customlib::GetBaseRoot]
    set ::Model::SpatialDimension [[$root selectNodes "value\[@n='nDim'\]"] getAttribute v ]
    set appname [[$root selectNodes "hiddenfield\[@n='activeapp'\]"] @v ]
    
    apps::setActiveApp $appname
}

proc spdAux::deactiveApp { appid } {
    
    set root [customlib::GetBaseRoot]
    [$root selectNodes "hiddenfield\[@n='activeapp'\]"] setAttribute v ""
    foreach elem [$root getElementsByTagName "appLink"] {
        if {$appid eq [$elem getAttribute "appid"] && [$elem getAttribute "active"] eq "1"} {
            $elem setAttribute "active" 0
            break
        } 
    }
}

proc spdAux::activeApp { appid } {
    #W "Active $appid"
    catch {
        set root [customlib::GetBaseRoot]
        [$root selectNodes "hiddenfield\[@n='activeapp'\]"] setAttribute v $appid
        foreach elem [$root getElementsByTagName "appLink"] {
            if {$appid eq [$elem getAttribute "appid"] && [$elem getAttribute "active"] eq "0"} {
                $elem setAttribute "active" 1
                set must_open_init_window 0
            } else {
                $elem setAttribute "active" 0
            }
        }
    }
    
    set nd [$root selectNodes "value\[@n='nDim'\]"]
    if {[$nd getAttribute v] ne "wait"} {
        if {[$nd getAttribute v] ne "undefined"} {
            set ::Model::SpatialDimension [$nd getAttribute v]
            spdAux::SwitchDimAndCreateWindow $::Model::SpatialDimension
            spdAux::TryRefreshTree
        } {
            ::spdAux::CreateDimensionWindow
        }
    }
}

proc spdAux::SetActiveAppFromDOM { } {
    set activeapp_dom ""
    set root [customlib::GetBaseRoot]
    set activeapp_node [$root selectNodes "//hiddenfield\[@n='activeapp'\]"]
    if {$activeapp_node ne ""} {
        set activeapp_dom [get_domnode_attribute $activeapp_node v]
        if { $activeapp_dom != "" } {
            apps::setActiveApp $activeapp_dom
        }
    }
    return $activeapp_dom
}
