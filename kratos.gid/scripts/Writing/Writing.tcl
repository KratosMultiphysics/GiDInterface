
##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval ::write {
    Kratos::AddNamespace [namespace current]

    variable mat_dict
    variable submodelparts
    variable MDPA_loop_control
    variable current_configuration
    variable current_mdpa_indent_level
    variable formats_dict
    variable properties_exclusion_list
}

proc write::Init { } {
    variable mat_dict
    variable submodelparts
    variable current_configuration
    variable current_mdpa_indent_level

    set current_configuration [dict create]

    set mat_dict ""
    set submodelparts [dict create]

    SetConfigurationAttribute dir ""
    SetConfigurationAttribute parts_un ""
    SetConfigurationAttribute materials_un ""
    SetConfigurationAttribute time_monitor 0
    SetConfigurationAttribute model_name ""

    variable MDPA_loop_control
    set MDPA_loop_control 0

    set current_mdpa_indent_level 0


    variable formats_dict
    set formats_dict [dict create]
    variable properties_exclusion_list
    set properties_exclusion_list [list "MID" "APPID" "ConstitutiveLaw" "Material" "Element"]
}

proc write::initWriteConfiguration {configuration} {
    SetConfigurationAttributes $configuration
    variable MDPA_loop_control
    set MDPA_loop_control 0

    processMaterials
}

proc write::initWriteData {parts mats} {
    set configutation [dict create]
    dict set configuration parts_un $parts
    dict set configuration materials_un $mats

    initWriteConfiguration $configuration
}

proc write::GetConfigurationAttribute {att} {
    variable current_configuration
    set ret ""
    if {[dict exists $current_configuration $att]} {
        set ret [dict get $current_configuration $att]
    }
    return $ret

}

proc write::SetConfigurationAttribute {att val} {
    variable current_configuration
    dict set current_configuration $att $val
}

proc write::SetConfigurationAttributes {configuration} {
    variable current_configuration
    set current_configuration [dict merge $current_configuration $configuration]
}

proc write::AddConfigurationAttribute {att val} {
    variable current_configuration
    dict append current_configuration $att $val]
}

# Write Events
proc write::writeEvent { filename } {
    update ;#else appid is empty running in batch mode with window
    set time_monitor [GetConfigurationAttribute time_monitor]
    Kratos::Log "Write start $filename"
    customlib::UpdateDocument
    SetConfigurationAttribute dir [file dirname $filename]
    SetConfigurationAttribute model_name [file rootname [file tail $filename]]

    set errcode 0
    set fail [::Kratos::CheckValidProjectName [file rootname $filename]]

    if {$fail} {
        W [= "Wrong project name. Avoid boolean and numeric names."]
        return 1
    }
    set inittime [clock seconds]

    # Set write formats depending on the user's configuration
    InitWriteFormats

    # Current active app
    set activeapp [::apps::getActiveApp]
    set appid [::apps::getActiveAppId]

    #### Force values update ####
    spdAux::ForceTreePreload

    #### Validate ####
    Kratos::Log "Write validation $appid"
    set errcode [writeValidateInApp $appid]

    #### MDPA Write ####
    if {$errcode eq 0} {
        Kratos::Log "Write MDPA $appid"
        set errcode [writeAppMDPA $appid]
    }
    #### Project Parameters Write ####
    set wevent [$activeapp getWriteParametersEvent]
    set filename "ProjectParameters.json"

    if {$errcode eq 0} {
        Kratos::Log "Write project parameters $appid"
        set errcode [write::singleFileEvent $filename $wevent "Project Parameters"]
    }

    #### Custom files block ####
    set wevent [$activeapp getWriteCustomEvent]
    set filename ""
    if {$errcode eq 0} {
        Kratos::Log "Write custom event $appid"
        set errcode [write::singleFileEvent $filename $wevent "Custom file" 0]
    }
    set endtime [clock seconds]
    set ttime [expr {$endtime-$inittime}]
    if {$time_monitor}  {
        W "Total time: [Kratos::Duration $ttime]"
    }

    #### Copy main script file ####
    if {$errcode eq 0} {
        Kratos::Log "Write custom event $appid"
        set errcode [CopyMainScriptFile]
    }

    #### Debug files for VSCode ####
    write::writeLaunchJSONFile

    Kratos::Log "Write end $appid in [Kratos::Duration $ttime]"
    return $errcode
}

