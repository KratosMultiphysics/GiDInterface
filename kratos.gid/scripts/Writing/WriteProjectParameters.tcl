
proc write::dict2json {dictVal} {
    # XXX: Currently this API isn't symmetrical, as to create proper
    # XXX: JSON text requires type knowledge of the input data
    set json ""
    dict for {key val} $dictVal {
        # key must always be a string, val may be a number, string or
        # bare word (true|false|null)
        if {0 && ![string is double -strict $val] && ![regexp {^(?:true|false|null)$} $val]} {
            set val "\"$val\""
        }
        if {[isDict $val]} {
            set val [dict2json $val]
            set val "\[${val}\]"
        } else {
            set val \"$val\"
        }
        append json "\"$key\": $val," \n
    }
    if {[string range $json end-1 end] eq ",\n"} {set json [string range $json 0 end-2]}
    return "\{${json}\}"
}
proc write::json2dict {JSONtext} {
    string range [
        string trim [
            string trimleft [
                string map {\t {} \n {} \r {} , { } : { } \[ \{ \] \}} $JSONtext
                ] {\uFEFF}
            ]
        ] 1 end-1
}
proc write::tcl2json { value } {
    # Guess the type of the value; deep *UNSUPPORTED* magic!
    # display the representation of a Tcl_Obj for debugging purposes. Do not base the behavior of any command on the results of this one; it does not conform to Tcl's value semantics!
    regexp {^value is a (.*?) with a refcount} [::tcl::unsupported::representation $value] -> type
    if {$value eq ""} {return [json::write array {*}[lmap v $value {tcl2json $v}]]}
    switch $type {
        string {
            if {$value eq "false"} {return [expr "false"]}
            if {$value eq "true"} {return [expr "true"]}
            if {$value eq "null"} {return null}
            if {$value eq "dictnull"} {return {{}}}
            return [json::write string $value]
        }
        dict {
            return [json::write object {*}[
                    dict map {k v} $value {tcl2json $v}]]
        }
        list {
            return [json::write array {*}[lmap v $value {tcl2json $v}]]
        }
        int - double {
            return [expr {$value}]
        }
        booleanString {
            if {[isBooleanFalse $value]} {return [expr "false"]}
            if {[isBooleanTrue $value]} {return [expr "true"]}
            return [json::write string $value]
            #return [expr {$value ? "true" : "false"}]
        }
        default {
            # Some other type; do some guessing...
            if {$value eq "null"} {
                # Tcl has *no* null value at all; empty strings are semantically
                # different and absent variables aren't values. So cheat!
                return $value
            } elseif {[string is integer -strict $value]} {
                return [expr {$value}]
            } elseif {[string is double -strict $value]} {
                return [expr {$value}]
            } elseif {[string is boolean -strict $value]} {
                return [expr {$value ? "true" : "false"}]
            }
            return [json::write string $value]
        }
    }
}

proc write::WriteJSON {processDict} {
    WriteString [write::tcl2json $processDict]
}

proc write::GetDefaultOutputDict { {appid ""} } {
    set outputDict [dict create]
    set resultDict [dict create]

    if {$appid eq ""} {set results_UN Results } {set results_UN [apps::getAppUniqueName $appid Results]}
    set GiDPostDict [dict create]
    dict set GiDPostDict GiDPostMode                [getValue $results_UN GiDPostMode]
    dict set GiDPostDict WriteDeformedMeshFlag      [getValue $results_UN GiDWriteMeshFlag]
    dict set GiDPostDict WriteConditionsFlag        [getValue $results_UN GiDWriteConditionsFlag]
    dict set GiDPostDict MultiFileFlag              [getValue $results_UN GiDMultiFileFlag]
    dict set resultDict gidpost_flags $GiDPostDict

    dict set resultDict file_label                 [getValue $results_UN FileLabel]
    set outputCT [getValue $results_UN OutputControlType]
    dict set resultDict output_control_type $outputCT
    if {$outputCT eq "time"} {set frequency [getValue $results_UN OutputDeltaTime]} {set frequency [getValue $results_UN OutputDeltaStep]}
    dict set resultDict output_frequency $frequency

    dict set resultDict body_output           [getValue $results_UN BodyOutput]
    dict set resultDict node_output           [getValue $results_UN NodeOutput]
    dict set resultDict skin_output           [getValue $results_UN SkinOutput]

    dict set resultDict plane_output [GetCutPlanesList $results_UN]

    dict set resultDict nodal_results [GetResultsList $results_UN OnNodes]
    dict set resultDict gauss_point_results [GetResultsList $results_UN OnElement]

    dict set outputDict "result_file_configuration" $resultDict
    dict set outputDict "point_data_configuration" [GetEmptyList]
    return $outputDict
}
proc write::GetEmptyList { } {
    # This is a gipsy code
    set a [list ]
    return $a
}
proc write::GetCutPlanesList { {results_UN Results} } {

    set root [customlib::GetBaseRoot]

    set list_of_planes [list ]

    set xp1 "[spdAux::getRoute $results_UN]/container\[@n='CutPlanes'\]/blockdata"
    set planes [$root selectNodes $xp1]

    foreach plane $planes {
        set pdict [dict create]
        set points [split [get_domnode_attribute [$plane firstChild] v] ","]
        set normals [split [get_domnode_attribute [$plane lastChild ] v] ","]
        dict set pdict point $points
        dict set pdict normal $normals
        if {![isVectorNull $normals]} {lappend list_of_planes $pdict}
        unset pdict
    }
    return $list_of_planes
}

