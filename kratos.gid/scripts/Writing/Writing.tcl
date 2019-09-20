
##################################################################################
#   This file is common for all Kratos Applications.
#   Do not change anything here unless it's strictly necessary.
##################################################################################

namespace eval write {
    variable mat_dict
    variable submodelparts
    variable MDPA_loop_control
    variable current_configuration
    variable current_mdpa_indent_level
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
    customlib::UpdateDocument
    SetConfigurationAttribute dir [file dirname $filename]
    SetConfigurationAttribute model_name [file rootname [file tail $filename]]

    set errcode 0
    set fail [::Kratos::CheckValidProjectName [file rootname $filename]]

    if {$fail} {
        W [= "Wrong project name. Avoid boolean and numeric names."]
        return 1
    }
    if {$time_monitor} {set inittime [clock seconds]}
    set activeapp [::apps::getActiveApp]
    set appid [::apps::getActiveAppId]

    #### Force values update ####
    spdAux::ForceTreePreload

    #### Validate ####
    set errcode [writeValidateInApp $appid]

    #### MDPA Write ####
    if {$errcode eq 0} {
        set errcode [writeAppMDPA $appid]
    }
    #### Project Parameters Write ####
    set wevent [$activeapp getWriteParametersEvent]
    set filename "ProjectParameters.json"

    if {$errcode eq 0} {
        set errcode [write::singleFileEvent $filename $wevent "Project Parameters"]
    }

    #### Custom files block ####
    set wevent [$activeapp getWriteCustomEvent]
    set filename ""
    if {$errcode eq 0} {
        set errcode [write::singleFileEvent $filename $wevent "Custom file" 0]
    }
    if {$time_monitor}  {
        set endtime [clock seconds]
        set ttime [expr {$endtime-$inittime}]
        W "Total time: [Duration $ttime]"
    }
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
    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
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

    if {$::Kratos::kratos_private(DevMode) eq "dev"} {
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

proc write::getSubModelPartId {cid group} {
    variable submodelparts

    set find [list $cid ${group}]
    if {[dict exists $submodelparts $find]} {
        return [dict get $submodelparts [list $cid ${group}]]
    } {
        return 0
    }
}

proc write::transformGroupName {groupid} {
    set new_parts [list ]
    foreach part [GidUtils::Split $groupid "//"]  {
        foreach {bad good} {" " "_"} {
            lappend new_parts [string map [list $bad $good] $part]
        }
    }
    return [join $new_parts /]
}

# Warning! Indentation must be set before calling here!
proc write::GetFormatDict { groupid mid num} {
    set s [mdpaIndent]
    set f "${s}%5d [format "%10d" $mid] [string repeat "%10d " $num]\n"
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

proc write::getPartsGroupsId {} {
    set root [customlib::GetBaseRoot]

    set listOfGroups [list ]
    set xp1 "[spdAux::getRoute [GetConfigurationAttribute parts_un]]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute [GetConfigurationAttribute parts_un]]/condition/group"
    }
    set groups [$root selectNodes $xp1]

    foreach group $groups {
        set groupName [get_domnode_attribute $group n]
        lappend listOfGroups $groupName
    }
    return $listOfGroups
}

proc write::getPartsSubModelPartId {} {
    set root [customlib::GetBaseRoot]

    set listOfGroups [list ]

    foreach group [getPartsGroupsId] {
        lappend listOfGroups [write::getSubModelPartId Parts $group]
    }
    return $listOfGroups
}

proc write::writePartSubModelPart { } {
    foreach group [getPartsGroupsId] {
        writeGroupSubModelPart Parts $group "Elements"
    }
}

proc write::writeLinearLocalAxesGroup {group} {
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
            write::WriteString [format "%5d \[3\](%14.10f, %14.10f, %14.10f)" $line $y0 $y1 $y2]
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

proc write::Duration { int_time } {
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
    return [getFormattedValue [gid_groups_conds::convert_value_to_default $node]]
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

proc write::writePropertiesJsonFile {{parts_un ""} {fname "materials.json"} {write_claw_name "True"} {model_part_name ""}} {
    if {$parts_un eq ""} {set parts_un [GetConfigurationAttribute parts_un]}
    set mats_json [getPropertiesList $parts_un $write_claw_name $model_part_name]
    write::OpenFile $fname
    write::WriteJSON $mats_json
    write::CloseFile
}

proc write::getPropertiesList {parts_un {write_claw_name "True"} {model_part_name ""}} {
    variable mat_dict
    set props_dict [dict create]
    set props [list ]

    set doc $gid_groups_conds::doc
    set root [$doc documentElement]
    #set root [customlib::GetBaseRoot]

    set xp1 "[spdAux::getRoute $parts_un]/group"
    if {[llength [$root selectNodes $xp1]] < 1} {
        set xp1 "[spdAux::getRoute $parts_un]/condition/group"
    }
    foreach gNode [$root selectNodes $xp1] {
        set group [get_domnode_attribute $gNode n]
        set sub_model_part [write::getSubModelPartId Parts $group]
        if {$model_part_name ne ""} {set sub_model_part $model_part_name.$sub_model_part}
        set sub_model_part [string trim $sub_model_part "."]
        if { [dict exists $mat_dict $group] } {
            set mid [dict get $mat_dict $group MID]
            set prop_dict [dict create]
            dict set prop_dict "model_part_name" $sub_model_part
            dict set prop_dict "properties_id" $mid
            set constitutive_law_id [dict get $mat_dict $group ConstitutiveLaw]
            set constitutive_law [Model::getConstitutiveLaw $constitutive_law_id]
            if {$constitutive_law ne ""} {
                set exclusionList [list "MID" "APPID" "ConstitutiveLaw" "Material" "Element"]
                set variables_dict [dict create]
                foreach prop [dict keys [dict get $mat_dict $group] ] {
                    if {$prop ni $exclusionList} {
                        dict set variables_list $prop [getFormattedValue [dict get $mat_dict $group $prop]]
                    }
                }
                set material_dict [dict create]

                if {$write_claw_name eq "True"} {
                    set constitutive_law_name [$constitutive_law getKratosName]
                    dict set material_dict constitutive_law [dict create name $constitutive_law_name]
                }
                dict set material_dict Variables $variables_list
                dict set material_dict Tables dictnull

                dict set prop_dict Material $material_dict

                lappend props $prop_dict
            }
        }

    }

    dict set props_dict properties $props
    return $props_dict
}

write::Init
