# Project Parameters
proc ::Fluid::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # Problem data
    dict set projectParametersDict problem_data [write::GetDefaultProblemDataDict $Fluid::app_id]

    # output configuration
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict $Fluid::app_id]

    # Solver settings
    dict set projectParametersDict solver_settings [Fluid::write::getSolverSettingsDict]

    # Boundary conditions processes
    set processesDict [dict create]
    dict set processesDict initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set processesDict boundary_conditions_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    dict set processesDict gravity [list [getGravityProcessDict] ]
    dict set processesDict auxiliar_process_list [getAuxiliarProcessList]

    dict set projectParametersDict processes $processesDict

    return $projectParametersDict
}

proc Fluid::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc Fluid::write::getAuxiliarProcessList {} {
    set process_list [list ]

    foreach process [getDragProcessList] {lappend process_list $process}

    return $process_list
}

proc Fluid::write::getDragProcessList {} {
    set root [customlib::GetBaseRoot]

    set process_list [list ]
    set xp1 "[spdAux::getRoute [GetAttribute drag_un]]/group"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]

        set write_output [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='write_drag_output_file'\]"]]]
        set print_screen [write::getStringBinaryFromValue [write::getValueByNode [$group selectNodes "./value\[@n='print_drag_to_screen'\]"]]]
        set interval_name [write::getValueByNode [$group selectNodes "./value\[@n='Interval'\]"]]

        set pdict [dict create]
        dict set pdict "python_module" "compute_body_fitted_drag_process"
        dict set pdict "kratos_module" "KratosMultiphysics.FluidDynamicsApplication"
        dict set pdict "process_name" "ComputeBodyFittedDragProcess"
        set params [dict create]
        dict set params "model_part_name" [write::GetModelPartNameWithParent $submodelpart]
        dict set params "write_drag_output_file" $write_output
        dict set params "print_drag_to_screen" $print_screen
        dict set params "interval" [write::getInterval $interval_name]
        dict set pdict "Parameters" $params

        lappend process_list $pdict
    }

    return $process_list
}

# Gravity SubModelParts and Process collection
proc Fluid::write::getGravityProcessDict {} {
    set root [customlib::GetBaseRoot]

    set value [write::getValue FLGravity GravityValue]
    set cx [write::getValue FLGravity Cx]
    set cy [write::getValue FLGravity Cy]
    set cz [write::getValue FLGravity Cz]
    #W "Gravity $value on \[$cx , $cy , $cz\]"
    set pdict [dict create]
    dict set pdict "python_module" "assign_vector_by_direction_process"
    dict set pdict "kratos_module" "KratosMultiphysics"
    dict set pdict "process_name" "AssignVectorByDirectionProcess"
    set params [dict create]
    set partgroup [write::getPartsSubModelPartId]
    dict set params "model_part_name" [write::GetModelPartNameWithParent [concat [lindex $partgroup 0]]]
    dict set params "variable_name" "BODY_FORCE"
    dict set params "modulus" $value
    dict set params "constrained" false
    dict set params "direction" [list $cx $cy $cz]
    dict set pdict "Parameters" $params

    return $pdict
}

# Skin SubModelParts ids
proc Fluid::write::getBoundaryConditionMeshId {} {
    set root [customlib::GetBaseRoot]
    set listOfBCGroups [list ]
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set cond [Model::getCondition $cid]
        if {[$cond getAttribute "SkinConditions"] eq "True"} {
            if {[[::Model::getCondition $cid] getGroupBy] eq "Condition"} {
                # Grouped conditions have its own submodelpart
                if {$cid ni $listOfBCGroups} {
                    lappend listOfBCGroups $cid
                }
            } else {
                set gname [::write::getSubModelPartId $cid $groupName]
                if {$gname ni $listOfBCGroups} {lappend listOfBCGroups $gname}
            }

        }
    }

    return $listOfBCGroups
}

