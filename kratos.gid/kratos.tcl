##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval Kratos {
    variable kratos_private
    variable must_quit
    variable must_write_calc_data
    variable must_exist_calc_data
}

proc Kratos::Start { } {
    if {[GidUtils::VersionCmp "14.1.2d"] <0 } {
        set dir [file dirname [info script]]
        uplevel 1 [list source [file join $dir scripts DeprecatedEvents.tcl]]
    } {
        Kratos::RegisterGiDEvents
    }
}


proc ChangeVariables { {groupname ""} } {
    if { [GidUtils::ExistsWindow PREFERENCES] } {
       GidUtils::CloseWindow PREFERENCES
    }
    set xmlfile Preferences.xml
    if { [info exists CreateWidgetsFromXml::fileread($xmlfile)] } {
        if { [GetCurrentPrePostMode] == "POST" } {
            CreateWidgetsFromXml::IniWin $CreateWidgetsFromXml::fileread($xmlfile) $groupname "ChangeVariables" "" 
        } else {
            CreateWidgetsFromXml::IniWin $CreateWidgetsFromXml::fileread($xmlfile) $groupname "ChangeVariables" {general kratos_preferences graphical meshing import_export fonts grid postprocess_main} 
        }
    } else {
        if { [GetCurrentPrePostMode] == "POST" } {
            CreateWidgetsFromXml::ReadXmlFile Preferences.xml $groupname "ChangeVariables"
        } else {
            CreateWidgetsFromXml::ReadXmlFile Preferences.xml $groupname "ChangeVariables" 1 {general kratos_preferences graphical meshing import_export fonts grid postprocess_main}
            
        }
    }    
}

proc Kratos::RegisterGiDEvents { } {
    # Unregister previous events
    GiD_UnRegisterEvents PROBLEMTYPE Kratos
    
    # Init / Load
    GiD_RegisterEvent GiD_Event_InitProblemtype Kratos::Event_InitProblemtype PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_LoadModelSPD Kratos::Event_LoadModelSPD PROBLEMTYPE Kratos

    # Preferences window
    #GiD_RegisterPluginPreferencesProc Kratos::Event_ModifyPreferencesWindow  
    
    # Groups / Layers
    GiD_RegisterEvent GiD_Event_AfterRenameGroup Kratos::Event_AfterRenameGroup PROBLEMTYPE Kratos
    
    # Mesh
    GiD_RegisterEvent GiD_Event_BeforeMeshGeneration Kratos::Event_BeforeMeshGeneration PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_AfterMeshGeneration Kratos::Event_AfterMeshGeneration PROBLEMTYPE Kratos
    
    # Write - Calculation
    GiD_RegisterEvent GiD_Event_AfterWriteCalculationFile Kratos::Event_AfterWriteCalculationFile PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_BeforeRunCalculation Kratos::Event_BeforeRunCalculation PROBLEMTYPE Kratos
    
    # Postprocess
    GiD_RegisterEvent GiD_Event_InitGIDPostProcess Kratos::Event_InitGIDPostProcess PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_EndGIDPostProcess Kratos::Event_EndGIDPostProcess PROBLEMTYPE Kratos
    
    # Save
    GiD_RegisterEvent GiD_Event_BeforeSaveGIDProject Kratos::Event_BeforeSaveGIDProject PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_SaveModelSPD Kratos::Event_SaveModelSPD PROBLEMTYPE Kratos
    
    # Extra
    GiD_RegisterEvent GiD_Event_ChangedLanguage Kratos::Event_ChangedLanguage PROBLEMTYPE Kratos
    
    # End
    GiD_RegisterEvent GiD_Event_EndProblemtype Kratos::Event_EndProblemtype PROBLEMTYPE Kratos
}