proc write::writeValidateInApp {appid} {
    set activeapp [::apps::getAppById $appid]
    set wevent ::[$activeapp getValidateWriteEvent]
    set errcode 0
    if {[info procs $wevent] eq $wevent} {
        set err [eval $wevent]
        set errcode [lindex $err 0]
        set errmess [lindex $err 1]
        if {$errcode} {
            foreach line $errmess {
                W $line
            }
        }
    }
    return $errcode
}

proc write::singleFileEvent { filename wevent {errName ""} {needsOpen 1} } {
    set errcode 0

    CloseFile
    if {$needsOpen} {OpenFile $filename}
    if {[Kratos::IsDeveloperMode]} {
        if {[catch {eval $wevent} errmsg options] } {
            W $::errorInfo
            set errcode 1
        }
    } else {
        if {[catch {eval $wevent} fid] } {
            W "Problem Writing $errName block:\n$fid\nEvent $wevent \nEnd problems"
            set errcode 1
        }
    }
    CloseFile

    return $errcode
}

proc write::writeAppMDPA {appid} {
    variable MDPA_loop_control
    incr MDPA_loop_control
    if {$MDPA_loop_control > 10} {error [= "Infinite loop on MDPA - Check recursive or cyclic calls"]}

    set errcode 0
    set activeapp [::apps::getAppById $appid]

    #### MDPA Write ####
    set wevent [$activeapp getWriteModelPartEvent]
    set filename "[Kratos::GetModelName].mdpa"

    CloseFile
    OpenFile $filename

    if {[Kratos::IsDeveloperMode]} {
        eval $wevent
    } else {
        if { [catch {eval $wevent} fid] } {
            W "Problem Writing MDPA block:\n$fid\nEnd problems"
            set errcode 1
        }
    }
    CloseFile
    return $errcode
}

proc write::GetWriteGroupName { group_id } {
    # Interval trick
    # If a group is child, and has been created due to the Interval issue
    # it's entities are on the father, so we need to use it's fathers name
    foreach parent [dict keys $spdAux::GroupsEdited] {
        if {$group_id in [dict get $spdAux::GroupsEdited $parent]} {
            set group_id $parent
            break
        }
    }
    return $group_id
}

proc write::GetListsOfNodes {elems nnodes {ignore 0} } {
    set obj [list ]
    set imax [llength $elems]
    if {$nnodes eq 0} {return $obj}
    set i 0
    while {$i < $imax} {
        for {set j 0} {$j < $ignore} {incr j} {incr i; if {$i >= $imax} {return $obj}}
        set tmp [list ]
        for {set j 0} {$j < $nnodes} {incr j} {
            if {$i >= $imax} {break}
            lappend tmp [lindex $elems $i]
            incr i
        }
        lappend obj $tmp
    }
    return $obj
}


proc write::transformGroupName {groupid} {
    set new_parts [list ]
    foreach part [GidUtils::Split $groupid "//"]  {
        foreach {bad good} {" " "_"} {
            lappend new_parts [string map [list $bad $good] $part]
        }
    }
    return [join $new_parts -]
}

# Warning! Indentation must be set before calling here!
proc write::GetFormatDict { groupid mid num} {
    variable formats_dict
    set id_f [dict get $formats_dict ID]
    set mid_f [dict get $formats_dict MAT_ID]

    set s [mdpaIndent]
    set f "${s}$id_f [format $mid_f $mid] [string repeat "$id_f " $num]\n"
    return [dict create $groupid $f]
}

proc write::getEtype {ov group} {
    set isquadratic [isquadratic]
    set ret [list "" ""]
    set b 0
    if {$ov eq "point"} {
        if {$b} {error "Multiple element types in $group over $ov"}
        set ret [list "Point" 1]
        set b 1
    }

    if {$ov eq "line"} {
        if {$b} {error "Multiple element types in $group over $ov"}
        switch $isquadratic {
            0 { set ret [list "Linear" 2] }
            default { set ret [list "Linear" 3] }
        }
    }

    if {$ov eq "surface"} {
        if {[GiD_EntitiesGroups get $group elements -count -element_type Triangle]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Triangle" 3]  }
                default { set ret [list "Triangle" 6]  }
            }
            set b 1
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Quadrilateral]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Quadrilateral" 4]  }
                1 { set ret [list "Quadrilateral" 8]  }
                2 { set ret [list "Quadrilateral" 9]  }
            }
            set b 1
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Circle]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Circle" 1]  }
            }
            set b 1
        }
    }

    if {$ov eq "volume"} {
        if {[GiD_EntitiesGroups get $group elements -count -element_type Tetrahedra]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Tetrahedra" 4]  }
                1 { set ret [list "Tetrahedra" 10] }
                2 { set ret [list "Tetrahedra" 10] }
            }
            set b 1
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Hexahedra]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Hexahedra" 8]  }
                1 { set ret [list "Hexahedra" 20]  }
                2 { set ret [list "Hexahedra" 27]  }
            }
            set b 1
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Prism]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Hexahedra" 6]  }
                1 { set ret [list "Hexahedra" 1]  }
                2 { set ret [list "Hexahedra" 27]  }
            }
            set b 1
        }
        if {[GiD_EntitiesGroups get $group elements -count -element_type Sphere]} {
            if {$b} {error "Multiple element types in $group over $ov"}
            switch $isquadratic {
                0 { set ret [list "Sphere" 1]  }
            }
            set b 1
        }
    }

    return $ret
}
proc write::isquadratic {} {
    return [GiD_Set Model(QuadraticType)]
}

