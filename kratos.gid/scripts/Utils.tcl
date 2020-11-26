
proc Kratos::Quicktest {example_app example_dim example_cmd} {
    apps::setActiveApp Examples
    ::Examples::LaunchExample $example_app $example_dim $example_cmd
} 

proc Kratos::ForceRun { } {
    # validated by escolano@cimne.upc.edu
    variable must_write_calc_data
    set temp $must_write_calc_data
    set must_write_calc_data 0
    GiD_Process Mescape Utilities Calculate escape escape
    set must_write_calc_data $temp
}

proc Kratos::DestroyWindows { } {
    gid_groups_conds::close_all_windows
    spdAux::DestroyWindows
    if {[info exists ::Kratos::kratos_private(UseWizard)] && $::Kratos::kratos_private(UseWizard)} {
        smart_wizard::DestroyWindow
    }
    ::Kratos::EndCreatePreprocessTBar
}

proc Kratos::ResetModel { } {
    foreach layer [GiD_Info layers] {
        GiD_Process 'Layers Delete $layer Yes escape escape
    }
    foreach group [GiD_Groups list] {
        if {[GiD_Groups exists $group]} {GiD_Groups delete $group}
    }
}

proc Kratos::GetModelName { } {
    return [file tail [GiD_Info project ModelName]]
}