proc Kratos::Event_InitProblemtype { dir } {
    W "init called"
    W [GidUtils::GetStackTrace]
    variable kratos_private
    variable must_quit
    variable must_write_calc_data
    variable must_exist_calc_data
    set must_quit 0
    set must_write_calc_data 1
    set must_exist_calc_data 1
    unset -nocomplain kratos_private
    set kratos_private(Path) $dir ;#to know where to find the files
    Kratos::InitGlobalVariables

    if { [GidUtils::VersionCmp $kratos_private(CheckMinimumGiDVersion)] < 0 } {
        W "Warning: kratos interface requires GiD $kratos_private(CheckMinimumGiDVersion) or later."
        if { [GidUtils::VersionCmp 14.0.0] < 0 } {
            W "If you are still using a GiD version 13.1.7d or later, you can still use most of the features, but think about upgrading to GiD 14." 
        } {
            W "If you are using an official version of GiD 14, we recommend to use the latest developer version"
        }
        W "Download it from: https://www.gidhome.com/download/developer-versions/"
    }

    Kratos::LoadCommonScripts
    
    #append to auto_path only folders that must include tcl packages (loaded on demand with package require mechanism)
    if { [lsearch -exact $::auto_path [file join $kratos_private(Path) scripts]] == -1 } {
        lappend ::auto_path [file join $kratos_private(Path) scripts]
    }
    
    foreach filename {Writing.tcl WriteHeadings.tcl WriteMaterials.tcl WriteNodes.tcl
        WriteElements.tcl WriteConditions.tcl WriteConditionsByGiDId.tcl WriteConditionsByUniqueId.tcl
        WriteProjectParameters.tcl WriteSubModelPart.tcl} {
        uplevel 1 [list source [file join $kratos_private(Path) scripts Writing $filename]]
    }

    foreach filename {Utils.tcl Logs.tcl Applications.tcl spdAuxiliar.tcl Menus.tcl Deprecated.tcl} {
        uplevel 1 [list source [file join $kratos_private(Path) scripts $filename]]
    }
    foreach filename {ApplicationMarketWindow.tcl CommonProcs.tcl TreeInjections.tcl MdpaImportMesh.tcl} {
        uplevel 1 [list source [file join $kratos_private(Path) scripts Controllers $filename]]
    }
    foreach filename {Model.tcl Entity.tcl Parameter.tcl Topology.tcl Solver.tcl ConstitutiveLaw.tcl Condition.tcl Element.tcl Material.tcl SolutionStrategy.tcl Process.tcl} {
        uplevel 1 [list source [file join $kratos_private(Path) scripts Model $filename]]
    }
    foreach filename {SimpleXMLViewer.tcl FileManager.tcl } {
        uplevel 1 [list source [file join $kratos_private(Path) libs $filename]]
    }

    Kratos::LogInitialData
    set spdAux::ProjectIsNew 0
    Kratos::load_gid_groups_conds
    Kratos::LoadEnvironment
    Kratos::UpdateMenus
    gid_groups_conds::SetProgramName $kratos_private(Name)
    gid_groups_conds::SetLibDir [file join $kratos_private(Path) exec]
    set spdfile [file join $kratos_private(Path) kratos_default.spd]
    if {[llength [info args {gid_groups_conds::begin_problemtype}]] eq 4} {
        gid_groups_conds::begin_problemtype $spdfile [Kratos::GiveKratosDefaultsFile] ""
    } {
        gid_groups_conds::begin_problemtype $spdfile [Kratos::GiveKratosDefaultsFile] "" 0
    }
    if {[gid_themes::GetCurrentTheme] eq "GiD_black"} {
        set gid_groups_conds::imagesdirList [lsearch -all -inline -not -exact $gid_groups_conds::imagesdirList [list [file join [file dirname $spdfile] images]]]
        gid_groups_conds::add_images_dir [file join [file dirname $spdfile] images Black]
        gid_groups_conds::add_images_dir [file join [file dirname $spdfile] images]
    }
    spdAux::processIncludes
    spdAux::parseRoutes
    update
    spdAux::LoadModelFiles
    gid_groups_conds::close_all_windows
    #kike: the problem here is that the model.spd with the information of the application
    #was not loaded because is invoked by a posterior event. I don't know really why is working apparently well !!
    set activeapp_dom [spdAux::SetActiveAppFromDOM]
    if { $activeapp_dom == "" } {
        #open a window to allow the user select the app
        after 500 [list spdAux::CreateWindow]
    }
}
proc Kratos::InitGlobalVariables {} {
    variable kratos_private
    
    set kratos_private(DevMode) "release" ; #can be dev or release
    set kratos_private(MenuItems) [dict create]
    set kratos_private(RestoreVars) [list ]
    set kratos_private(LogFilename) ""
    set kratos_private(Log) [list ]
    set kratos_private(UseWizard) 0
    array set kratos_private [ReadProblemtypeXml [file join $kratos_private(Path) kratos.xml] Infoproblemtype {Name Version CheckMinimumGiDVersion}]
}

