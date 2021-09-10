##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::apps {
    Kratos::AddNamespace [namespace current]
    
    variable activeApp
    variable appList
}

proc apps::Init { } {
    variable activeApp
    variable appList
    set activeApp ""
    set appList [list ]
}

proc apps::ClearActiveApp {} {
    variable activeApp
    namespace delete "::[apps::getActiveAppId]"
    set activeApp ""
}

proc apps::setActiveApp {appid} {
    variable activeApp
    variable appList
    
    foreach app $appList {
        if {[$app getName] eq $appid} {
            set activeApp $app
            $app activate
            Kratos::Log "apps::setActiveApp $appid"
            break
        }
    }
    spdAux::activeApp $appid
}

proc apps::getActiveApp { } {
    variable activeApp;
    return $activeApp
}
proc apps::setActiveAppSoft { appid } {
    variable activeApp
    variable appList
    #W "set active app $appid in $appList"
    foreach app $appList {
        #W [$app getName]
        if {[$app getName] eq $appid} {
            set activeApp $app
            break
        }
    }
}

proc apps::getActiveAppId { } {
    variable activeApp;
    set id ""
    if {$activeApp ne ""} {
        set id [$activeApp getName]
    }
    return $id
}

proc apps::getAppById { id } {
    variable appList
    set appR ""
    foreach app $appList {
        if {[$app getName] eq $id} {set appR $app; break}
    }
    return $appR
}

proc apps::NewApp {appid publicname prefix} {
    variable appList
    set ap [App new $appid]
    $ap setPublicName $publicname
    $ap setPrefix $prefix
    lappend appList $ap
    return $ap
}

# also_tools => 0 all apps no tools | 1 all apps and tools | 2 only tools
proc apps::getAppsList {{also_tools 1}} {
    variable appList
    set list [list ]
    foreach app $appList {
        set is_tool [$app isTool]
        set pass 0
        switch $also_tools {
            0 { if {!$is_tool} {set pass 1} }
            1 { set pass 1 }
            2 { if {$is_tool} {set pass 1} }
        }
        if {$pass} {
            lappend list $app
        }
    }
    return $list
}
proc apps::getAllApplicationsName {{also_tools 1}} {
    
    set appnames [list ]
    foreach app [apps::getAppsList $also_tools] {
        lappend appnames [$app getPublicName]
    }
    return $appnames
}

proc apps::getAllApplicationsID {{also_tools 1}} {
    
    set appnames [list ]
    foreach app [apps::getAppsList $also_tools] {
        lappend appnames [$app getName]
    }
    return $appnames
}

proc apps::getImgFrom { appName {img "logo" } } {
    return [gid_themes::GetImage [getImgPathFrom $appName $img] "Kratos"]
}
proc apps::getImgPathFrom { appName {img "logo" } } {
    variable appList
    
    set imagespath ""
    foreach app $appList {
        if {[$app getName] eq $appName} {set imagespath [expr {$img == "logo" ? [$app getIcon] : [$app getImagePath $img] }]; break}
    }
    return $imagespath
    #return [Bitmap::get [file native $imagespath]]
}

proc apps::getMyDir {appName} {
    return [file join $::Kratos::kratos_private(Path) apps $appName]
}

proc apps::getCurrentUniqueName {un} {
    return [ExecuteOnCurrentXML getUniqueName $un]
}
proc apps::getAppUniqueName {appName un} {
    variable appList
    foreach app $appList {
        if {[$app getName] eq $appName} {return [$app executexml getUniqueName $un]}
    }
}

proc apps::ExecuteOnCurrentXML { func args} {
    variable activeApp
    if {$activeApp ne ""} {
        return [ExecuteOnAppXML [$activeApp getName] $func {*}$args]
    }
}
proc apps::ExecuteOnAppXML { appid func args} {
    set response ""
    set app [getAppById $appid]
    set response [$app executexml $func {*}$args]   

    return $response
}

proc apps::ExecuteOnApp {appid func args} {
    set response ""
    set app [getAppById $appid]
    set response [$app execute $func {*}$args]   

    return $response
}
proc apps::ExecuteOnCurrentApp {func args} {
    variable activeApp
    set response ""
    if {$activeApp ne ""} {
        set response [ExecuteOnApp [$activeApp getName] $func {*}$args]
    }
    return $response
}
proc apps::LoadAppById {appid} {
    variable appList
    foreach app $appList {
        if {[$app getName] eq $appid} {
            $app activate
            break
        }
    }
}

proc apps::isPublic {appId} {
    set app [getAppById $appId]
    if {$app eq ""} {return 0}
    return [$app isPublic]
}

proc apps::CheckElemState {elem inputid {arg ""} } {
    variable activeApp
    
    return [$activeApp executexml CheckElemState $elem $inputid $arg]
}


