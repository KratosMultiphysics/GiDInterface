package require json::write
package require json

proc write::json2dict_former {JSONtext} {
    string range [
        string trim [
            string trimleft [
                string map {\t {} \n {} \r {} , { } : { } \[ \{ \] \}} $JSONtext
                ] {\uFEFF}
            ]
        ] 1 end-1
}
proc write::json2dict {JSONtext} {
    return [::json::json2dict $JSONtext]
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
proc write::tcl2jsonstrings { value } {
    # Guess the type of the value; deep *UNSUPPORTED* magic!
    # display the representation of a Tcl_Obj for debugging purposes. Do not base the behavior of any command on the results of this one; it does not conform to Tcl's value semantics!
    regexp {^value is a (.*?) with a refcount} [::tcl::unsupported::representation $value] -> type
    if {$value eq ""} {return [json::write array {*}[lmap v $value {tcl2jsonstrings $v}]]}
    switch $type {
        string {
            if {$value eq "null"} {return null}
            if {$value eq "dictnull"} {return {{}}}
            return [json::write string $value]
        }
        dict {
            return [json::write object {*}[
                    dict map {k v} $value {tcl2jsonstrings $v}]]
        }
        list {
            return [json::write array {*}[lmap v $value {tcl2jsonstrings $v}]]
        }
        int - double {
            return [json::write string $value]
        }
        booleanString {
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
                return [json::write string $value]
            } elseif {[string is double -strict $value]} {
                return [json::write string $value]
            } elseif {[string is boolean -strict $value]} {
                return [json::write string $value]
            }
            return [json::write string $value]
        }
    }
}

proc write::WriteJSON {processDict} {
    WriteString [write::tcl2json $processDict]
}
proc write::WriteJSONAsStringFields {processDict} {
    WriteString [write::tcl2jsonstrings $processDict]
}

proc write::GetEmptyList { } {
    # This is a gipsy code
    set a [list ]
    return $a
}

proc write::GetCutPlanesList { {cut_planes_UN CutPlanes} } {
    set xp1 "[spdAux::getRoute CutPlanes]"
    return [GetCutPlanesByXPathList $xp1]
}

proc write::GetCutPlanesByXPathList { xpath } {

    set root [customlib::GetBaseRoot]

    set list_of_planes [list ]

    set xp1 "$xpath/blockdata"
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
        dict set solverSettingsDict $n [write::getValue $StratParamsUN $n force]
    }
    foreach {n in} [$sch getInputs] {
        dict set solverSettingsDict $n [write::getValue $StratParamsUN $n force]
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
    set bcCondsList [list ]
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
            set processWriteCommand [$process getAttribute write_command]
            
            dict set processDict process_name $processName

            if {$processWriteCommand eq ""} {
                set processDict [write::GetProcessHeader $group $process $condition $groupId]

                set process_parameters [$process getInputs]
                foreach {inputName in_obj} $process_parameters {
                    dict set processDict Parameters $inputName [write::GetInputValue $group $in_obj]
                }
                
            } else {
                set processDict [$processWriteCommand $group $condition $process]
            }
            lappend bcCondsList $processDict
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
        lappend bcCondsList $processDict
    }
    return $bcCondsList
}

proc write::GetResultsList { un {cnd ""} } {

    if {$cnd eq ""} {set xp1 [spdAux::getRoute $un]} {set xp1 "[spdAux::getRoute $un]/container\[@n = '$cnd'\]"}
    return [GetResultsByXPathList $xp1]
}

proc write::GetResultsByXPathList { xpath } {

    set root [customlib::GetBaseRoot]

    set result [list ]
    set xp1 "$xpath/value"
    set resultxml [$root selectNodes $xp1]
    foreach res $resultxml {
        if {[get_domnode_attribute $res v] in [list "Yes" "True" "1"] && [get_domnode_attribute $res state] ne "hidden"} {
            set name [get_domnode_attribute $res n]
            lappend result $name
        }
    }
    return $result
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
    return [string trim $result "."]
}