proc write::GetNodesFromElementFace {elem_id face_id} {
    set inf [GiD_Mesh get element $elem_id]
    set elem_type [lindex $inf 1]
    set nnodes [lindex $inf 2]
    set nodes [list ]
    switch $elem_type {
        Tetrahedra {
            set matrix {{1 2 3 5 6 7} {2 4 3 9 10 6} {3 4 1 10 8 7} {4 2 1 9 5 8}}
        }
        Triangle {
            set matrix {{1 2 4} {2 3 5} {3 1 6}}
        }
    }
    # Decrementamos porque la cara con id = i corresponde a la posicion i-1 de la matriz
    incr face_id -1
    set face_matrix [lindex $matrix $face_id]
    foreach node_index $face_matrix {
        set node [lindex $inf [expr $node_index +2]]
        if {$node ne ""} {lappend nodes $node}
    }
    #W "eid $elem_id fid $face_id nds $nodes"
    return $nodes
}

proc write::getPartsGroupsId {{what "name"} } {
    set root [customlib::GetBaseRoot]

    set listOfGroups [list ]
    set xp1 "[spdAux::getRoute [GetConfigurationAttribute parts_un]]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute [GetConfigurationAttribute parts_un]]/condition/group"
    }
    set groups [$root selectNodes $xp1]

    foreach group $groups {
        if {$what eq "node"} {
            lappend listOfGroups $group
        } else {
            set groupName [get_domnode_attribute $group n]
            lappend listOfGroups $groupName
        }
    }
    return $listOfGroups
}

proc write::getPartsSubModelPartId {} {
    set root [customlib::GetBaseRoot]

    set listOfGroups [list ]

    foreach group [getPartsGroupsId node] {
        set cnd_id [get_domnode_attribute [$group parent] n]
        set group_name [get_domnode_attribute $group n]
        lappend listOfGroups [write::getSubModelPartId $cnd_id $group_name]
    }
    return $listOfGroups
}

proc write::writePartSubModelPart { } {
    foreach group [getPartsGroupsId node] {
        set part_name  [get_domnode_attribute [$group parent] n]
        set group_name [get_domnode_attribute $group n]
        writeGroupSubModelPart $part_name $group_name "Elements"
    }
}

proc write::writeLinearLocalAxesGroup {group} {
    variable formats_dict
    set id_f [dict get $formats_dict ID]
    set coord_f [dict get $formats_dict COORDINATE]
    set elements [GiD_EntitiesGroups get $group elements -element_type linear]
    set num_elements [objarray length $elements]
    if {$num_elements} {
        write::WriteString "Begin ElementalData LOCAL_AXIS_2 // Groups: $group"
        for {set i 0} {$i < $num_elements} {incr i} {
            set line [objarray get $elements $i]
            set raw [lindex [lindex [GiD_Info conditions -localaxesmat line_Local_axes mesh $line] 0] 3]
            set y0 [lindex $raw 1]
            set y1 [lindex $raw 4]
            set y2 [lindex $raw 7]
            write::WriteString [format "$id_f \[3\]($coord_f, $coord_f, $coord_f)" $line $y0 $y1 $y2]
        }
        write::WriteString "End ElementalData"
        write::WriteString ""
    }
    return $num_elements
}