proc write::isVectorNull {vector} {
    set null 1
    foreach component $vector {
        if {$component != 0} {
            set null 0
            break
        }
    }
    return $null
}

proc write::GetDataType {value} {
    regexp {^value is a (.*?) with a refcount} [::tcl::unsupported::representation $value] -> type
    return $type
}

proc write::getSolutionStrategyParametersDict { {solStratUN ""} {schemeUN ""} {StratParamsUN ""} } {
    if {$solStratUN eq ""} {
        set solStratUN [apps::getCurrentUniqueName SolStrat]
    }
    if {$schemeUN eq ""} {
        set schemeUN [apps::getCurrentUniqueName Scheme]
    }
    if {$StratParamsUN eq ""} {
        set StratParamsUN [apps::getCurrentUniqueName StratParams]
    }

    set solstratName [write::getValue $solStratUN]
    set schemeName [write::getValue $schemeUN]
    set sol [::Model::GetSolutionStrategy $solstratName]
    set sch [$sol getScheme $schemeName]

    set solverSettingsDict [dict create]
    foreach {n in} [$sol getInputs] {
        dict set solverSettingsDict $n [write::getValue $StratParamsUN $n ]
    }
    foreach {n in} [$sch getInputs] {
        dict set solverSettingsDict $n [write::getValue $StratParamsUN $n ]
    }
    return $solverSettingsDict
}


proc write::getSolversParametersDict { {appid ""} } {
    if {$appid eq ""} {
        set appid [apps::getActiveAppId]
    }
    set solStratUN [apps::getAppUniqueName $appid SolStrat]
    set solstratName [write::getValue $solStratUN]
    set sol [::Model::GetSolutionStrategy $solstratName]
    set solverSettingsDict [dict create]
    foreach se [$sol getSolversEntries] {
        set solverEntryDict [dict create]
        set un [apps::getAppUniqueName $appid "$solstratName[$se getName]"]
        set route [spdAux::getRoute $un]
        if {$route ne "" } {
            set solver_entry_node [[customlib::GetBaseRoot] selectNodes $route]
            set solver_entry_state [get_domnode_attribute $solver_entry_node state]
            if {$solver_entry_state ne "hidden"} {
                set solverName [write::getValue $un Solver]
                if {$solverName ni [list "Default" "AutomaticOpenMP" "AutomaticMPI" "Automatic" ""]} {
                    dict set solverEntryDict solver_type $solverName
                    set solver [::Model::GetSolver $solverName]
                    foreach {n in} [$solver getInputs] {
                        # JG temporal, para la precarga de combos
                        if {[$in getType] ni [list "bool" "integer" "double"]} {
                            set v [write::getValue $un $n check]
                            dict set solverEntryDict $n $v
                        } {
                            dict set solverEntryDict $n [write::getValue $un $n]
                        }
                    }
                    dict set solverSettingsDict [$se getName] $solverEntryDict
                }
            }
        }
        unset solverEntryDict
    }
    return $solverSettingsDict
}

