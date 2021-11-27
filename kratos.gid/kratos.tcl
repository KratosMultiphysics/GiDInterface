##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::Kratos {
    variable kratos_private

    variable must_write_calc_data
    variable must_exist_calc_data

    variable tmp_init_mesh_time
    variable namespaces
}

# Hard minimum GiD Version is 14
if {[GidUtils::VersionCmp "14.0.1"] >=0 } {
    if {[GidUtils::VersionCmp "14.1.1"] >=0 } {
        # GiD Developer versions
        proc GiD_Event_InitProblemtype { dir } {
            Kratos::Event_InitProblemtype $dir
        }
    } {
        # GiD Official versions
        proc InitGIDProject { dir } {
            Kratos::Event_InitProblemtype $dir
        }
    }
} {
    # GiD versions previous to 14 are no longer allowed
    # As we dont register the event InitProblemtype, the rest of events are also unregistered
    # So no chance to open anything in GiD 13.x or earlier
    WarnWin "The minimum GiD Version for Kratos is 14 or later \nUpdate at gidhome.com"
}

proc Kratos::Events { } {
    variable kratos_private

    # Recommended GiD Version is the latest developer always
    if {[GidUtils::VersionCmp "14.1.4d"] <0 } {
        set dir [file dirname [info script]]
        uplevel #0 [list source [file join $kratos_private(Path) scripts DeprecatedEvents.tcl]]
        Kratos::ModifyPreferencesWindowOld
    } {
        Kratos::RegisterGiDEvents
    }
}

proc Kratos::RegisterGiDEvents { } {
    # Unregister previous events
    GiD_UnRegisterEvents PROBLEMTYPE Kratos

    # Init / Load
    # After new gid project
    #GiD_RegisterEvent GiD_Event_InitProblemtype Kratos::Event_InitProblemtype PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_LoadModelSPD Kratos::Event_LoadModelSPD PROBLEMTYPE Kratos

    # Groups / Layers
    GiD_RegisterEvent GiD_Event_AfterRenameGroup Kratos::Event_AfterRenameGroup PROBLEMTYPE Kratos

    # Mesh
    GiD_RegisterEvent GiD_Event_BeforeMeshGeneration Kratos::Event_BeforeMeshGeneration PROBLEMTYPE Kratos
    GiD_RegisterEvent GiD_Event_MeshProgress Kratos::Event_MeshProgress PROBLEMTYPE Kratos
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

    # Preferences window
    GiD_RegisterPluginPreferencesProc Kratos::Event_ModifyPreferencesWindow
    if {[GidUtils::VersionCmp "15.0.0"] >=0 } {CreateWidgetsFromXml::ClearCachePreferences}
}

proc Kratos::Event_InitProblemtype { dir } {
    variable kratos_private

    # Init Kratos problemtype global vars with default values
    Kratos::InitGlobalVariables $dir

    # Load all common tcl files (not the app ones)
    Kratos::LoadCommonScripts

    # GiD Versions earlier than recommended get a message
    Kratos::WarnAboutMinimumRecommendedGiDVersion

    # Register the rest of events
    Kratos::Events

    # Start the log and register the initial information
    Kratos::LogInitialData

    # Problemtype libraries as CustomLib
    Kratos::LoadProblemtypeLibraries

    # Load the Kratos problemtype global and user environment (stored preferences)
    Kratos::LoadEnvironment

    # Customize GiD menus to add the Kratos entry
    Kratos::UpdateMenus

    # Start the spd as new project. Mandatory even if we are opening an old case, because this loads the default spd for the future transform
    spdAux::StartAsNewProject

    # Open the App selection window. It's delayed to wait if GiD calls the Event_LoadModelSPD (open a case instead of new)
    set activeapp_dom [spdAux::SetActiveAppFromDOM]
    if { $activeapp_dom == "" } {
        #open a window to allow the user select the app
        after 500 [list spdAux::CreateWindow]
    }
}