proc write::SetParallelismConfiguration {{un "Parallelization"} {n "OpenMPNumberOfThreads"}} {
    set nt 0
    set paralleltype [write::getValue ParallelType]
    if {$paralleltype eq "OpenMP"} {
        catch {set nt [write::getValue $un $n]}
        if {$nt} {write::SetEnvironmentVariable OMP_NUM_THREADS $nt} {return 0}
    } else {
        write::SetEnvironmentVariable OMP_NUM_THREADS 1
        WriteMPIbatFile $un
    }
}

proc write::SetEnvironmentVariable {name value} {
    set ::env($name) $value
}

proc write::WriteMPIbatFile {un} {
    # MPINumberOfProcessors
    set dir $::Kratos::kratos_private(Path)
    set model_dir [GetConfigurationAttribute dir]
    set model_name [GetConfigurationAttribute model_name]
    set num_nodes [write::getValue $un MPINumberOfProcessors]

    set fd [GiD_File fopen [file join $model_dir "MPILauncher.sh"]]
    GiD_File fprintf $fd %s "export LD_LIBRARY_PATH=\"$dir/exec/Kratos\":\"$dir/exec/Kratos/libs\""
    GiD_File fprintf $fd %s "export PYTHONPATH=\"$dir/exec/Kratos/python35.zip\":\"$dir/exec/Kratos\":\$PYTHONPATH"
    GiD_File fprintf $fd %s "export OMP_NUM_THREADS=1"
    GiD_File fprintf $fd %s "# Run Python using the script MainKratos.py"
    GiD_File fprintf $fd %s "mpirun --np $num_nodes \"$dir/exec/Kratos/runkratos\" MainKratos.py > \"$model_dir/$model_name.info\" 2> \"$model_dir/$model_name.err\""
    GiD_File fclose $fd
}

proc write::forceUpdateNode {node} {
    catch {get_domnode_attribute $node dict}
    catch {get_domnode_attribute $node values}
    catch {get_domnode_attribute $node value}
    catch {get_domnode_attribute $node state}
}
proc write::getValueByNode { node {what noforce} } {
    if {[get_domnode_attribute $node v] eq "" || $what eq "force"} {
        write::forceUpdateNode $node
    }
    return [getFormattedValue [get_domnode_attribute $node v]]
}
proc write::getValueByNodeChild { parent_node child_name {what noforce} } {
    set node [$parent_node find n $child_name]
    return [write::getValueByNode $node $what]
}
proc write::getValueByXPath { xpath { it "" }} {
    set root [customlib::GetBaseRoot]
    set node [$root selectNodes $xpath]
    if {$node ne ""} {
        if {$it ne ""} {set node [$node find n $it]}
        return [write::getValueByNode $node]
    }
    return ""
}
proc write::getValue { name { it "" } {what noforce} } {
    set root [customlib::GetBaseRoot]

    set xp [spdAux::getRoute $name]
    set node [$root selectNodes $xp]
    if {$node ne ""} {
        if {$it ne ""} {set node [$node find n $it]}
        if {$what eq "force"} {write::forceUpdateNode $node}
        return [getValueByNode $node]
    } {
        return ""
    }
}

# anything containing the comma character is a list
proc write::getFormattedValue {value} {
    set v ""
    if {[string first , $value] != -1} {
        set v [list ]
        foreach part [split $value ,] {
            lappend v [getFormattedValue $part]
        }
    } else {
        catch {set v [expr $value]}
        if {$v eq "" } {set v $value}
    }
    return $v
}

proc write::isBoolean {value} {
    set goodList [list "Yes" "1" "yes" "ok" "YES" "Ok" "OK" "True" "TRUE" "true" "No" "0" "no" "NO" "False" "FALSE" "false"]
    if {$value in $goodList} {return 1} {return 0}
}
proc write::isBooleanTrue {value} {
    set goodList [list "Yes" "1" "yes" "ok" "YES" "Ok" "OK" "True" "TRUE" "true"]
    if {$value in $goodList} {return 1} {return 0}
}
proc write::isBooleanFalse {value} {
    set goodList [list "No" "0" "no" "NO" "False" "FALSE" "false"]
    if {$value in $goodList} {return 1} {return 0}
}

proc write::getStringBinaryValue { name { it "" } } {
    set v [getValue $name $it]
    return [write::getStringBinaryFromValue $v]
}
proc write::getStringBinaryFromValue {v} {
    set goodList [list "Yes" "1" "yes" "ok" "YES" "Ok" "OK" "True" "TRUE" "true"]
    if {$v in $goodList} {return "true" } {return "false"}
}