proc write::getConditionsParametersDict {un {condition_type "Condition"}} {

    set root [customlib::GetBaseRoot]
    set bcCondsDict [list ]
    set grouped_conditions [list ]

    set xp1 "[spdAux::getRoute $un]/condition/group"
    set groups [$root selectNodes $xp1]
    if {$groups eq ""} {
        set xp1 "[spdAux::getRoute $un]/group"
        set groups [$root selectNodes $xp1]
    }
    foreach group $groups {
        set groupName [$group @n]
        set cid [[$group parent] @n]
        set groupName [write::GetWriteGroupName $groupName]
        set groupId [::write::getSubModelPartId $cid $groupName]
        set grouping_by ""
        if {$condition_type eq "Condition"} {
            set condition [::Model::getCondition $cid]
            if {$condition eq ""} {continue}
            set grouping_by [$condition getGroupBy]
        } {
            set condition [::Model::getNodalConditionbyId $cid]
            if {$condition eq ""} {continue}
        }
        if {$grouping_by eq "Condition"} {
            # Grouped conditions will be processed later
            if {$cid ni $grouped_conditions} {
                lappend grouped_conditions $cid
            }
        } else {
            set processName [$condition getProcessName]
            set process [::Model::GetProcess $processName]
            set processDict [dict create]
            set paramDict [dict create]
            dict set paramDict model_part_name [write::GetModelPartNameWithParent $groupId]

            set process_attributes [$process getAttributes]
            set process_parameters [$process getInputs]

            dict set process_attributes process_name [dict get $process_attributes n]
            dict unset process_attributes n
            dict unset process_attributes pn
            if {[dict exists $process_attributes help]} {dict unset process_attributes help}
            if {[dict exists $process_attributes process_name]} {dict unset process_attributes process_name}

            set processDict [dict merge $processDict $process_attributes]
            if {[$condition hasAttribute VariableName]} {
                set variable_name [$condition getAttribute VariableName]
                # "lindex" is a rough solution. Look for a better one.
                if {$variable_name ne ""} {dict set paramDict variable_name [lindex $variable_name 0]}
            }
            foreach {inputName in_obj} $process_parameters {
                set in_type [$in_obj getType]
                if {$in_type eq "vector"} {
                    set vector_type [$in_obj getAttribute "vectorType"]
                    if {$vector_type eq "bool"} {
                        set ValX [expr [get_domnode_attribute [$group find n ${inputName}X] v] ? True : False]
                        set ValY [expr [get_domnode_attribute [$group find n ${inputName}Y] v] ? True : False]
                        set ValZ [expr False]
                        if {[$group find n ${inputName}Z] ne ""} {set ValZ [expr [get_domnode_attribute [$group find n ${inputName}Z] v] ? True : False]}
                    } elseif {$vector_type eq "double"} {
                        if {[$in_obj getAttribute "enabled"] in [list "1" "0"]} {
                            foreach i [list "X" "Y" "Z"] {
                                if {[expr [get_domnode_attribute [$group find n Enabled_$i] v] ] ne "Yes"} {
                                    set Val$i null
                                } else {
                                    set printed 0
                                    if {[$in_obj getAttribute "function"] eq "1"} {
                                        if {[get_domnode_attribute [$group find n "ByFunction$i"] v]  eq "Yes"} {
                                            set funcinputName "${i}function_$inputName"
                                            set value [get_domnode_attribute [$group find n $funcinputName] v]
                                            set Val$i $value
                                            set printed 1
                                        }
                                    }
                                    if {!$printed} {
                                        set value [expr [gid_groups_conds::convert_value_to_default [$group find n ${inputName}$i] ] ]
                                        set Val$i $value
                                    }
                                }
                            }
                        } else {
                            foreach i [list "X" "Y" "Z"] {
                                set printed 0
                                if {[$in_obj getAttribute "function"] eq "1"} {
                                    if {[get_domnode_attribute [$group find n "ByFunction$i"] v]  eq "Yes"} {
                                        set funcinputName "${i}function_$inputName"
                                        set value [get_domnode_attribute [$group find n $funcinputName] v]
                                        set Val$i $value
                                        set printed 1
                                    }
                                }
                                if {!$printed} {
                                    set value [expr [gid_groups_conds::convert_value_to_default [$group find n ${inputName}$i] ] ]
                                    set Val$i $value
                                }
                            }
                        }
                    } elseif {$vector_type eq "tablefile" || $vector_type eq "file"} {
                        set ValX "[get_domnode_attribute [$group find n ${inputName}X] v]"
                        set ValY "[get_domnode_attribute [$group find n ${inputName}Y] v]"
                        set ValZ "0"
                        if {[$group find n ${inputName}Z] ne ""} {set ValZ "[get_domnode_attribute [$group find n ${inputName}Z] v]"}
                    } else {
                        set ValX [expr [gid_groups_conds::convert_value_to_default [$group find n ${inputName}X] ] ]
                        set ValY [expr [gid_groups_conds::convert_value_to_default [$group find n ${inputName}Y] ] ]
                        set ValZ [expr 0.0]
                        if {[$group find n ${inputName}Z] ne ""} {set ValZ [expr [gid_groups_conds::convert_value_to_default [$group find n ${inputName}Z] ]]}
                    }
                    dict set paramDict $inputName [list $ValX $ValY $ValZ]
                } elseif {$in_type eq "inline_vector"} {
                    set value [gid_groups_conds::convert_value_to_default [$group find n $inputName]]
                    lassign [split $value ","] ValX ValY ValZ
                    if {$ValZ eq ""} {set ValZ 0.0}
                    dict set paramDict $inputName [list [expr $ValX] [expr $ValY] [expr $ValZ]]
                } elseif {$in_type eq "double" || $in_type eq "integer"} {
                    set printed 0
                    if {[$in_obj getAttribute "function"] eq "1"} {
                        if {[get_domnode_attribute [$group find n "ByFunction"] v]  eq "Yes"} {
                            set funcinputName "function_$inputName"
                            set value [get_domnode_attribute [$group find n $funcinputName] v]
                            dict set paramDict $inputName $value
                            set printed 1
                        }
                    }
                    if {!$printed} {
                        set value [gid_groups_conds::convert_value_to_default [$group find n $inputName]]
                        #set value [get_domnode_attribute [$group find n $inputName] v]
                        dict set paramDict $inputName [expr $value]
                    }
                } elseif {$in_type eq "bool"} {
                    set value [get_domnode_attribute [$group find n $inputName] v]
                    set value [expr $value ? True : False]
                    dict set paramDict $inputName [expr $value]
                } elseif {$in_type eq "tablefile"} {
                    set value [get_domnode_attribute [$group find n $inputName] v]
                    dict set paramDict $inputName $value
                } else {
                    if {[get_domnode_attribute [$group find n $inputName] state] ne "hidden" } {
                        set value [get_domnode_attribute [$group find n $inputName] v]
                        dict set paramDict $inputName $value
                    }
                }
            }
            if {[$group find n Interval] ne ""} {dict set paramDict interval [write::getInterval  [get_domnode_attribute [$group find n Interval] v]] }
            dict set processDict Parameters $paramDict
            lappend bcCondsDict $processDict
        }
    }

    foreach cid $grouped_conditions {
        if {$condition_type eq "Condition"} {
            set condition [::Model::getCondition $cid]
        } {
            set condition [::Model::getNodalConditionbyId $cid]
        }

        set processName [$condition getProcessName]
        set process [::Model::GetProcess $processName]
        set processDict [dict create]
        set paramDict [dict create]
        dict set paramDict model_part_name [write::GetModelPartNameWithParent $cid]

        set process_attributes [$process getAttributes]
        set process_parameters [$process getInputs]

        dict set process_attributes process_name [dict get $process_attributes n]
        dict unset process_attributes n
        dict unset process_attributes pn

        set processDict [dict merge $processDict $process_attributes]
        if {[$condition hasAttribute VariableName]} {
            set variable_name [$condition getAttribute VariableName]
            # "lindex" is a rough solution. Look for a better one.
            if {$variable_name ne ""} {dict set paramDict variable_name [lindex $variable_name 0]}
        }
        dict set processDict Parameters $paramDict
        lappend bcCondsDict $processDict
    }
    return $bcCondsDict
}