# Clase App
catch {App destroy}
oo::class create App {
    variable publicname
    variable name
    variable imagepath
    variable writeModelPartEvent
    variable writeParametersEvent
    variable writeCustomEvent
    variable writeValidateEvent
    variable prefix
    variable release
    variable is_tool

    variable properties
    
    constructor {n} {
        variable name
        variable publicname
        variable imagepath
        variable writeModelPartEvent
        variable writeParametersEvent
        variable writeCustomEvent
        variable writeValidateEvent
        variable prefix
        variable public
        variable is_tool
        variable properties
        
        set name $n
        set publicname $n
        set imagepath [file nativename [file join $::Kratos::kratos_private(Path) apps $n images] ]
        set writeModelPartEvent $n
        append writeModelPartEvent "::write"
        append writeModelPartEvent "::writeModelPartEvent"
        set writeParametersEvent $n
        append writeParametersEvent "::write"
        append writeParametersEvent "::writeParametersEvent"
        set writeCustomEvent $n
        append writeCustomEvent "::write"
        append writeCustomEvent "::writeCustomFilesEvent"
        set writeValidateEvent $n
        append writeValidateEvent "::write"
        append writeValidateEvent "::writeValidateEvent"
        set prefix ""
        set public 0
        set is_tool 0

        set properties [dict create ]
    }
    
    method activate { } {apps::ActivateApp_do [self]}
    
    method getPrefix { } {variable prefix; return $prefix}
    method setPrefix { p } {variable prefix; set prefix $p}
    
    method getPublicName { } {variable publicname; return $publicname}
    method setPublicName { pn } {variable publicname; set publicname $pn}
    
    method getName { } {variable name; return $name}
    
    method getIcon { } {return [my getImagePath logo.png]}
    method getImagePath { imgName } {variable imagepath; return [file nativename [file join $imagepath $imgName] ]}
    
    method getWriteModelPartEvent { } {variable writeModelPartEvent; return $writeModelPartEvent}
    
    method getWriteParametersEvent { } {variable writeParametersEvent; return $writeParametersEvent}
    
    method getWriteCustomEvent { } {variable writeCustomEvent; return $writeCustomEvent}

    method getValidateWriteEvent { } {variable writeValidateEvent; return $writeValidateEvent}
    
    method executexml { func args } {
        variable name
        set f ::${name}::xml::${func}
        if {[info procs $f] ne ""} {$f {*}$args}
        }
    method execute { func args } {
        variable name
        set f ::${name}::${func}
        if {[info procs $f] ne ""} {$f {*}$args}
        }
    
    method setPublic {v} {variable public; set public $v}
    method isPublic { } {variable public; return $public}
    
    method setIsTool {v} {variable is_tool; set is_tool $v}
    method isTool { } {variable is_tool; return $is_tool}
    
    method getKratosApplicationName { } {return [::${name}::GetAttribute kratos_name]}

    method setProperties {props} {variable properties; set properties $props}
    method getProperty {n} {variable properties; if {[dict exists $properties $n]} {return [dict get $properties $n]}}
    method getProperties {} {variable properties; return $properties}
    method getPermission {n} {variable properties; if {[dict exists $properties permissions $n]} {return [dict get $properties permissions $n]} }
    method getPermissions {} {variable properties; return [dict get $properties permissions]} 
    method getUniqueName {n} {variable properties; if {[dict exists $properties unique_names $n]} {return [dict get $properties unique_names $n]} }
    method getUniqueNames {} {variable properties; return [dict get $properties unique_names} 
    method getWriteProperty {n} {variable properties; if {[dict exists $properties write $n]} {return [dict get $properties write $n]} }
    method getWriteProperties {} {variable properties; return [dict get $properties write} 
}
proc apps::ActivateApp_do {app} {
    # set ::Kratos::must_quit 0
    set app_name [$app getName]
    set dir [file join $::Kratos::kratos_private(Path) apps $app_name]
    set app_definition_file [file join $dir app.json]
    if {[file exists $app_definition_file]} {
        set props [Kratos::ReadJsonDict $app_definition_file]
        $app setProperties $props

        # Load app dependences
        if {[dict exists $props requeriments apps]} {
            foreach app_id [dict get $props requeriments apps] {
                apps::LoadAppById $app_id
            }
        }

        # Then load the app files, so we can overwrite functions loaded in dependences
        if {[dict exists $props script_files]} {
            foreach source_file [dict get $props script_files] {
                set fileName [file join $dir $source_file]
                apps::loadAppFile $fileName
            }
        }
        
        if {[dict exists $props permissions wizard]} {if {[write::isBooleanTrue [dict get $props permissions wizard]]} { Kratos::LoadWizardFiles }}
        if {[dict exists $props start_script]} {eval [dict get $props start_script] $app}
        apps::ApplyAppPreferences $app
    } else {
        W "MISSING app.json file for app $app_name"
        set fileName [file join $dir start.tcl]
        apps::loadAppFile $fileName
    }
    
    if {[gid_themes::GetCurrentTheme] eq "GiD_black"} {
        set gid_groups_conds::imagesdirList [lsearch -all -inline -not -exact $gid_groups_conds::imagesdirList [list [file join $dir images]]]
        gid_groups_conds::add_images_dir [file join $dir images Black]
    } 
    gid_groups_conds::add_images_dir [file join $dir images]
}

proc apps::ApplyAppPreferences {app} {
    if {[write::isBooleanTrue [$app getPermission open_tree]]} {set spdAux::TreeVisibility 1} {set spdAux::TreeVisibility 0}
    if {[$app getProperty dimensions] ne ""} { set ::Model::ValidSpatialDimensions [$app getProperty dimensions] }
}

proc apps::loadAppFile {fileName} {uplevel #0 [list source $fileName]}

apps::Init