proc write::GetDefaultProblemDataDict { {appid ""} } {

    # Get the results unique name. appid parameter is usefull for multiple inheritance app with more than 1 results section
    if {$appid eq ""} {set results_UN Results } {set results_UN [GetConfigurationAttribute results_un]}

    # Problem name
    set problem_data_dict [dict create]
    set model_name [Kratos::GetModelName]
    dict set problem_data_dict problem_name $model_name

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problem_data_dict "parallel_type" $paralleltype

    # Write the echo level in the problem data section
    set echo_level [write::getValue $results_UN EchoLevel]
    dict set problem_data_dict echo_level $echo_level

    # Time Parameters
    dict set problem_data_dict start_time [write::getValue [GetConfigurationAttribute time_parameters_un] StartTime]
    dict set problem_data_dict end_time [write::getValue [GetConfigurationAttribute time_parameters_un] EndTime]

    return $problem_data_dict
}

proc write::GetDefaultOutputProcessDict { {appid ""}  } {
    # Output process must be placed inside json lists
    set gid_output_process_list [list ]
    set need_gid [write::getValue EnableGiDOutput]
    if {[write::isBooleanTrue $need_gid]}  {
        lappend gid_output_process_list [write::GetDefaultGiDOutput $appid]
    }

    set vtk_output_process_list [list ]
    set need_vtk [write::getValue EnableVtkOutput]
    if {[write::isBooleanTrue $need_vtk]}  {
        lappend vtk_output_process_list [write::GetDefaultVTKOutput $appid]
    }

    set outputProcessesDict [dict create]
    dict set outputProcessesDict gid_output $gid_output_process_list
    dict set outputProcessesDict vtk_output $vtk_output_process_list

    return $outputProcessesDict
}

proc write::GetDefaultGiDOutput { {appid ""} } {
    # prepare params
    set model_name [Kratos::GetModelName]

    # Setup GiD-Output
    set outputProcessParams [dict create]
    dict set outputProcessParams model_part_name [write::GetModelPartNameWithParent [GetConfigurationAttribute output_model_part_name]]
    dict set outputProcessParams output_name $model_name
    dict set outputProcessParams postprocess_parameters [write::GetDefaultOutputGiDDict $appid]

    set outputConfigDict [dict create]
    dict set outputConfigDict python_module gid_output_process
    dict set outputConfigDict kratos_module KratosMultiphysics
    dict set outputConfigDict process_name GiDOutputProcess
    dict set outputConfigDict help "This process writes postprocessing files for GiD"
    dict set outputConfigDict Parameters $outputProcessParams

    return $outputConfigDict
}

proc write::GetDefaultOutputGiDDict { {appid ""} {gid_options_xpath ""} } {
    set outputDict [dict create]
    set resultDict [dict create]

    if {$appid eq ""} {set results_UN Results } {set results_UN [apps::getAppUniqueName $appid Results]}
    if {$gid_options_xpath eq ""} {set gid_options_xpath "[spdAux::getRoute $results_UN]/container\[@n='GiDOutput'\]/container\[@n='GiDOptions'\]"}
    set GiDPostDict [dict create]
    dict set GiDPostDict GiDPostMode                [getValueByXPath $gid_options_xpath GiDPostMode]
    dict set GiDPostDict WriteDeformedMeshFlag      [getValueByXPath $gid_options_xpath GiDWriteMeshFlag]
    dict set GiDPostDict WriteConditionsFlag        [getValueByXPath $gid_options_xpath GiDWriteConditionsFlag]
    dict set GiDPostDict MultiFileFlag              [getValueByXPath $gid_options_xpath GiDMultiFileFlag]
    dict set resultDict gidpost_flags $GiDPostDict

    dict set resultDict file_label                 [getValueByXPath $gid_options_xpath FileLabel]
    set outputCT [getValueByXPath $gid_options_xpath OutputControlType]
    dict set resultDict output_control_type $outputCT
    if {$outputCT eq "time"} {
        set frequency [getValueByXPath $gid_options_xpath OutputDeltaTime]
    } {
        set frequency [getValueByXPath $gid_options_xpath OutputDeltaStep]
    }
    dict set resultDict output_interval $frequency

    dict set resultDict body_output [getValueByXPath $gid_options_xpath BodyOutput]
    dict set resultDict node_output [getValueByXPath $gid_options_xpath NodeOutput]
    dict set resultDict skin_output [getValueByXPath $gid_options_xpath SkinOutput]

    set gid_cut_planes_xpath "[spdAux::getRoute $results_UN]/container\[@n='GiDOutput'\]/container\[@n='CutPlanes'\]"
    dict set resultDict plane_output [GetCutPlanesByXPathList $gid_cut_planes_xpath]
    
    set gid_nodes_xpath "[spdAux::getRoute $results_UN]/container\[@n='OnNodes'\]"
    dict set resultDict nodal_results [GetResultsByXPathList $gid_nodes_xpath]
    
    set gid_nodes_nh_xpath "[spdAux::getRoute $results_UN]/container\[@n='OnNodesNonHistorical'\]"
    dict set resultDict nodal_nonhistorical_results [GetResultsByXPathList $gid_nodes_nh_xpath]

    set gid_elements_xpath "[spdAux::getRoute $results_UN]/container\[@n='OnElement'\]"
    dict set resultDict gauss_point_results [GetResultsByXPathList $gid_elements_xpath]

    dict set outputDict "result_file_configuration" $resultDict
    dict set outputDict "point_data_configuration" [GetEmptyList]
    return $outputDict
}