proc write::GetResultsList { un {cnd ""} } {

    set root [customlib::GetBaseRoot]

    set result [list ]
    if {$cnd eq ""} {set xp1 "[spdAux::getRoute $un]/value"} {set xp1 "[spdAux::getRoute $un]/container\[@n = '$cnd'\]/value"}
    set resultxml [$root selectNodes $xp1]
    foreach res $resultxml {
        if {[get_domnode_attribute $res v] in [list "Yes" "True" "1"] && [get_domnode_attribute $res state] ne "hidden"} {
            set name [get_domnode_attribute $res n]
            lappend result $name
        }
    }
    return $result
}

proc write::GetRestartProcess { {un ""} {name "" } } {

    set root [customlib::GetBaseRoot]

    set resultDict [dict create ]
    if {$un eq ""} {set un "Restart"}
    if {$name eq ""} {set name "RestartOptions"}

    dict set resultDict "python_module" "restart_process"
    dict set resultDict "kratos_module" "KratosMultiphysics.SolidMechanicsApplication"
    dict set resultDict "help" "This process writes restart files"
    dict set resultDict "process_name" "RestartProcess"

    set params [dict create]
    set saveValue [write::getStringBinaryValue $un SaveRestart]

    dict set resultDict "process_name" "RestartProcess"
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set params "model_part_name" [write::GetModelPartNameWithParent $model_name]
    dict set params "save_restart" $saveValue
    dict set params "restart_file_name" [file tail [GiD_Info Project ModelName]]
    set xp1 "[spdAux::getRoute $un]/container\[@n = '$name'\]/value"
    set file_label [getValue $un RestartFileLabel]
    dict set params "restart_file_label" $file_label
    set output_control [getValue $un RestartControlType]
    dict set params "output_control_type" $output_control
    if {$output_control eq "time"} {dict set params "output_frequency" [getValue $un RestartDeltaTime]} {dict set params "output_frequency" [getValue $un RestartDeltaStep]}
    set jsonoutput [write::getStringBinaryValue $un json_output]
    dict set params "json_output" $jsonoutput

    dict set resultDict "Parameters" $params
    return $resultDict
}