proc Kratos::InitGlobalVariables {dir} {
    variable kratos_private

    # clean and start private variables array
    unset -nocomplain kratos_private
    set kratos_private(Path) $dir

    # This variables allows us to Write only and to run only
    variable must_write_calc_data
    set must_write_calc_data 1
    variable must_exist_calc_data
    set must_exist_calc_data 1

    # User environment (stored for future sessions)
    # DevMode in preferences window
    set kratos_private(DevMode) "release" ; #can be dev or release
    # Echo level for messaging
    set kratos_private(echo_level) 0
    # indent in mdpa files  | 0 ASCII unindented | 1 ASCII indented pretty
    set kratos_private(mdpa_format) 1
    # kratos debug env for VSCode debug
    set kratos_private(debug_folder) ""
    # Version of the kratos executable
    set kratos_private(exec_version) "dev"
    # Allow logs -> 0 No | 1 Only local | 2 Share with dev team
    set Kratos::kratos_private(allow_logs) 1
    # git hash of the problemtype
    set Kratos::kratos_private(problemtype_git_hash) 0
    # Place were the logs will be placed
    set Kratos::kratos_private(model_log_folder) ""
    # Check exec/launch.json
    set Kratos::kratos_private(launch_configuration) "local"

    # Variable to store the Kratos menu items
    set kratos_private(MenuItems) [dict create]
    # List of variables to store/load in user preferences
    set kratos_private(RestoreVars) [list ]
    # Filepath of the log
    set kratos_private(LogFilename) ""
    # Log message list itself
    set kratos_private(Log) [list ]
    # Are we using wizard
    set kratos_private(UseWizard) 0
    # Project New 1/0
    set kratos_private(ProjectIsNew) 1
    # Is using files modules
    set kratos_private(UseFiles) 0
    # Variables from the problemtype definition (kratos.xml)
    array set kratos_private [ReadProblemtypeXml [file join $kratos_private(Path) kratos.xml] Infoproblemtype {Name Version CheckMinimumGiDVersion}]

    variable namespaces
    set namespaces [list ]
}

proc Kratos::LoadCommonScripts { } {
    variable kratos_private

    # append to auto_path only folders that must include tcl packages (loaded on demand with package require mechanism)
    if { [lsearch -exact $::auto_path [file join $kratos_private(Path) scripts]] == -1 } {
        lappend ::auto_path [file join $kratos_private(Path) scripts]
    }
    if { [lsearch -exact $::auto_path [file join $kratos_private(Path) libs]] == -1 } {
        lappend ::auto_path [file join $kratos_private(Path) libs]
    }

    # Writing common scripts
    foreach filename {Writing.tcl WriteHeadings.tcl WriteMaterials.tcl WriteNodes.tcl
        WriteElements.tcl WriteConditions.tcl WriteConditionsByGiDId.tcl WriteConditionsByUniqueId.tcl
        WriteProjectParameters.tcl WriteSubModelPart.tcl WriteProcess.tcl} {
        uplevel #0 [list source [file join $kratos_private(Path) scripts Writing $filename]]
    }
    # Common scripts
    foreach filename {Utils.tcl Applications.tcl spdAuxiliar.tcl Menus.tcl Deprecated.tcl Logs.tcl} {
        uplevel #0 [list source [file join $kratos_private(Path) scripts $filename]]
    }
    # Common controllers
    foreach filename {ApplicationMarketWindow.tcl ExamplesWindow.tcl CommonProcs.tcl PreferencesWindow.tcl TreeInjections.tcl MdpaImportMesh.tcl Drawer.tcl ImportFiles.tcl} {
        uplevel #0 [list source [file join $kratos_private(Path) scripts Controllers $filename]]
    }
    # Model class
    foreach filename {Model.tcl Entity.tcl Parameter.tcl Topology.tcl Solver.tcl ConstitutiveLaw.tcl Condition.tcl Element.tcl Material.tcl SolutionStrategy.tcl Process.tcl} {
        uplevel #0 [list source [file join $kratos_private(Path) scripts Model $filename]]
    }
    # Libs
    foreach filename {SimpleXMLViewer.tcl} {
        uplevel #0 [list source [file join $kratos_private(Path) libs $filename]]
    }
}

proc Kratos::Event_LoadModelSPD { filespd } {
    after 1 [list Kratos::LoadModelSPD $filespd]
}