proc write::GetDefaultVTKOutput { {appid ""} } {

    # prepare params
    set model_name [Kratos::GetModelName]

    # Setup Vtk-Output
    set outputConfigDictVtk [dict create]
    dict set outputConfigDictVtk python_module vtk_output_process
    dict set outputConfigDictVtk kratos_module KratosMultiphysics
    dict set outputConfigDictVtk process_name VtkOutputProcess
    dict set outputConfigDictVtk help "This process writes postprocessing files for Paraview"
    dict set outputConfigDictVtk Parameters [write::GetDefaultParametersOutputVTKDict $appid]

    return $outputConfigDictVtk
}

proc write::GetDefaultParametersOutputVTKDict { {appid ""} } {
    set resultDict [dict create]
    dict set resultDict model_part_name [write::GetModelPartNameWithParent [GetConfigurationAttribute output_model_part_name]]

    if {$appid eq ""} {set results_UN Results } {set results_UN [apps::getAppUniqueName $appid Results]}
    set vtk_options_xpath "[spdAux::getRoute $results_UN]/container\[@n='VtkOutput'\]/container\[@n='VtkOptions'\]"

    # manually selecting step, otherwise Paraview won't group the results
    set outputCT [getValueByXPath $vtk_options_xpath OutputControlType]
    dict set resultDict output_control_type $outputCT
    if {$outputCT eq "time"} {set frequency [getValueByXPath $vtk_options_xpath OutputDeltaTime]} {set frequency [getValueByXPath $vtk_options_xpath OutputDeltaStep]}
    dict set resultDict output_interval               $frequency
    dict set resultDict file_format                    [getValueByXPath $vtk_options_xpath VtkFileFormat]
    dict set resultDict output_precision               7
    dict set resultDict output_sub_model_parts         "false"
    dict set resultDict output_path                    "vtk_output"
    dict set resultDict save_output_files_in_folder    "true"
    dict set resultDict nodal_solution_step_data_variables [GetResultsList $results_UN OnNodes]
    dict set resultDict nodal_data_value_variables      [GetResultsList $results_UN OnNodesNonHistorical]
    dict set resultDict element_data_value_variables    [list ]
    dict set resultDict condition_data_value_variables  [list ]
    dict set resultDict gauss_point_variables_extrapolated_to_nodes   [GetResultsList $results_UN OnElement]

    return $resultDict
}

proc write::GetDefaultRestartDict { } {

    set restartDict [dict create]
    dict set restartDict SaveRestart False
    dict set restartDict RestartFrequency 0
    dict set restartDict LoadRestart False
    dict set restartDict Restart_Step 0
    return $restartDict
}
