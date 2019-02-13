##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

##########################################################
#################### GiD Tcl events ######################
##########################################################
proc InitGIDProject { dir } {
    #W "InitGIDProject"
    Kratos::InitGIDProject $dir
}
proc GiD_Event_AfterNewGIDProject {} {
    # W "GiD_Event_AfterNewGIDProject"
}

# Load GiD project files (initialise XML Tdom structure)
proc GiD_Event_AfterReadGIDProject { filename } {
    #W "GiD_Event_AfterReadGIDProject"
    set name [file tail $filename]
    set spd_file [file join ${filename}.gid ${name}.spd]
    Kratos::AfterReadGIDProject $spd_file
}

proc BeforeTransformProblemType {file oldproblemtype newproblemtype} {
    # W "BeforeTransformProblemType"
}

proc AfterTransformProblemType {file oldproblemtype newproblemtype messages} {
    # W "AfterTransformProblemType"
}

proc EndGIDProject {} {
    Kratos::RestoreVariables
    Kratos::DestroyWindows
    spdAux::EndRefreshTree
    Kratos::RegisterEnvironment
    Model::DestroyEverything
    Kratos::EndCreatePreprocessTBar
    gid_groups_conds::end_problemtype [Kratos::GiveKratosDefaultsFile]
    unset -nocomplain ::Kratos::kratos_private
}

proc ChangedLanguage { newlan } {
    Kratos::UpdateMenus
}

proc InitGIDPostProcess {} {
    gid_groups_conds::close_all_windows
    gid_groups_conds::open_post check_default
}

proc EndGIDPostProcess {} {
    gid_groups_conds::close_all_windows
    if {$::spdAux::TreeVisibility} {
        gid_groups_conds::open_conditions check_default
        gid_groups_conds::open_conditions menu
    }
    ::Kratos::CreatePreprocessModelTBar
}


# Save GiD project files (save XML Tdom structure to spd file)
proc SaveGIDProject { filespd } {
    gid_groups_conds::save_spd_file $filespd
    Kratos::RegisterEnvironment
    FileSelector::CopyFilesIntoModel [file dirname $filespd]
}

proc AfterWriteCalcFileGIDProject { filename errorflag } {
    if {$Kratos::must_write_calc_data} {
        set errcode [Kratos::WriteCalculationFilesEvent $filename]
        if {$errcode} {return "-cancel-"}
    } else {
        if {$Kratos::must_exist_calc_data} {

        }
    }
}

proc GiD_Event_BeforeMeshGeneration { elementsize } {
    return [Kratos::BeforeMeshGeneration $elementsize]
}
proc AfterMeshGeneration { fail } {
    Kratos::AfterMeshGeneration $fail
}