proc Kratos::IsModelEmpty { } {
    if {[GiD_Groups list] != ""} {return false}
    if {[GiD_Layers list] != "Layer0"} {return false}
    if {[GiD_Geometry list point 1:end] != ""} {return false}
    return true
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

proc Kratos::CheckProjectIsNew {filespd} {
    variable kratos_private
    set filedir [file dirname $filespd]
    if {[file nativename $kratos_private(Path)] eq [file nativename $filedir]} {
        set kratos_private(ProjectIsNew) 1
    } else {
        set kratos_private(ProjectIsNew) 0
    }
}


proc Kratos::WarnAboutMinimumRecommendedGiDVersion { } {
    variable kratos_private

    if { [GidUtils::VersionCmp $kratos_private(CheckMinimumGiDVersion)] < 0 } {
        W "Warning: kratos interface requires GiD $kratos_private(CheckMinimumGiDVersion) or later."
        if { [GidUtils::VersionCmp 14.0.0] < 0 } {
            W "If you are still using a GiD version 13.1.7d or later, you can still use most of the features, but think about upgrading to GiD 14." 
        } {
            W "If you are using an official version of GiD 14, we recommend to use the latest developer version"
        }
        W "Download it from: https://www.gidhome.com/download/developer-versions/"
    }
}

# Customlib libs and preferences
proc Kratos::LoadProblemtypeLibraries {} {  
    package require customlib_extras
    package require customlib_native_groups
    variable kratos_private
    
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
}

proc Kratos::GiveKratosDefaultsFile {} {
    variable kratos_private
    set gid_defaults [GiD_GetUserSettingsFilename -create_folders]
    set dir_name [file dirname $gid_defaults]
    set file_name $kratos_private(Name)$kratos_private(Version).ini
    if { $::tcl_platform(platform) == "windows" } {
        return [file join $dir_name $file_name]
    } else {
        return [file join $dir_name .$file_name]
    }
}

# PREFERENCES
proc Kratos::GetPreferencesFilePath { } {
    variable kratos_private
    # Where we store the user preferences :)
    
    # Get the GiD preferences dir
    set dir_name [file dirname [GiveGidDefaultsFile]]

    # Our file is KratosVars.txt
    set file_name $kratos_private(Name)Vars.txt

    # Linux one will start with a point... pijadas
    if { $::tcl_platform(platform) == "windows" } {
        return [file join $dir_name $file_name]
    } else {
        return [file join $dir_name .$file_name]
    }
}

proc Kratos::RegisterEnvironment { } {
    #do not save preferences starting with flag gid.exe -c (that specify read only an alternative file)
    if { [GiD_Set SaveGidDefaults] } {
        variable kratos_private
        set vars_to_save [list DevMode echo_level mdpa_format]
        set preferences [dict create]
        foreach v $vars_to_save {
            if {[info exists kratos_private($v)]} {
                dict set preferences $v $kratos_private($v)
            }
        }
        
        if {[llength [dict keys $preferences]] > 0} {
            set fp [open [Kratos::GetPreferencesFilePath] w]
            if {[catch {set data [puts $fp [write::tcl2json $preferences]]} ]} {W "Problems saving user prefecences"; W $data}
            close $fp
        }
    }
}

proc Kratos::LoadEnvironment { } {
    variable kratos_private

    # Init variables
    set data ""
    
    catch {
        # Try to open the preferences file
        set fp [open [Kratos::GetPreferencesFilePath] r]
        # Read the preferences
        set data [read $fp]
        # Close the file
        close $fp
    }
    # Preferences are written in json format
    foreach {k v} [write::json2dict $data] {
        # Foreach pair key value, restore it
        set kratos_private($k) $v
    }
}

# LOGS

proc Kratos::LogInitialData { } {
    
    # Get the exec version
    Kratos::GetExecVersion
    Kratos::GetProblemtypeGitTag 

    set initial_data [dict create]
    dict set initial_data GiD_version [GiD_Info gidversion]
    dict set initial_data problemtype_git_hash $Kratos::kratos_private(problemtype_git_hash)
    dict set initial_data problemtype_version $Kratos::kratos_private(Version)
    dict set initial_data executable_version $Kratos::kratos_private(exec_version)
    dict set initial_data current_platform $::tcl_platform(platform)
    dict set initial_data gid_version [GiD_Info gidversion]
    
    Kratos::Log [write::tcl2json $initial_data]
}


proc Kratos::Duration { int_time } {
    if {$int_time == 0} {return "0 sec"}
    set timeList [list]
    foreach div {86400 3600 60 1} mod {0 24 60 60} name {day hr min sec} {
        set n [expr {$int_time / $div}]
        if {$mod > 0} {set n [expr {$n % $mod}]}
        if {$n > 1} {
            lappend timeList "$n ${name}s"
        } elseif {$n == 1} {
            lappend timeList "$n $name"
        }
    }
    return [join $timeList]
}


proc Kratos::GetExecVersion {} {
    catch {
        variable kratos_private
        set tmp_filename [GidUtils::GetTmpFilename]
        if { $::tcl_platform(platform) == "unix"} {set command [file join $kratos_private(Path) exec Kratos runkratos]} {set command [file join $kratos_private(Path) exec Kratos runkratos.exe]}
        set result [exec $command -c "import KratosMultiphysics as Kratos" >> $tmp_filename]
        set fp [open $tmp_filename r]
        set file_data [read $fp]
        close $fp
        file delete $tmp_filename
        set data [split $file_data "\n"]
        foreach line $data {
            if {[string first "Multi-Physics" $line] > 0} {
                set kratos_private(exec_version) [string range [string trim $line] 14 end]
                break;
            }
        }
    }
}
proc Kratos::GetProblemtypeGitTag {} {
    catch {
        variable kratos_private
        set tmp_filename [GidUtils::GetTmpFilename]
        set result [exec git -C $kratos_private(Path) log --format="%H" -n 1 >> $tmp_filename]
        set fp [open $tmp_filename r]
        set file_data [read $fp]
        close $fp
        file delete $tmp_filename
        set data [split $file_data "\n"]
        set kratos_private(problemtype_git_hash) [string trim [string trim [lindex $data 0]] "\""]
    }
}

proc Kratos::GetMeshBasicData { } {
    set result [dict create]
    foreach element_type [GidUtils::GetElementTypes all] {
        set ne [GiD_Info Mesh NumElements $element_type]       
        if { $ne } {
            dict set result $element_type $ne
        }
    }
    
    dict set result nodes [GiD_Info Mesh NumNodes] 
    dict set result is_quadratic [expr [GiD_Info Project Quadratic] && ![GiD_Cartesian get iscartesian] ]
    return $result   
}