proc Kratos::LoadModelSPD { filespd } {
    variable kratos_private

    # Event called if a model exists, so close all the windows while tree isn't loaded
    gid_groups_conds::close_all_windows
    update

    # Dont open the init window. Saved models have already app and dimension
    set spdAux::must_open_init_window 0

    # Need this check for old gid compatibility. Sometimes this event was called by mistake.
    Kratos::CheckProjectIsNew $filespd

    # If the spd file does not exist, sorry
    if { ![file exists $filespd] } { WarnWin "Could not find the spd file\n$filespd" ;return }

    #### TRANSFORM SECTION ####
    # Need transform? Define concepts: Model spd = old version || Problemtype spd = new version || Result of transform == Valid spd
    # Get PT version
    set versionPT [gid_groups_conds::give_data_version]
    set kratos_private(problemtype_version) $versionPT
    # Open manually the spd file to get the version and the basic information
    set old_doc [gid_groups_conds::open_XML_file_gzip $filespd]
    set old_root [$old_doc documentElement]
    set old_versionData [$old_root @version]
    set version_data [dict create model_version $old_versionData ]
    Kratos::Log "Load model -> [write::tcl2json $version_data]"

    # Compare the version number
    if { [package vcompare $versionPT $old_versionData] != 0 } {
        # If the spd versions are different, transform (no matter which is greater)

        # Do the transform
        after idle [list Kratos::TransformProblemtype $old_root ${filespd}]

    } else {
        # If the spd versions are equal, partyhard

        # Load the old spd
        gid_groups_conds::open_spd_file $filespd

        # Refresh the cache
        customlib::UpdateDocument

        # Load default files (if any) (file selection values store the filepaths in the spd)
        spdAux::LoadModelFiles

        # Load default intervals (if any)
        spdAux::LoadIntervalGroups

        # Reactive the previous app
        spdAux::reactiveApp

        apps::ExecuteOnCurrentApp LoadModelEvent $filespd

        # Open the tree
        spdAux::OpenTree

        after 500 {set ::Kratos::kratos_private(model_log_folder) [file join [GiD_Info Project ModelName].gid Logs]}
    }

}

proc Kratos::Event_EndProblemtype { } {
    Kratos::Log "End session"
    # New event system need an unregister
    if {[GidUtils::VersionCmp "14.1.4d"] >= 0 } {
        GiD_UnRegisterEvents PROBLEMTYPE Kratos
        GiD_UnRegisterPluginPreferencesProc Kratos::Event_ModifyPreferencesWindow
    }
    if {[array exists ::Kratos::kratos_private]} {
        # Close the log and moves them to the folder
        Kratos::FlushLog

        # Restore GiD variables that were modified by kratos and must be restored (maybe mesher)
        Kratos::RestoreVariables

        # Close all kratos windows
        Kratos::DestroyWindows

        # Stop the tree refresh loop
        spdAux::EndRefreshTree

        # Save user preferences
        Kratos::RegisterEnvironment

        # Delete all instances of model objects
        Model::DestroyEverything

        # Close customlib things
        gid_groups_conds::end_problemtype [Kratos::GiveKratosDefaultsFile]

        # Clear private global variable
        unset -nocomplain ::Kratos::kratos_private

    }
    Drawer::UnregisterAll

    # Clear namespaces
    Kratos::DestroyNamespaces
}


proc Kratos::RestoreVariables { } {
    variable kratos_private

    # Restore GiD variables that kratos modified (maybe the mesher...)
    if {[info exists kratos_private(RestoreVars)]} {
        foreach {k v} $kratos_private(RestoreVars) {
            # W "$k $v"
            set $k $v
        }
    }
    set kratos_private(RestoreVars) [list ]
}

proc Kratos::AddRestoreVar {varName} {
    variable kratos_private

    # Add a variable (and value) to the list of variables that will be restored before exiting
    if {[info exists $varName]} {
        set val [set $varName]
        lappend kratos_private(RestoreVars) $varName $val
    }
}

proc Kratos::LoadWizardFiles { } {
    variable kratos_private
    # Load the wizard package
    set kratos_private(UseWizard) 1
    package require gid_smart_wizard
    Kratos::UpdateMenus
}
proc Kratos::LoadImportFiles { } {
    variable kratos_private
    # Load the wizard package
    set kratos_private(UseFiles) 1
    package require gid_pt_file_manager
    Kratos::UpdateMenus
}