proc BeforeRunCalculation { batfilename basename dir problemtypedir gidexe args } {
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

proc GiD_Event_BeforeSaveGIDProject { modelname} {
    set fail [::Kratos::CheckValidProjectName $modelname]

    if {$fail} {
        W [= "Wrong project name. Avoid boolean and numeric names."]
        return "-cancel-"
    }
}

proc AfterRenameGroup { oldname newname } {
    spdAux::RenameIntervalGroup $oldname $newname
}

##########################################################
#################### Kratos namespace ####################
##########################################################
namespace eval Kratos {
    variable kratos_private
    variable must_quit
    variable must_write_calc_data
    variable must_exist_calc_data
}

proc Kratos::InitGIDProject { dir } {
    variable kratos_private
    variable must_quit
    variable must_write_calc_data
    variable must_exist_calc_data
    set must_quit 0
    set must_write_calc_data 1
    set must_exist_calc_data 1
    unset -nocomplain kratos_private
    set kratos_private(Path) $dir ;#to know where to find the files
    set kratos_private(DevMode) "release" ; #can be dev or release
    set kratos_private(MenuItems) [dict create]
    set kratos_private(RestoreVars) [list ]
    array set kratos_private [ReadProblemtypeXml [file join $dir kratos.xml] Infoproblemtype {Name Version MinimumGiDVersion}]
    if { [GidUtils::VersionCmp $kratos_private(MinimumGiDVersion)] < 0 } {
        WarnWin [_ "Error: %s Interface requires GiD %s or later." $kratos_private(Name) $kratos_private(MinimumGiDVersion)]
    }

    #append to auto_path only folders that must include tcl packages (loaded on demand with package require mechanism)
    if { [lsearch -exact $::auto_path [file join $dir scripts]] == -1 } {
        lappend ::auto_path [file join $dir scripts]
    }
    # foreach filename {Writing.tcl WriteHeadings.tcl WriteMaterials.tcl WriteNodes.tcl WriteElements.tcl WriteConditions.tcl} {
    #     uplevel 1 [list source [file join $dir scripts Writing $filename]]
    # }
    foreach filename {Writing.tcl WriteHeadings.tcl WriteMaterials.tcl WriteNodes.tcl
     WriteElements.tcl WriteConditions.tcl WriteConditionsByGiDId.tcl WriteConditionsByUniqueId.tcl
     WriteProjectParameters.tcl WriteSubModelPart.tcl} {
        uplevel 1 [list source [file join $dir scripts Writing $filename]]
    }
    foreach filename {Applications.tcl spdAuxiliar.tcl Menus.tcl Deprecated.tcl} {
        uplevel 1 [list source [file join $dir scripts $filename]]
    }
    foreach filename {ApplicationMarketWindow.tcl CommonProcs.tcl TreeInjections.tcl MdpaImportMesh.tcl} {
        uplevel 1 [list source [file join $dir scripts Controllers $filename]]
    }
    foreach filename {Model.tcl Entity.tcl Parameter.tcl Topology.tcl Solver.tcl ConstitutiveLaw.tcl Condition.tcl Element.tcl Material.tcl SolutionStrategy.tcl Process.tcl} {
        uplevel 1 [list source [file join $dir scripts Model $filename]]
    }
    foreach filename {SimpleXMLViewer.tcl FileManager.tcl } {
        uplevel 1 [list source [file join $dir libs $filename]]
    }
    set kratos_private(UseWizard) 0
    set spdAux::ProjectIsNew 0
    Kratos::load_gid_groups_conds
    Kratos::LoadEnvironment
    Kratos::UpdateMenus
    gid_groups_conds::SetProgramName $kratos_private(Name)
    gid_groups_conds::SetLibDir [file join $dir exec]
    set spdfile [file join $dir kratos_default.spd]
    gid_groups_conds::begin_problemtype $spdfile [Kratos::GiveKratosDefaultsFile] "" 0
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

# Event triggered when opening a GiD model with kratos
proc Kratos::AfterReadGIDProject { filespd } {
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
        after idle [list Kratos::upgrade_problemtype $filespd $nd $activeapp]
    } else {
        gid_groups_conds::open_spd_file "$filespd"
        customlib::UpdateDocument
        spdAux::LoadModelFiles
        spdAux::LoadIntervalGroups
        spdAux::reactiveApp
        spdAux::OpenTree
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
    spdAux::ForceTreePreload
    set errcode [::write::writeEvent $filename]
    if {$errcode} {
        ::GidUtils::SetWarnLine "Error writing mdpa or json"
    } else {
        ::GidUtils::SetWarnLine "MDPA and JSON written OK"
    }
    return $errcode
}

proc Kratos::ForceRun { } {
    # validated by escolano@cimne.upc.edu
    variable must_write_calc_data
    set must_write_calc_data 0
    GiD_Process Utilities Calculate
    set must_write_calc_data 1
}

proc Kratos::RestoreVariables { } {
    variable kratos_private

    foreach {k v} $kratos_private(RestoreVars) {
        set $k $v
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

proc Kratos::DestroyWindows {} {
    gid_groups_conds::close_all_windows
    spdAux::DestroyWindow
    if {$::Kratos::kratos_private(UseWizard)} {
        smart_wizard::DestroyWindow
    }
    ::Kratos::EndCreatePreprocessTBar
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
    dict set preferences DevMode $kratos_private(DevMode)
    #gid_groups_conds::set_preference DevMode $kratos_private(DevMode)
    set fp [open [Kratos::GetPreferencesFilePath] w]
    if {[catch {set data [puts $fp [write::tcl2json $preferences]]} ]} {W "Problems saving user prefecences"; W $data}
    close $fp
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

proc Kratos::GetModelName { } {
    return [file tail [GiD_Info project ModelName]]
}

proc Kratos::load_gid_groups_conds {} {  
    package require customlib_extras ;#this require also customLib
    package require customlib_native_groups
    package require json::write
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

proc Kratos::ResetModel { } {
    foreach layer [GiD_Info layers] {
        GiD_Process 'Layers Delete $layer Yes escape escape
    }
    foreach group [GiD_Groups list] {
        if {[GiD_Groups exists $group]} {GiD_Groups delete $group}
    }
}

proc Kratos::IsModelEmpty { } {
    if {[GiD_Groups list] != ""} {return false}
    if {[GiD_Layers list] != "Layer0"} {return false}
    if {[GiD_Geometry list point 1:end] != ""} {return false}
    return true
}

proc Kratos::BeforeMeshGeneration {elementsize} {
    foreach group [GiD_Groups list] {
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

proc Kratos::AfterMeshGeneration {fail} {
    apps::ExecuteOnCurrentApp AfterMeshGeneration $fail
}

proc Kratos::CheckValidProjectName {modelname} {
    set fail 0
    set filename [file tail $modelname]
    if {[string is double $filename]} {set fail 1}
    if {[write::isBoolean $filename]} {set fail 1}
    if {$filename == "null"} {set fail 1}
    return $fail

}

proc Kratos::PrintArray {a {pattern *}} {
    # ABSTRACT:
    # Print the content of array nicely

    upvar 1 $a array
    if {![array exists array]} {
        error "\"$a\" isn't an array"
    }
    set maxl 0
    foreach name [lsort [array names array $pattern]] {
        if {[string length $name] > $maxl} {
            set maxl [string length $name]
        }
    }
    set maxl [expr {$maxl + [string length $a] + 2}]
    foreach name [lsort [array names array $pattern]] {
        set nameString [format %s(%s) $a $name]
        W "[format "%-*s = %s" $maxl $nameString $array($name)]"
    }
}

proc ::Kratos::Quicktest {example_app example_dim example_cmd} {
    apps::setActiveApp Examples
    ::Examples::LaunchExample $example_app $example_dim $example_cmd
}