proc write::OpenFile { fn } {
    set dir [GetConfigurationAttribute dir]
    set filename [file join $dir $fn]
    CloseFile
    customlib::InitWriteFile $filename
}

proc write::CloseFile { } {
    customlib::EndWriteFile
}

proc write::WriteString {str} {
    GiD_WriteCalculationFile puts [format "%s" $str]
}

proc write::getMatDict {} {
    variable mat_dict
    return $mat_dict
}
proc write::setMatDict {matdict} {
    variable mat_dict
    set mat_dict $matdict
}

proc write::isDict {value} {
    return [expr {[string is list $value] && ([llength $value]&1) == 0}]
}

proc write::getSpacing {number} {
    set r ""
    for {set i 0} {$i<$number} {incr i} {append r " "}
    return $r
}
proc write::mdpaIndent { {b 4} } {
    variable current_mdpa_indent_level
    if {[info exists Kratos::kratos_private(mdpa_format)]} {
        if {$Kratos::kratos_private(mdpa_format) == 0} {
            return ""
        }
    }
    string repeat [string repeat " " $b] $current_mdpa_indent_level
}

# Sets the precission for the diffetent entities written in the mdpa
# To customize the formats and precissions for your mdpa.
# You can edit in your write mdpa event script using write::SetWriteFormatFor
proc write::InitWriteFormats { } {
    if {$::Kratos::kratos_private(mdpa_format) == 1} {
        # Readable
        write::SetWriteFormatFor ID "%5d"
        write::SetWriteFormatFor CONNECTIVITY "%10d"
        write::SetWriteFormatFor MAT_ID "%10d"
        write::SetWriteFormatFor COORDINATE "%14.10f"
    } else {
        # Optimized
        write::SetWriteFormatFor ID "%d"
        write::SetWriteFormatFor CONNECTIVITY "%d"
        write::SetWriteFormatFor MAT_ID "%d"
        write::SetWriteFormatFor COORDINATE "%.10f"
    }
}

proc write::SetWriteFormatFor { what format } {
    variable formats_dict
    dict set formats_dict $what $format
}

proc write::CopyFileIntoModel { filepath } {
    set dir [GetConfigurationAttribute dir]
    set activeapp [::apps::getActiveApp]
    set inidir [apps::getMyDir [$activeapp getName]]
    set totalpath [file join $inidir $filepath]
    file copy -force $totalpath $dir
}
proc write::RenameFileInModel { src target } {
    set dir [GetConfigurationAttribute dir]
    set srcfile [file join $dir $src]
    set tgtfile [file join $dir $target]
    file rename -force $srcfile $tgtfile
}

proc write::WriteAssignedValues {condNode} {
    set assignedVector [list 1 0 1]
    set valuesVector [list 0.0 null 0.0]

    for {set i 0} {$i<3} {incr i} {
        set assigned [lindex $assignedVector $i]
        if {!$assigned} {set assignedVector [lreplace $assignedVector $i $i null]}
    }
    set ret [dict create value $valuesVector]
    return $ret
}

proc write::writeLaunchJSONFile { } {
    # Check if developer
    if {[Kratos::IsDeveloperMode]} {
        set debug_folder $Kratos::kratos_private(debug_folder)

        # Prepare JSON as dict
        set json [dict create version "0.2.0"]
        set n_omp "1"
        set python_env [dict create OMP_NUM_THREADS $n_omp PYTHONPATH $debug_folder LD_LIBRARY_PATH [file join $debug_folder libs]]
        set python_configuration [dict create name "python main" type python request launch program MainKratos.py console integratedTerminal env $python_env cwd [GetConfigurationAttribute dir]]
        set cpp_configuration [dict create name "C++ Attach" type cppvsdbg request attach processId "\${command:pickProcess}"]
        dict set json configurations [list $python_configuration $cpp_configuration]

        # Print json
        CloseFile
        file mkdir [file join [GetConfigurationAttribute dir] .vscode]
        OpenFile ".vscode/launch.json"
        write::WriteJSONAsStringFields $json
        CloseFile
    }
}

proc write::CopyMainScriptFile { } {
    set errcode 0
    # Main python script
    if {[catch {
            set orig_name [write::GetConfigurationAttribute main_launch_file]
            if {$orig_name ne ""} {
                write::CopyFileIntoModel $orig_name
                write::RenameFileInModel [file tail $orig_name] "MainKratos.py"
            }
        } fid] } {
        W "Problem Writing Main launch script \nEvent $fid \nEnd problems"
        return errcode 1
    }
    return $errcode
}

write::Init
