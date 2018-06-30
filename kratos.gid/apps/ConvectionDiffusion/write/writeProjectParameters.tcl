# Project Parameters
proc ::ConvectionDiffusion::write::getParametersDict { } {
    set projectParametersDict [dict create]

    # First section -> Problem data
    set problemDataDict [dict create]
    set model_name [file tail [GiD_Info Project ModelName]]
    dict set problemDataDict problem_name $model_name
    dict set problemDataDict model_part_name "FluidModelPart"
    set nDim [expr [string range [write::getValue nDim] 0 0]]
    dict set problemDataDict domain_size $nDim

    # Parallelization
    set paralleltype [write::getValue ParallelType]
    dict set problemDataDict "parallel_type" $paralleltype
    if {$paralleltype eq "OpenMP"} {
        #set nthreads [write::getValue Parallelization OpenMPNumberOfThreads]
        #dict set problemDataDict NumberofThreads $nthreads
    } else {
        #set nthreads [write::getValue Parallelization MPINumberOfProcessors]
        #dict set problemDataDict NumberofProcessors $nthreads
    }

    # Write the echo level in the problem data section
    set echo_level [write::getValue Results EchoLevel]
    dict set problemDataDict echo_level $echo_level

    # Time Parameters
    dict set problemDataDict start_time [write::getValue CNVDFFTimeParameters StartTime]
    dict set problemDataDict end_time [write::getValue CNVDFFTimeParameters EndTime]


    dict set projectParametersDict problem_data $problemDataDict

    # output configuration
    dict set projectParametersDict output_configuration [write::GetDefaultOutputDict]

    # restart options
    set restartDict [dict create]
    dict set restartDict SaveRestart False
    dict set restartDict RestartFrequency 0
    dict set restartDict LoadRestart False
    dict set restartDict Restart_Step 0
    dict set projectParametersDict restart_options $restartDict

    # Solver settings
    set solverSettingsDict [dict create]
    set currentStrategyId [write::getValue CNVDFFSolStrat]
    set strategy_write_name [[::Model::GetSolutionStrategy $currentStrategyId] getAttribute "ImplementedInPythonFile"]
    dict set solverSettingsDict solver_type $strategy_write_name

    # model import settings
    set modelDict [dict create]
    dict set modelDict input_type "mdpa"
    dict set modelDict input_filename $model_name
    dict set solverSettingsDict model_import_settings $modelDict

    if {0} {
        set materialsDict [dict create]
        dict set materialsDict materials_filename [GetAttribute materials_file]
        dict set solverSettingsDict material_import_settings $materialsDict
    }

    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolutionStrategyParametersDict] ]
    set solverSettingsDict [dict merge $solverSettingsDict [write::getSolversParametersDict ConvectionDiffusion] ]

    # Parts
    dict set solverSettingsDict volume_model_part_name {*}[write::getPartsSubModelPartId]

    # Skin parts
    dict set solverSettingsDict skin_parts [getBoundaryConditionMeshId]

    # No skin parts
    dict set solverSettingsDict no_skin_parts [getNoSkinConditionMeshId]
    # Time stepping settings
    set timeSteppingDict [dict create]
    dict set timeSteppingDict "time_step" [write::getValue CNVDFFTimeParameters DeltaTime]
    dict set solverSettingsDict time_stepping $timeSteppingDict

    dict set projectParametersDict solver_settings $solverSettingsDict

    # Boundary conditions processes
    dict set projectParametersDict initial_conditions_process_list [write::getConditionsParametersDict [GetAttribute nodal_conditions_un] "Nodal"]
    dict set projectParametersDict boundary_conditions_process_list [write::getConditionsParametersDict [GetAttribute conditions_un]]
    dict set projectParametersDict body_force [list [getBodyForceProcessDict] ]
    # dict set projectParametersDict auxiliar_process_list [getAuxiliarProcessList]

    return $projectParametersDict
}

proc ConvectionDiffusion::write::writeParametersEvent { } {
    set projectParametersDict [getParametersDict]
    write::SetParallelismConfiguration
    write::WriteJSON $projectParametersDict
}

# proc ConvectionDiffusion::write::getAuxiliarProcessList {} {
#     set process_list [list ]

#     return $process_list
# }

# Body force SubModelParts and Process collection
proc ConvectionDiffusion::write::getBodyForceProcessDict {} {
    set root [customlib::GetBaseRoot]

    set value [write::getValue CNVDFFBodyForce BodyForceValue]
    set pdict [dict create]
    dict set pdict "python_module" "assign_scalar_variable_process"
    dict set pdict "kratos_module" "KratosMultiphysics"
    dict set pdict "process_name" "AssignScalarVariableProcess"
    set params [dict create]
    set partgroup [write::getPartsSubModelPartId]
    dict set params "model_part_name" [concat [lindex $partgroup 0]]
    dict set params "variable_name" "HEAT_FLUX"
    dict set params "value" $value
    dict set params "constrained" false
    dict set pdict "Parameters" $params

    return $pdict
}

# Skin SubModelParts ids
proc ConvectionDiffusion::write::getBoundaryConditionMeshId {} {
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
proc ConvectionDiffusion::write::getNoSkinConditionMeshId {} {
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