proc Kratos::LoadCommonScripts { } {
    variable kratos_private

}

proc Kratos::Event_LoadModelSPD { filespd } {
    variable kratos_private

    # Dont open the init window. Saved models have already app and dimension
    set spdAux::must_open_init_window 0

    set filedir [file dirname $filespd]
    if {[file nativename $kratos_private(Path)] eq [file nativename $filedir]} {
        set spdAux::ProjectIsNew 0
    } else {
        set spdAux::ProjectIsNew 1
    }
    gid_groups_conds::close_all_windows
    update
    if { ![file exists $filespd] } { return }
    
    # Need transform? Get PT version
    set versionPT [gid_groups_conds::give_data_version]
    set kratos_private(problemtype_version) $versionPT
    # Open manually the spd file to get the version and the basic information
    set doc_new [gid_groups_conds::open_XML_file_gzip $filespd]
    set root [$doc_new documentElement]
    set versionData [$root @version]
    if { [package vcompare $versionPT $versionData] == 1 } {
        set activeapp_node [$root selectNodes "//hiddenfield\[@n='activeapp'\]"]
        if {$activeapp_node ne ""} {
            set activeapp [get_domnode_attribute $activeapp_node v]
        } else {
            W "Unable to get the active application"
            return ""   
        }
        set nd [ [$root selectNodes "value\[@n='nDim'\]"] getAttribute v]
        spdAux::LoadIntervalGroups $root
        spdAux::LoadModelFiles $root
        after idle Kratos::upgrade_problemtype $filespd $nd $activeapp
    } else {
        gid_groups_conds::open_spd_file $filespd
        customlib::UpdateDocument
        spdAux::LoadModelFiles
        spdAux::LoadIntervalGroups
        spdAux::reactiveApp
        spdAux::OpenTree
    }
}

proc Kratos::Event_EndProblemtype { } {
    if {![GidUtils::VersionCmp "14.1.2d"] <0 } {
        GiD_UnRegisterEvents PROBLEMTYPE Kratos
    }
    if {[array exists ::Kratos::kratos_private]} {
        Kratos::RestoreVariables
        Kratos::DestroyWindows
        spdAux::EndRefreshTree
        Kratos::RegisterEnvironment
        Model::DestroyEverything
        Kratos::EndCreatePreprocessTBar
        gid_groups_conds::end_problemtype [Kratos::GiveKratosDefaultsFile]
        unset -nocomplain ::Kratos::kratos_private
    }
}

proc Kratos::WriteCalculationFilesEvent { {filename ""} } {
    if {$filename eq ""} {
        if {[GiD_Info Project Modelname] eq "UNNAMED"} {
            error "Save your model first"
        } {
            set filename [file join [GiD_Info Project Modelname].gid [Kratos::GetModelName].dat]
        }
    }
    FileSelector::CopyFilesIntoModel [file dirname $filename]
    write::Init
    set errcode [::write::writeEvent $filename]
    if {$errcode} {
        ::GidUtils::SetWarnLine "Error writing mdpa or json"
    } else {
        ::GidUtils::SetWarnLine "MDPA and JSON written OK"
    }
    return $errcode
}