# No-skin SubModelParts ids
proc Fluid::write::getNoSkinConditionMeshId {} {
    set root [customlib::GetBaseRoot]
    set listOfNoSkinGroups [list ]

    # Append drag processes model parts names
    set xp1 "[spdAux::getRoute [GetAttribute drag_un]]/group"
    set dragGroups [$root selectNodes $xp1]
    foreach dragGroup $dragGroups {
        set groupName [$dragGroup @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$dragGroup parent] @n]
        set submodelpart [::write::getSubModelPartId $cid $groupName]
        if {$submodelpart ni $listOfNoSkinGroups} {lappend listOfNoSkinGroups $submodelpart}
    }

    # Append no skin conditions model parts names
    set xp1 "[spdAux::getRoute [GetAttribute conditions_un]]/condition/group"
    set groups [$root selectNodes $xp1]
    foreach group $groups {
        set groupName [$group @n]
        set groupName [write::GetWriteGroupName $groupName]
        set cid [[$group parent] @n]
        set cond [Model::getCondition $cid]
        if {[$cond getAttribute "SkinConditions"] eq "False"} {
            set gname [::write::getSubModelPartId $cid $groupName]
            if {$gname ni $listOfNoSkinGroups} {lappend listOfNoSkinGroups $gname}
        }
    }

    return $listOfNoSkinGroups
}

proc Fluid::write::getSolverSettingsDict { } {
    set solverSettingsDict [dict create]
    dict set solverSettingsDict model_part_name [GetAttribute model_part_name]
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solverSettingsDict domain_size $nDim
    set currentStrategyId [write::getValue FLSolStrat]
    set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "ImplementedInPythonFile"]
    dict set solverSettingsDict solver_type $strategy_write_name

    # model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    #set model_name [Kratos::GetModelName]
    set model_name [concat [Kratos::GetModelName]Fluid]
    W $model_name
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    if {0} {
        set materialsDict [dict create]
        dict set materialsDict materials_filename [GetAttribute materials_file]
        dict set solverSettingsDict material_import_settings $materialsDict
    }

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict FLSolStrat FLScheme FLStratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict Fluid] ]

    # Parts
    dict set solverSettingsDict volume_model_part_name {*}[write::getPartsSubModelPartId]

    # Skin parts
    dict set solverSettingsDict skin_parts [getBoundaryConditionMeshId]

    # No skin parts
    dict set solverSettingsDict no_skin_parts [getNoSkinConditionMeshId]

    # Time stepping settings
    set timeSteppingDict [dict create]
    set automaticDeltaTime [write::getValue FLTimeParameters AutomaticDeltaTime]
    dict set timeSteppingDict automatic_time_step $automaticDeltaTime
    if {$automaticDeltaTime eq "Yes"} {
        dict set timeSteppingDict "CFL_number" [write::getValue FLTimeParameters CFLNumber]
        dict set timeSteppingDict "minimum_delta_time" [write::getValue FLTimeParameters MinimumDeltaTime]
        dict set timeSteppingDict "maximum_delta_time" [write::getValue FLTimeParameters MaximumDeltaTime]
    } else {
        dict set timeSteppingDict "time_step" [write::getValue FLTimeParameters DeltaTime]
    }
    dict set solverSettingsDict time_stepping $timeSteppingDict

    # For monolithic schemes, set the formulation settings
    if {$currentStrategyId eq "Monolithic"} {
        set formulationSettingsDict [dict create]
        # Set element type
        dict set formulationSettingsDict element_type "vms"
        # Set OSS and remove oss_switch from the original dictionary
        # It is important to check that there is oss_switch, otherwise the derived apps (e.g. embedded) might crash
        if {[dict exists $solverSettingsDict oss_switch]} {
            dict set formulationSettingsDict use_orthogonal_subscales [write::getStringBinaryFromValue [dict get $solverSettingsDict oss_switch]]
            dict unset solverSettingsDict oss_switch
        }
        # Set dynamic tau and remove dynamic_tau from the original dictionary
        dict set formulationSettingsDict dynamic_tau [dict get $solverSettingsDict dynamic_tau]
        dict unset solverSettingsDict dynamic_tau
        # Include the formulation settings in the solver settings dict
        dict set solverSettingsDict formulation $formulationSettingsDict
    }

    return $solverSettingsDict
}