proc write::getAllMaterialParametersDict {matname} {
    set root [customlib::GetBaseRoot]
    set md [dict create]

    set xp3 [spdAux::getRoute [GetConfigurationAttribute materials_un]]
    append xp3 [format_xpath {/blockdata[@n="material" and @name=%s]/value} $matname]

    set props [$root selectNodes $xp3]
    foreach prop $props {
        dict set md [$prop @n] [get_domnode_attribute $prop v]
    }
    return $md
}

proc write::getIntervalsDict { { un "Intervals" } {appid "" } } {
    set root [customlib::GetBaseRoot]

    set intervalsDict [dict create]
    set xp3 "[spdAux::getRoute $un]/blockdata\[@n='Interval'\]"
    if {$xp3 ne ""} {
        set intervals [$root selectNodes $xp3]
        foreach intNode $intervals {
            set name [get_domnode_attribute $intNode name]
            set xpini "value\[@n='IniTime'\]"
            set xpend "value\[@n='EndTime'\]"
            set ininode [$intNode selectNodes $xpini]
            set endnode [$intNode selectNodes $xpend]
            set ini ""
            set end ""
            catch {set ini [expr [get_domnode_attribute $ininode v]]}
            catch {set end [expr [get_domnode_attribute $endnode v]]}
            if {$ini eq ""} {set ini [get_domnode_attribute $ininode v]}
            if {$end eq ""} {set end [get_domnode_attribute $endnode v]}
            dict set intervalsDict $name [list $ini $end]
        }
    }
    return $intervalsDict
}
proc write::getInterval { interval {un "Intervals"} {appid "" }  } {
    set ini 0.0
    set end 0.0
    set intervals [write::getIntervalsDict $un]
    foreach int [dict keys $intervals] {
        if {$int eq $interval} {lassign [dict get $intervals $int] ini end}
    }
    return [list $ini $end]
}

proc write::GetModelPartNameWithParent { child_name {forced_parent ""}} {
    set parent ""
    if {$forced_parent eq ""} {
        set par [write::GetConfigurationAttribute model_part_name]
        if {$par ne ""} {
            append parent $par "."
        }
    } else {
         append parent $forced_parent "."
    }
    append result $parent $child_name
    return $result
}

proc write::GetDefaultOutputProcessDict { } {
    # prepare params
    set model_name [file tail [GiD_Info Project ModelName]]
    set paralleltype [write::getValue ParallelType]

    set outputProcessParams [dict create]
    dict set outputProcessParams model_part_name [write::GetModelPartNameWithParent [GetConfigurationAttribute output_model_part_name]] 
    dict set outputProcessParams output_name $model_name
    dict set outputProcessParams postprocess_parameters [write::GetDefaultOutputDict]

    set outputConfigDict [dict create]
    if {$paralleltype eq "OpenMP"} {
        dict set outputConfigDict python_module gid_output_process
        dict set outputConfigDict kratos_module KratosMultiphysics
        dict set outputConfigDict process_name GiDOutputProcess
        dict set outputConfigDict help "This process writes postprocessing files for GiD"
    } else {
        dict set outputConfigDict python_module gid_output_process_mpi
        dict set outputConfigDict kratos_module TrilinosApplication
        dict set outputConfigDict process_name GiDOutputProcessMPI
        dict set outputConfigDict help "This process writes postprocessing files in MPI for GiD"
    }

    dict set outputConfigDict Parameters $outputProcessParams

    set output_process_list [list ]
    lappend output_process_list $outputConfigDict

    set outputProcessesDict [dict create]
    dict set outputProcessesDict gid_output $output_process_list
}