proc Kratos::TransformProblemtype {old_dom old_filespd} {
    # Check if current problemtype allows transforms
    if {[GiDVersionCmp 14.1.1d] < 0} { W "The minimum GiD version for a transform is '14.1.1d'\n Click Ok to try it anyway (You may lose data)" }

    # set ::Kratos_AskToTransform to 0 to not not ask if transform and old model, and automatically act like ok was pressed (e.g. to automatize in batch)
    if { ![info exists ::Kratos_AskToTransform] || $::Kratos_AskToTransform } {
        # Ask the user if it's ready to tranform
        set w [dialogwin_snit .gid._ask -title [_ "Transform"] -entrytext [_ "The model needs to be upgraded. Do you want to upgrade to new version? You can lose data"]]
        set action [$w createwindow]
        destroy $w
        if { $action < 1 } { return }
    }

    # Get the old app
    set old_activeapp_node [$old_dom selectNodes "//hiddenfield\[@n='activeapp'\]"]
    if {$old_activeapp_node ne ""} {
        set old_activeapp [get_domnode_attribute $old_activeapp_node v]
    } else {
        WarnWin "Unable to get the active application in your model"
        return ""
    }
    # Get the old dimmension
    set old_nd [ [$old_dom selectNodes "value\[@n='nDim'\]"] getAttribute v]

    # Load the previous intervals
    spdAux::LoadIntervalGroups $old_dom

    # Load the previous files (file selection values store the filepaths in the spd)
    spdAux::LoadModelFiles $old_dom

    # Refresh the cache
    customlib::UpdateDocument

    # Prepare the new spd spatial dimmension
    spdAux::SetSpatialDimmension $old_nd

    # Prepare the new spd (and model) active application
    apps::setActiveApp $old_activeapp
    apps::ExecuteOnCurrentXML CustomTree ""

    # Call to customlib transform and pray
    gid_groups_conds::transform_problemtype $old_filespd

    # Load default files (if any) (file selection values store the filepaths in the spd)
    spdAux::LoadModelFiles

    # Load default intervals (if any)
    spdAux::LoadIntervalGroups
}

proc Kratos::Event_BeforeMeshGeneration {elementsize} {
    # Prepare things before meshing
    variable tmp_init_mesh_time
    set inittime [clock seconds]
    set tmp_init_mesh_time $inittime
    Kratos::Log "Mesh BeforeMeshGeneration start"
    GiD_Process Mescape Meshing MeshCriteria NoMesh Lines 1:end escape escape escape
    GiD_Process Mescape Meshing MeshCriteria NoMesh Surfaces 1:end escape escape escape
    GiD_Process Mescape Meshing MeshCriteria NoMesh Volumes 1:end escape escape escape

    # We need to mesh every line and surface assigned to a group that appears in the tree
    foreach group [spdAux::GetAppliedGroups] {
        GiD_Process Mescape Meshing MeshCriteria Mesh Lines {*}[GiD_EntitiesGroups get $group lines] escape escape escape
        GiD_Process Mescape Meshing MeshCriteria Mesh Surfaces {*}[GiD_EntitiesGroups get $group surfaces] escape escape escape
        GiD_Process Mescape Meshing MeshCriteria Mesh Volumes {*}[GiD_EntitiesGroups get $group volumes] escape escape escape
    }
    # Maybe the current application needs to do some extra job
    set ret [apps::ExecuteOnCurrentApp BeforeMeshGeneration $elementsize]
    set endtime [clock seconds]
    set ttime [expr {$endtime-$inittime}]
    Kratos::Log "Mesh BeforeMeshGeneration end in [Duration $ttime]"
    return $ret
}

proc Kratos::Event_MeshProgress { total_percent partial_percents_0 partial_percents_1 partial_percents_2 partial_percents_3 n_nodes n_elems } {
    # Maybe the current application needs to do some extra job
    apps::ExecuteOnCurrentApp MeshProgress $total_percent $partial_percents_0 $partial_percents_1 $partial_percents_2 $partial_percents_3 $n_nodes n_elems
}

proc Kratos::Event_AfterMeshGeneration {fail} {
    variable tmp_init_mesh_time
    # Maybe the current application needs to do some extra job
    apps::ExecuteOnCurrentApp AfterMeshGeneration $fail
    set endtime [clock seconds]
    set ttime [expr {$endtime-$tmp_init_mesh_time}]
    Kratos::Log "Mesh end process in [Duration $ttime]"
    set mesh_data [Kratos::GetMeshBasicData]
    Kratos::Log "Mesh data -> [write::tcl2json $mesh_data]"
}

proc Kratos::Event_AfterRenameGroup { oldname newname } {
    spdAux::RenameIntervalGroup $oldname $newname
}

proc Kratos::Event_InitGIDPostProcess {} {
    # Close the tree
    gid_groups_conds::close_all_windows
    # We don't have (yet) any postprocess window
    gid_groups_conds::open_post check_default
}