proc Kratos::RestoreVariables { } {
    variable kratos_private
    
    if {[info exists kratos_private(RestoreVars)]} {
        foreach {k v} $kratos_private(RestoreVars) {
            set $k $v
        }
    }
    set kratos_private(RestoreVars) [list ]
}

proc Kratos::AddRestoreVar {varName} {
    variable kratos_private
    if {[info exists $varName]} {
        set val [set $varName]   
        lappend kratos_private(RestoreVars) $varName $val
    }
}

proc Kratos::LoadWizardFiles { } {
    set ::Kratos::kratos_private(UseWizard) 1
    package require gid_smart_wizard
    Kratos::UpdateMenus
}

proc Kratos::SwitchMode {} {
    variable kratos_private
    if {$kratos_private(DevMode) eq "dev"} {
        set kratos_private(DevMode) "release"
    }  {
        set kratos_private(DevMode) "dev"
    }
    Kratos::RegisterEnvironment
    #W "Registrado $kratos_private(DevMode)"
    Kratos::UpdateMenus
    spdAux::RequestRefresh
}

proc Kratos::GetPreferencesFilePath { } {
    variable kratos_private
    set dir_name [file dirname [GiveGidDefaultsFile]]
    set file_name $kratos_private(Name)Vars.txt
    if { $::tcl_platform(platform) == "windows" } {
        return [file join $dir_name $file_name]
    } else {
        return [file join $dir_name .$file_name]
    }
}

proc Kratos::RegisterEnvironment { } {
    variable kratos_private
    set varsToSave [list DevMode]
    set preferences [dict create]
    if {[info exists kratos_private(DevMode)]} {
        dict set preferences DevMode $kratos_private(DevMode)
        #gid_groups_conds::set_preference DevMode $kratos_private(DevMode)
    }
    if {[llength [dict keys $preferences]] > 0} {
        set fp [open [Kratos::GetPreferencesFilePath] w]
        if {[catch {set data [puts $fp [write::tcl2json $preferences]]} ]} {W "Problems saving user prefecences"; W $data}
        close $fp
    }
}

proc Kratos::LoadEnvironment { } {
    variable kratos_private
    #set kratos_private(DevMode) [gid_groups_conds::get_preference DevMode releasedefault]
    set data ""
    set syspath HOME
    if {$::tcl_platform(platform) eq "windows"} {set syspath APPDATA}
    catch {
        set fp [open [Kratos::GetPreferencesFilePath] r]
        set data [read $fp]
        close $fp
    }
    foreach {k v} [write::json2dict $data] {
        set kratos_private($k) $v
    }
}

proc Kratos::load_gid_groups_conds {} {  
    package require customlib_extras ;#this require also customLib
    package require customlib_native_groups
}

proc Kratos::GiveKratosDefaultsFile {} {
    variable kratos_private
    set dir_name [file dirname [GiveGidDefaultsFile]]
    set file_name $kratos_private(Name)$kratos_private(Version).ini
    if { $::tcl_platform(platform) == "windows" } {
        return [file join $dir_name $file_name]
    } else {
        return [file join $dir_name .$file_name]
    }
}

proc Kratos::upgrade_problemtype {spd_file dim app_id} {
    if {[GiDVersionCmp 14.1.1d] < 0} { W "The minimum GiD version for a transform is '14.1.1d'\n Click Ok to try it anyway" }
    set w [dialogwin_snit .gid._ask -title [_ "Action"] -entrytext \
            [_ "The model needs to be upgraded. Do you want to upgrade to new version?"]]
    set action [$w createwindow]
    destroy $w
    if { $action < 1 } { return }
    
    customlib::UpdateDocument
    spdAux::SetSpatialDimmension $dim
    apps::setActiveApp $app_id

    gid_groups_conds::transform_problemtype $spd_file
    #GiD_Process escape escape escape escape Data Defaults TransfProblem $project

    
    spdAux::LoadModelFiles
    spdAux::LoadIntervalGroups
}



