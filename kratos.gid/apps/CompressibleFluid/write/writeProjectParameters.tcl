# Project Parameters
proc ::CompressibleFluid::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # Problem data
    dict set projectParametersDict problem_data [write::GetDefaultProblemDataDict $CompressibleFluid::app_id]

    # output configuration
    dict set projectParametersDict output_processes [write::GetDefaultOutputProcessDict $CompressibleFluid::app_id]

    # Solver settings
    set solver_settings_dict [CompressibleFluid::write::getSolverSettingsDict]
    dict set solver_settings_dict "reform_dofs_at_each_step" false
    dict set projectParametersDict solver_settings $solver_settings_dict

    # Boundary conditions processes
    set processesDict [dict create]
    dict set processesDict initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set processesDict boundary_conditions_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    dict set processesDict gravity [list [getGravityProcessDict] ]
    dict set processesDict auxiliar_process_list [getAuxiliarProcessList]

    dict set projectParametersDict processes $processesDict

    return $projectParametersDict
}

proc CompressibleFluid::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

proc CompressibleFluid::write::getAuxiliarProcessList {} {
    set process_list [list ]

    foreach process [getDragProcessList] {lappend process_list $process}

    return $process_list
}

proc CompressibleFluid::write::getDragProcessList {} {
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
proc CompressibleFluid::write::getGravityProcessDict {} {
    set root [customlib::GetBaseRoot]

    set value [write::getValue CFGravity GravityValue]
    set cx [write::getValue CFGravity Cx]
    set cy [write::getValue CFGravity Cy]
    set cz [write::getValue CFGravity Cz]
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
proc CompressibleFluid::write::getBoundaryConditionMeshId {} {
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
proc CompressibleFluid::write::getNoSkinConditionMeshId {} {
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

proc CompressibleFluid::write::GetUsedElements {} {
    set root [customlib::GetBaseRoot]

    # Get the fluid part
    set xp1 "[spdAux::getRoute [GetAttribute parts_un]]/group"
    set lista [list ]
    foreach gNode [[customlib::GetBaseRoot] selectNodes $xp1] {
        set g $gNode
        set name [write::getValueByNode [$gNode selectNodes ".//value\[@n='Element']"] ]
        if {$name ni $lista} {lappend lista $name}
    }

    return $lista
}

proc CompressibleFluid::write::getSolverSettingsDict { } {
    set solverSettingsDict [dict create]
    dict set solverSettingsDict model_part_name [GetAttribute model_part_name]
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set solverSettingsDict domain_size $nDim
    set currentStrategyId [write::getValue CFSolStrat "" force]
    set strategy [::Model::GetSolutionStrategy $currentStrategyId]
    set strategy_write_name [$strategy getAttribute "ImplementedInPythonFile"]
    set strategy_type [$strategy getAttribute "Type"]
    dict set solverSettingsDict solver_type $strategy_write_name

    # model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    set model_name [CompressibleFluid::write::getFluidModelPartFilename]
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    # material import settings
    set materialsDict [dict create]
    dict set materialsDict materials_filename [GetAttribute materials_file]
    dict set solverSettingsDict material_import_settings $materialsDict

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict CFSolStrat CFScheme CFStratParams] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict CompressibleFluid] ]

    # Parts
    dict set solverSettingsDict volume_model_part_name {*}[write::getPartsSubModelPartId]

    # Skin parts
    dict set solverSettingsDict skin_parts [getBoundaryConditionMeshId]

    # No skin parts
    dict set solverSettingsDict no_skin_parts [getNoSkinConditionMeshId]

    # Time stepping settings
    set timeSteppingDict [dict create]
    set automaticDeltaTime [write::getValue CFTimeParameters AutomaticDeltaTime]
    dict set timeSteppingDict automatic_time_step $automaticDeltaTime
    if {$automaticDeltaTime eq "Yes"} {
        dict set timeSteppingDict "CFL_number" [write::getValue CFTimeParameters CFL_Number]
        dict set timeSteppingDict "minimum_delta_time" [write::getValue CFTimeParameters MinimumDeltaTime]
        dict set timeSteppingDict "maximum_delta_time" [write::getValue CFTimeParameters MaximumDeltaTime]
        dict set timeSteppingDict "Viscous_Fourier_number" [write::getValue CFTimeParameters Viscous_Fourier_number]
        dict set timeSteppingDict "Thermal_Fourier_number" [write::getValue CFTimeParameters Thermal_Fourier_number]
    } else {
        dict set timeSteppingDict "time_step" [write::getValue CFTimeParameters DeltaTime]
    }
    dict set solverSettingsDict time_stepping $timeSteppingDict

    return $solverSettingsDict
}

proc CompressibleFluid::write::GetMonolithicElementTypeFromElementName {element_name} {
    set element [Model::getElement $element_name]
    if {![$element hasAttribute FormulationElementType]} {error "Your monolithic element $element_name need to define the FormulationElementType field"}
    set formulation_element_type [$element getAttribute FormulationElementType]
    return {*}$formulation_element_type
}