proc Kratos::Event_EndGIDPostProcess {} {
    # Close all postprocess windows
    gid_groups_conds::close_all_windows
    # If the tree must be visible
    if {$::spdAux::TreeVisibility} {
        # Open the tree
        gid_groups_conds::open_conditions check_default
        gid_groups_conds::open_conditions menu
    }
    # Show the kratos toolbar
    ::Kratos::CreatePreprocessModelTBar
}

proc Kratos::Event_BeforeRunCalculation { batfilename basename dir problemtypedir gidexe args } {
    # Let's launch the Kratos rocket!
    set run 1

    catch {
        # If the user selected MPI, stop it!
        set paralleltype [write::getValue ParallelType]
        # MPI must be launched manually
        if {$paralleltype eq "MPI"} {set run 0}
    }
    if {!$run} {
        return [list "-cancel-" [= "You have selected MPI parallelism system.\nInput files have been written.\nRun the MPILauncher.sh script" ]]
    }
    set app_run_brake [apps::ExecuteOnCurrentApp BreakRunCalculation]
    if {[write::isBooleanTrue $app_run_brake]} {return "-cancel-"}

    if {[info exists Kratos::kratos_private(launch_configuration)]} {
        set launch_type $Kratos::kratos_private(launch_configuration)
        W $launch_type
    }
}

proc Kratos::Event_AfterWriteCalculationFile { filename errorflag } {
    # Only write if required
    if {$Kratos::must_write_calc_data} {
        set errcode [Kratos::WriteCalculationFilesEvent $filename]
        if {$errcode} {return "-cancel-"}
    }
}

proc Kratos::WriteCalculationFilesEvent { {filename ""} } {
    # Write the calculation files (mdpa, json...)
    if {$filename eq ""} {
        # Model must be saved
        if {[GiD_Info Project Modelname] eq "UNNAMED"} {
            error "Save your model first"
        } {
            # Prepare the filename
            set filename [file join [GiD_Info Project Modelname].gid [Kratos::GetModelName]]
        }
    }
    # The calculation process may need the files of the file selector entries inside the model folder
    if {$Kratos::kratos_private(UseFiles) eq 1} {FileSelector::CopyFilesIntoModel [file dirname $filename]}

    # Start the write configuration clean
    write::Init

    # Start the writing process
    set errcode [::write::writeEvent $filename]

    # Kindly inform the user
    if {$errcode} {
        ::GidUtils::SetWarnLine "Error writing mdpa or json"
    } else {
        ::GidUtils::SetWarnLine "MDPA and JSON written OK"
    }
    return $errcode
}

proc Kratos::Event_BeforeSaveGIDProject { modelname} {
    # There are some restrictions in the filenames
    set fail [::Kratos::CheckValidProjectName $modelname]

    if {$fail} {
        W [= "Wrong project name. Avoid boolean and numeric names."]
        return "-cancel-"
    }
}

proc Kratos::Event_SaveModelSPD { filespd } {
    # Save the spd
    gid_groups_conds::save_spd_file $filespd

    # Save user preferences
    Kratos::RegisterEnvironment

    # User files (in file selectors) copied into the model (if required)
    if {$Kratos::kratos_private(UseFiles) eq 1} {FileSelector::CopyFilesIntoModel [file dirname $filespd]}

    # Let the current app implement it's Save event
    apps::ExecuteOnCurrentApp AfterSaveModel $filespd

    # Log it
    set Kratos::kratos_private(model_log_folder) [file join [GiD_Info Project ModelName].gid Logs]
    Kratos::Log "Save model [file tail $filespd ]"

}


proc Kratos::Event_ChangedLanguage  { newlan } {
    Kratos::UpdateMenus
}

proc Kratos::Event_ModifyPreferencesWindow { root } {
    Kratos::ModifyPreferencesWindow $root
}

proc Kratos::Quicktest {example_app example_dim example_cmd} {
    # Method used in jginternational tester (check http://github.com/jginternational/kratos-gid-tester)

    # We can only test examples from the Examples app
    apps::setActiveApp Examples

    # So launch the example
    ::Examples::LaunchExample $example_app $example_dim $example_cmd

    # And close the windows
    Kratos::DestroyWindows
}

proc Kratos::AddNamespace { namespace_name } {
    variable namespaces
    lappend namespaces $namespace_name

}

proc Kratos::DestroyNamespaces { } {
    variable namespaces

    foreach name $namespaces {
        catch {namespace delete $name}
    }
    uplevel #0 [list namespace delete ::Kratos]
}