proc Kratos::Event_BeforeMeshGeneration {elementsize} {
    foreach group [spdAux::GetAppliedGroups] {
        GiD_Process Mescape Meshing MeshCriteria Mesh Lines {*}[GiD_EntitiesGroups get $group lines] escape escape escape
        GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}[GiD_EntitiesGroups get $group surfaces] escape escape
    }
    # GiD_Set ForceMesh(Points) 1
    # GiD_Set ForceMesh(Lines) 1
    # GiD_Set ForceMesh(Surfaces) 1
    set ret ""
    set ret [apps::ExecuteOnCurrentApp BeforeMeshGeneration $elementsize]
    return $ret
}

proc Kratos::Event_AfterMeshGeneration {fail} {
    apps::ExecuteOnCurrentApp AfterMeshGeneration $fail
}

proc Kratos::Event_AfterRenameGroup { oldname newname } {
    spdAux::RenameIntervalGroup $oldname $newname
}

proc Kratos::Event_InitGIDPostProcess {} {
    gid_groups_conds::close_all_windows
    gid_groups_conds::open_post check_default
}

proc Kratos::Event_EndGIDPostProcess {} {
    gid_groups_conds::close_all_windows
    if {$::spdAux::TreeVisibility} {
        gid_groups_conds::open_conditions check_default
        gid_groups_conds::open_conditions menu
    }
    ::Kratos::CreatePreprocessModelTBar
}

proc Kratos::Event_BeforeRunCalculation { batfilename basename dir problemtypedir gidexe args } {
    set run 1
    
    catch {
        set paralleltype [write::getValue ParallelType]
        if {$paralleltype eq "MPI"} {set run 0}
    }
    if {$run} {
        return ""
    } {
        return [list "-cancel-" [= "You have selected MPI parallelism system.\nInput files have been written.\nRun the MPILauncher.sh script" ]]
        
    }
    
}

proc Kratos::Event_AfterWriteCalculationFile { filename errorflag } {
    if {$Kratos::must_write_calc_data} {
        set errcode [Kratos::WriteCalculationFilesEvent $filename]
        if {$errcode} {return "-cancel-"}
    } else {
        if {$Kratos::must_exist_calc_data} {
            
        }
    }
}

proc Kratos::Event_BeforeSaveGIDProject { modelname} {
    set fail [::Kratos::CheckValidProjectName $modelname]
    
    if {$fail} {
        W [= "Wrong project name. Avoid boolean and numeric names."]
        return "-cancel-"
    }
}


proc Kratos::Event_SaveModelSPD { filespd } {
    gid_groups_conds::save_spd_file $filespd
    Kratos::RegisterEnvironment
    FileSelector::CopyFilesIntoModel [file dirname $filespd]
}


proc Kratos::Event_ChangedLanguage  { newlan } {
    Kratos::UpdateMenus
}


proc Kratos::Event_ModifyPreferencesWindow { root } {
    Kratos::ModifyPreferencesWindow $root
}

proc ::Kratos::Quicktest {example_app example_dim example_cmd} {
    apps::setActiveApp Examples
    ::Examples::LaunchExample $example_app $example_dim $example_cmd
}

proc Kratos::LogInitialData { } {
    set initial_data [dict create]
    dict set initial_data GiD_Version [GiD_Info gidversion]
    dict set initial_data Problemtype_Git_Hash "68418871cff2b897f7fb9176827871b339fe5f91"
    
    Kratos::Log [write::tcl2json $initial_data]
}

Kratos::Start 